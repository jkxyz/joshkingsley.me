---
title: Publishing a static site with Nix
date: 2023-02-06
draft: true
---

Following in the grand tradition of blogging about blogging, for the first post on this
site I've decided to write about how it's built and deployed. It also seems like a good
thing to write about as I debug and finalize some parts of it.

I hope this serves as a good rough guide to using Nix for building and deploying a simple
package to a web server. I will try to walk through the various Nix elements without
assuming too much knowledge, but it won't be an in-depth guide to Nix.

## Static site generation

You will be relieved to hear that I decided to save the world from being burdened with yet another static
site generator. This site is generated using [Metalsmith](https://metalsmith.io/).

It seemed like a good choice to me because it's based on a model that I could
immediately understand. Instead of using a complex configuration file, Metalsmith
works more like a functional pipeline of plugins which transform a set of files at
each step.

For example:

```js
Metalsmith(__dirname)
  .source('src')
  .destination('target')
  .clean(true)
  .use(markdown())
  .use(layouts())
  .build(err => { if (err) throw err; });
```

The above constructs a configuration which first cleans the destination directory,
and then pipes the files found in the source directory through the `markdown` and 
`layouts` plugins. Finally it attempts to build the configuration.

Put this in a `build.js` file (along with the requisite `require`s) and you can
run it with `node build.js` to transform some Markdown files.

I like this because there's no hidden magic. 

The one confusing issue I ran into
was caused by the fact I had the plugins in the wrong order. I can only imagine
it would have been even more confusing if the build was run in an implicit order
that I didn't define. Furthermore, if I want to see how the build looks after a
certain step, I can just comment out the plugins which come after it and inspect
the destination directory.

The usual caveat applies, when working in JavaScript-land, that you need
to be reasonably familiar with the JavaScript bundling ecosystem. I had worked
with PostCSS and other tools before, so I didn't find it too difficult to get
things working as I wanted them to.

## Packaging HTML with Nix

If you've never used Nix before, here is the unconvincing pitch: Nix is a tool
for reproducibly building files and distributing them as packages. It's a 
purely functional package manager.

This has a huge number of emergent benefits. But for our purposes here, it
makes it a great tool for deploying software and configuration to remote servers.

The most basic building block of Nix is the derivation. This is some code
which describes how to build a file or set of files based on some inputs, like
another set of files (i.e. source code), or the outputs of other derivations.

The first derivation we want to write for publishing a static site is one which
builds our HTML and assets. This requires capturing all of the dependencies 
required for the build, and providing a script which generates the output
and copies it to the Nix store.

Since I'm using Node and npm for managing dependencies, my derivation needs to
take its inputs from `package.json`. There are a number of ways to do this, but
many of them require generating a separate lock file containing hashes of the
dependencies for Nix to use. 

However, there's a function built in to nixpkgs called `buildNpmPackage`, which
does exactly what it says on the tin, without requiring a separate lock file. It
first installs the npm dependencies as normal, and then hashes the resulting files
so that they are stable and cacheable on each re-build. Dependencies will only be
re-fetched when the `package.json` or `package-lock.json` change.

We can write a simple package file called `site.nix` like this:

```nix
{ buildNpmPackage, lib, ... }:

buildNpmPackage {
  name = "site";
  src = ./site;
  npmDepsHash = lib.fakeHash;
}
```

Along with a minimal `flake.nix` to handle fetching nixpkgs and define our
package as an output:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system; };
      in {
        packages = { site = pkgs.callPackage (import ./site.nix) { }; };
      });
}
```

The package can then be built with:

```
$ nix build .#site
```

When building for the first time, Nix will fail on the hash mismatch:

```
error: hash mismatch in fixed-output derivation '/nix/store/gn318dgpa8rq96dynf1wq6a9gb8pl3kl-site-npm-deps.drv':
         specified: sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
            got:    sha256-SIBBCkUSWPuHhxh91TBYF9YRBUOxqKeQ8vy39MvWbN8=
error: 1 dependencies of derivation '/nix/store/xnrbzw9zf76b2z2ncss18rjpjwfg878z-site.drv' failed to build
```

The package file can then be updated with the correct hash:

```nix
{ buildNpmPackage, lib, ... }:

buildNpmPackage {
  name = "site";
  src = ./site;
  # npmDepsHash = lib.fakeHash;
  npmDepsHash = "sha256-SIBBCkUSWPuHhxh91TBYF9YRBUOxqKeQ8vy39MvWbN8=";
}
```

The build then proceeds by running `npm build`, which we can configure in `package.json` 
to run `node build.js`. This is configurable but it seems like a convenient default.

The output of the build is symlinked by Nix to `result`:

```
$ ls -al result
lrwxrwxrwx 1 josh users 48 Feb  6 23:08 result -> /nix/store/njqx7jb87277bp1lp7s74y0irfg71wap-site

$ ls result/lib/node_modules/site/target
blog  index.html  styles.css
```

Great! I now have a Nix package which builds my HTML. And it only took me a year and
a half of tinkering and experimenting with Nix to understand what any of these
terms mean!

## NixOS

NixOS uses Nix to package an entire Linux distribution. The stand-out benefit of NixOS is that
your entire OS, including the kernel, packages, and their versions, is defined from a declarative 
set of configuration files. It's trivial to make changes, test them out, and roll them back, with
the assurance that you won't immediately forget what you did and have to figure it out all over 
again.

The OS configuration is built like any other Nix derivation, and using a tool called `nixos-rebuild`,
we can build and deploy the configuration either to our local machine or a remote machine.

The configuration is defined by a set of composable modules, which define the options used to 
build the system. A NixOS module looks something like this:

```nix
{ ... }:

{
  services.openssh.enable = true;

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFfcOdH0DX1wM+1UvZ3nBeKuGLyXv+TcHxFyONUaxhhb josh@sparrowhawk"
  ];
}
```

This module enables the OpenSSH daemon as a system service, and puts my public key
in the list of authorized keys for the root user.

### Installing NixOS

There are any number of ways to install NixOS. Some hosting providers have pre-built images,
while nixpkgs also has support for building custom EC2 and DigitalOcean images.

I'm deploying to Hetzner Cloud, and the easiest way to get started is by using [nixos-infect](https://github.com/elitak/nixos-infect).

This tool takes an existing Linux installation and turns it into NixOS, presumably through
witchcraft.

### Setting up a NixOS configuration

However you install NixOS, you will probably end up with some files at `/etc/nixos`. The
default location for the system configuration to be stored is `/etc/nixos/configuration.nix`,
and most tools will generate some default options there. Typically there will also be a 
`hardware-configuration.nix` module, which is generated based on the detected hardware, and
is imported by `configuration.nix`.

Let's copy those to our project and use them as the basis for building our configuration:

```
$ mkdir nixos
$ scp root@www.joshkingsley.me:/etc/nixos/* nixos/www
```

Now we need to define the derivation for our system. We can do this in `flake.nix` by
adding an output under `nixosConfigurations`:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system; };
      in {
        packages = { site = pkgs.callPackage (import ./site.nix) { }; };
      }) // {
        nixosConfigurations.www = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./nixos/www/configuration.nix
          ];
        };
      };
}
```

And just to make sure everything is working, let's build the system locally:

```
$ nixos-rebuild build --flake .#www
```

And then deploy it to the server:

```
$ nixos-rebuild switch --flake .#www --target-host root@www.joshkingsley.me
```

This last command will build all of the necessary packages and derivations locally,
before copying the required paths from the local Nix store to the server. It then
creates a bunch of symlinks to define a new "generation" of the system, and runs
the activation script to ensure that all services are running and that the boot
loader is configured to boot into this generation on reset.

### Configuring nginx

Now that we have a server running our NixOS configuration, we want to put something
interesting on it. Let's write a NixOS module which enables nginx and serves our
static site.

We can easily find the options available for the nginx service by looking them up on
[search.nixos.org](https://search.nixos.org/options?channel=22.11&from=0&size=50&sort=relevance&type=packages&query=services.nginx.).

This helps us write a module:

```nix
{ pkgs, ... }:

let site = pkgs.callPackage (import ../site.nix) { };

in {
  services.nginx = {
    enable = true;

    virtualHosts."joshkingsley.me" = {
      enableACME = true;
      forceSSL = true;
      root = "${site}/lib/node_modules/site/target";
    };

    virtualHosts."www.joshkingsley.me" = {
      enableACME = true;
      addSSL = true;
      globalRedirect = "joshkingsley.me";
    };
  };
}
```

The nginx options are pretty high-level, and they make it really easy to define an 
nginx configuration with automatic SSL provided by Let's Encrypt. The first virtual
host is configured with a `root` pointing to the build directory in our site package.
The second redirects all requests to the domain without the "www".

Now we can add it to the list of modules in our system:

```nix
modules = [
  ./nixos/www/configuration.nix
  ./nixos/nginx.nix
];
```

But when building again, we get a failed assertion:

```
$ nixos-rebuild build --flake .#www
building the system configuration...
error:
       Failed assertions:
       - You must accept the CA's terms of service before using
       the ACME module by setting `security.acme.acceptTerms`
       to `true`. For Let's Encrypt's ToS see https://letsencrypt.org/repository/
(use '--show-trace' to show detailed location information)
```

In order to use the ACME options, we need to accept Let's Encrypt's terms of service.
This requires adding the following options to our module:

```nix
security.acme.acceptTerms = true;
security.acme.defaults.email = "you@domain.example";
```

After deploying to the server again, and setting up the appropriate DNS records,
we should be able to navigate to the website and see it being served.

## Conclusion

I'm very happy with this setup for a number of reasons:

1. If I ever want to move to a different server, it will take me less than 10 minutes
to launch and deploy an exact copy of everything I've just deployed
to this server. The hardware is ephemeral, and I don't have to fiddle around with
configuration or elaborate scripts to get things as I want them.
2. Improving it is an iterative, collaborative process and I don't have to be scared 
of breaking something. The whole system is open source for others to build on, and 
composed of smaller pieces shared by the Nix community and myself.
3. It's another reason to talk to my poor friends and colleagues about Nix, as I
endeavor to break their spirits and convince them to use it for everything.

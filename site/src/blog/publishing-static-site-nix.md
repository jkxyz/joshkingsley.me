---
title: Publishing a static site with Nix
date: 2023-02-06
draft: true
---

Following in the grand tradition of blogging about blogging, for the first post on this
site I've decided to write about how it's built and deployed. It also seems like a good
thing to write about as I debug and finalize some parts of it.

I hope this serves as a good on-boarding to using Nix for building and deploying a simple
package to a web server. I will try to walk through the various Nix elements without
assuming too much knowledge.

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
  npmDepsHash = "sha256-zrKQBtenBb0e28yuOdefnzktcoYEbTZaL2D12ptG/Lc=";
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

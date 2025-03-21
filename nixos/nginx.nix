{ pkgs, ... }:

let site = pkgs.callPackage (import ../site.nix) { };

in {
  services.nginx = {
    enable = true;

    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    sslCiphers = "AES256+EECDH:AES256+EDH:!aNULL";

    commonHttpConfig = ''
      # Add HSTS header to HTTPS requests.
      # Adding this header to HTTP requests is discouraged
      map $scheme $hsts_header {
          https   "max-age=31536000; includeSubdomains";
      }
      add_header Strict-Transport-Security $hsts_header;

      # Enable CSP for your services.
      add_header Content-Security-Policy "default-src https:" always;

      # Minimize information leaked to other domains
      add_header 'Referrer-Policy' 'origin-when-cross-origin';

      # Disable embedding as a frame
      add_header X-Frame-Options DENY;

      # Prevent injection of code in other mime types (XSS Attacks)
      add_header X-Content-Type-Options nosniff;

      # Enable XSS protection of the browser.
      # May be unnecessary when CSP is configured properly (see above)
      add_header X-XSS-Protection "1; mode=block";
    '';

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

  security.acme.acceptTerms = true;
  security.acme.defaults.email = "josh@joshkingsley.me";
}

{ ... }: {
  boot.cleanTmpDir = true;
  zramSwap.enable = true;

  networking = {
    hostName = "www";
    domain = "joshkingsley.me";

    interfaces.ens3.ipv6.addresses = [{
      address = "2a01:4f8:1c17:77f6::1";
      prefixLength = 64;
    }];

    defaultGateway6 = {
      address = "fe80::1";
      interface = "ens3";
    };

    firewall.allowedTCPPorts = [ 22 80 443 ];
  };

  services.openssh.enable = true;

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFfcOdH0DX1wM+1UvZ3nBeKuGLyXv+TcHxFyONUaxhhb josh@sparrowhawk"
  ];

  system.stateVersion = "22.11";
}

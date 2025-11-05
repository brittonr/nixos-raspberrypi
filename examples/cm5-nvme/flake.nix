{
  description = "CM5 NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";
    
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    extra-substituters = [ "https://nixos-raspberrypi.cachix.org" ];
    extra-trusted-public-keys = [ 
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI=" 
    ];
  };

  outputs = { self, nixpkgs, nixos-raspberrypi, disko, ... }@inputs: {
    nixosConfigurations.cm5 = nixos-raspberrypi.lib.nixosSystemFull {
      specialArgs = inputs;
      modules = [
        disko.nixosModules.disko
        ./disko-config.nix
        ./configuration.nix
        {
          imports = with nixos-raspberrypi.nixosModules; [
            raspberry-pi-5.base
            raspberry-pi-5.page-size-16k
            raspberry-pi-5.display-vc4
            raspberry-pi-5.bluetooth
          ];
        }
      ];
    };
  };
}

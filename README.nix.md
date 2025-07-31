# tar1090 Nix Flake

This flake provides a NixOS module for `tar1090`, an improved web interface for ADS-B decoders.

## Usage

To use this flake, add it to your `flake.nix` inputs:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    tar1090.url = "github:your-github-username/tar1090"; # Replace with your fork
  };

  outputs = { self, nixpkgs, tar1090 }:
    {
      nixosConfigurations.your-hostname = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          tar1090.nixosModules.default
        ];
      };
    };
}
```

Then, in your `configuration.nix`, you can configure `tar1090` instances:

```nix
{
  services.tar1090 = {
    enable = true;
    instances = {
      default = {
        enable = true;
        dataSource = "/run/readsb";
        webPath = "tar1090";
      };
      another-instance = {
        enable = true;
        dataSource = "/run/dump1090-fa";
        webPath = "dump1090";
      };
    };
  };
}
```

This will create two `tar1090` instances, accessible at `http://your-nixos-machine/tar1090` and `http://your-nixos-machine/dump1090`.

## Building and Running

To build the package:

```sh
nix build .#tar1090
```

To apply the configuration to your NixOS system:

```sh
sudo nixos-rebuild switch --flake .#your-hostname
```

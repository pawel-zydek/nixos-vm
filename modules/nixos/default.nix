{ inputs, ... }:
{
  # Wszystkie moduły systemowe. Moduły z core/ działają zawsze,
  # pozostałe nic nie robią, dopóki host ich nie włączy (my.<nazwa>.enable = true).
  imports = [
    inputs.disko.nixosModules.disko
    inputs.home-manager.nixosModules.home-manager

    ./core/nix.nix
    ./core/boot.nix
    ./core/locale.nix
    ./core/users.nix
    ./core/packages.nix
    ./core/home-manager.nix

    ./storage/disko-zfs.nix
    ./storage/zfs.nix
    ./storage/ntfs.nix

    ./desktop/i3.nix
    ./desktop/audio.nix

    ./services/ssh.nix

    ./virtualisation/qemu-guest.nix
  ];
}

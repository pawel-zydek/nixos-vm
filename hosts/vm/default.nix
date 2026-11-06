{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos
  ];

  # --- Tożsamość hosta ---
  networking.hostName = "nixos-vm";
  networking.hostId = "379d459b";               # własne 8 znaków hex (wymagane przez ZFS)
  my.disk = "/dev/disk/by-id/virtio-nixosvm";   # numer seryjny dysku w VM = "nixosvm" (patrz README)

  # --- Co jest włączone na tym hoście ---
  my.zfs.enable = true;
  my.desktop.i3.enable = true;
  my.audio.enable = true;

  my.virtualisation.qemuGuest.enable = true;
  my.services.ssh.enable = true;

  # Klucze, którymi można logować się przez SSH
  users.users.pawel.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINlKrUMXtKlnlbGQgiioga7bd/StVWdbAwz+1jJ7+vQO pawel@nixos-pg"
  ];

  # Wersja systemu, na której pierwotnie zainstalowano NixOS - nie zmieniać
  system.stateVersion = "26.05";
}

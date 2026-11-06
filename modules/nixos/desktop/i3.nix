{ config, lib, pkgs, ... }:
let
  cfg = config.my.desktop.i3;
in
{
  options.my.desktop.i3.enable = lib.mkEnableOption "menedżer okien i3 (X11) z LightDM";

  config = lib.mkIf cfg.enable {
    services.xserver = {
      enable = true;
      windowManager.i3.enable = true;   # i3, i3status, i3lock, dmenu
      displayManager.lightdm = {
        enable = true;
        background = ../../../assets/wallpapers/NixOS/NixOS-Stripes-Logo.png;
      };
    };
    services.displayManager.defaultSession = "none+i3";

    # Podstawowe czcionki (Plasma dostarczała własne)
    fonts.enableDefaultPackages = true;

    # Magazyn haseł (Secret Service) zamiast KWallet - z niego korzysta
    # git (credential.helper = libsecret). Odblokowuje się przy logowaniu.
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.lightdm.enableGnomeKeyring = true;
    programs.seahorse.enable = true;    # podgląd zapisanych haseł

    environment.systemPackages = with pkgs; [
      feh                 # tapeta pulpitu
      pavucontrol         # mikser dźwięku
    ];
  };
}

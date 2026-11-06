{ config, lib, pkgs, ... }:
let
  mod = config.xsession.windowManager.i3.config.modifier;
in
{
  # Konfiguracja i3 (~/.config/i3/config). Sesję uruchamia LightDM (modules/nixos/desktop/i3.nix).
  # Pełna lista domyślnych skrótów: https://i3wm.org/docs/refcard.html
  xsession.windowManager.i3 = {
    enable = true;
    config = {
      # Alt zamiast Super: klawisz Super często przechwytuje system hosta, a nie VM
      modifier = "Mod1";
      terminal = "alacritty";
      menu = "${pkgs.dmenu}/bin/dmenu_run";

      fonts = {
        names = [ "DejaVu Sans" ];
        size = 10.0;
      };

      keybindings = lib.mkOptionDefault {
        "${mod}+Shift+x" = "exec ${pkgs.i3lock}/bin/i3lock -c 1d2021";   # blokada ekranu
      };

      startup = [
        # tapeta przy każdym starcie/przeładowaniu i3
        {
          command = "${pkgs.feh}/bin/feh --bg-fill ${../../assets/wallpapers/NixOS/NixOS-Simple-Blue.png}";
          always = true;
          notification = false;
        }
      ];

      bars = [
        {
          position = "bottom";
          statusCommand = "${pkgs.i3status}/bin/i3status";
          fonts = {
            names = [ "DejaVu Sans Mono" ];
            size = 10.0;
          };
        }
      ];
    };
  };

  # Pasek stanu: sieć, dysk, obciążenie, pamięć, data
  programs.i3status = {
    enable = true;
    enableDefault = true;
  };
}

{ config, lib, pkgs, ... }:
let
  cfg = config.my.virtualisation.qemuGuest;
in
{
  options.my.virtualisation.qemuGuest.enable = lib.mkEnableOption "dodatki gościa KVM/QEMU (agent QEMU, SPICE)";

  config = lib.mkIf cfg.enable {
    services.qemuGuest.enable = true;          # wyłączanie/stan VM z poziomu virt-managera
    services.spice-vdagentd.enable = true;     # schowek i automatyczna rozdzielczość

    # Agent sesji SPICE (rozdzielczość, schowek host <-> VM).
    # i3 nie uruchamia programów z XDG autostart, więc własna usługa użytkownika.
    systemd.user.services.spice-vdagent = {
      description = "Agent sesji SPICE";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.spice-vdagent}/bin/spice-vdagent -x";
        Restart = "on-failure";
      };
    };

    # Automatyczna rozdzielczość pod i3.
    # Po zmianie rozmiaru okna virt-manager zgłasza VM nową "preferowaną" rozdzielczość,
    # ale ktoś musi ją zastosować - Plasma robiła to sama, i3 nie. Ta usługa nasłuchuje
    # zmian ekranu (RandR) i wykonuje `xrandr --auto` na podłączonym wyjściu.
    systemd.user.services.spice-autoresize = {
      description = "Dopasowanie rozdzielczości do okna virt-managera";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      path = [ pkgs.xev pkgs.xrandr pkgs.gnugrep pkgs.gawk ];
      script = ''
        resize() {
          output=$(xrandr | awk '/ connected/ { print $1; exit }')
          if [ -n "$output" ]; then xrandr --output "$output" --auto || true; fi
        }
        resize
        xev -root -event randr \
          | grep --line-buffered 'XRROutputChangeNotifyEvent' \
          | while read -r _; do resize; done
      '';
      serviceConfig.Restart = "on-failure";
    };
  };
}

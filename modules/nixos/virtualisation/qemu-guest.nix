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
  };
}

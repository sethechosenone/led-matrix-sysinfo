{ config, lib, pkgs, appPackage, ... }:

with lib;

{
  options.services.ledMatrixSysinfo.enable = mkEnableOption "Enable LED Matrix sysinfo service";

  config = mkIf config.services.ledMatrixSysinfo.enable {
    systemd.services.led-matrix-sysinfo = {
      description = "LED Matrix sysinfo service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig.ExecStart = "${appPackage}/bin/led-matrix-sysinfo";
      serviceConfig.Restart = "on-failure";
      serviceConfig.Type = "simple";
    };
  };
}
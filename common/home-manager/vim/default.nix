{ lib, config, pkgs, ... }:

with lib;

let cfg = config.red-door-collective.vim;
in {
  options.red-door-collective.vim.enable = mkEnableOption "Enables red-door-collective's vim config";

  config = mkIf cfg.enable {
    home.packages = [ pkgs.vim ];
    home.file.".vimrc".source = ./vimrc;
  };
}

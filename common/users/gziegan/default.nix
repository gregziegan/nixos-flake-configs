{
  pkgs,
  config,
  ...
}: let
  name = "Greg Ziegan";
  email = "greg.ziegan@gmail.com";
  commitTemplate = pkgs.writeTextFile {
    name = "gziegan-commit-template";
    text = ''
      Signed-off-by: ${name} <${email}>
    '';
  };
in {
  imports = [../../home-manager];

  # red-door-collective = {
  #   htop.enable = true;
  #   vim.enable = true;
  # };

  programs.bash.sessionVariables = {
    SYSTEMD_COLORS = true;
  };

  services.lorri.enable = true;
  home.packages = with pkgs; [cachix niv nixfmt bind unzip];

  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  programs.git = {
    package = pkgs.gitAndTools.gitFull;
    enable = true;
    userName = name;
    userEmail = email;
    ignores = ["*~" "*.swp" "*.#"];
    delta.enable = true;
    extraConfig = {
      commit.template = "${commitTemplate}";
      core.editor = "vim";
      color.ui = "auto";
      credential.helper = "store --file ~/.git-credentials";
      format.signoff = true;
      init.defaultBranch = "main";
      protocol.keybase.allow = "always";
      pull.rebase = "true";
      push.default = "current";
    };
  };
}

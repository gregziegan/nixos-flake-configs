{
  pkgs,
  config,
  devenv,
  fenix,
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

  home.packages = with pkgs;
    [
      # Some basics
      coreutils
      curl
      wget

      # Dev stuff
      _1password
      jq
      jd-diff-patch
      jdk
      nodePackages.typescript
      nodejs
      git-absorb
      python311
      python311Packages.pytest
      python311Packages.black
      dhall
      dhall-lsp-server
      dhall-json
      gh
      zellij
      unzip

      # Useful nix related tools
      nixpkgs-fmt
      nixd
      alejandra
      zsh-nix-shell

      cachix # adding/managing alternative binary caches hosted by Cachix
      # comma # run software from without installing it
      nodePackages.node2nix
    ]
    ++ lib.optionals stdenv.isDarwin [
      fenix.packages."aarch64-darwin".minimal.toolchain # rust
      devenv.packages.aarch64-darwin.devenv
      cocoapods
      m-cli # useful macOS CLI commands
    ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ll = "ls -l";
    };
    history = {
      size = 10000;
      path = "${config.xdg.dataHome}/zsh/history";
    };

    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
      {
        name = "powerlevel10k-config";
        src = ../p10k-config;
        file = "p10k.zsh";
      }
      {
        name = "nix-shell";
        src = "${pkgs.zsh-nix-shell}/share/zsh/site-functions";
      }
    ];
  };

  programs.bash.sessionVariables = {
    SYSTEMD_COLORS = true;
  };

  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  programs.git = {
    package = pkgs.gitAndTools.gitFull;
    enable = true;
    userName = name;
    userEmail = email;
    ignores = ["*~" "*.swp" "*.#"];
    aliases = {
      co = "checkout";
      ec = "config --global -e";
      up = "!git pull --rebase --prune $@ && git submodule update --init --recursive";
      cob = "checkout -b";
      cm = "!git add -A && git commit -m";
      save = "!git add -A && git commit -m 'SAVEPOINT'";
      wip = "!git add -u && git commit -m \"WIP\"";
      undo = "reset HEAD~1 --mixed";
      amend = "commit -a --amend";
      wipe = "!git add -A && git commit -qm 'WIPE SAVEPOINT' && git reset HEAD~1 --hard";
      # bcleanprod = "!f() { git branch --merged \${1-production} | grep -v \" \${1-production}$\" | xargs git branch -d; }; f";
      bdone = "!f() { git checkout \${1-main} && git up && git bclean \${1-main}; }; f";

      st = "status";
      sync = "!git fetch origin && git remote prune origin && :";
      searchfiles = "log --name-status --source --all -S";
      searchtext = "!f() { git grep \"$*\" $(git rev-list --all); }; f";
      uncommit = "reset --soft HEAD^";
      unstage = "reset HEAD --";
      diff-all = "!\"for name in $(git diff --name-only $1); do git difftool -y $1 $name & done\"";
      diff-changes = "diff --name-status -r";
      diff-stat = "diff --stat --ignore-space-change -r";
      diff-staged = "diff --cached";
      diff-upstream = "!git fetch origin && git diff main origin/main";
    };
    delta.enable = true;
    extraConfig = {
      branch.autoSetupRebase = "always";
      commit.template = "${commitTemplate}";
      core.editor = "vim";
      color.ui = "auto";
      credential.helper = "store --file ~/.git-credentials";
      format.signoff = true;
      init.defaultBranch = "main";
      protocol.keybase.allow = "always";
      pull.rebase = "true";
      push.autoSetupRemote = true;
      push.default = "current";
    };
  };
}

{
  config,
  pkgs,
  ...
}: {
  users.users.gziegan = {
    isNormalUser = true;
    description = "Greg Ziegan";
    extraGroups = ["networkmanager" "wheel"];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDhQYc5LT5giAndbsAoMC9/bVUhDWcD4pm4am8BMEK55 greg.ziegan@gmail.com" # mac-mini
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFiZiOE3W3eYeMSMkUwiLM/M7UJhmt1s0/QUDlXhwuVw greg.ziegan@gmail.com" # sankara
    ];
  };

  users.users.root.openssh.authorizedKeys.keys = config.users.users.gziegan.openssh.authorizedKeys.keys;
  home-manager.users.gziegan = import ../home-manager/gziegan;
}

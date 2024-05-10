let
  gziegan = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDhQYc5LT5giAndbsAoMC9/bVUhDWcD4pm4am8BMEK55 greg.ziegan@gmail.com"
  ];

  hosts = [
  ];

  publicKeys = gziegan ++ hosts;
in
{ }

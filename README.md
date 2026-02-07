# Backer Upper

A simple Bash script for orchestrating BorgBackup. It needs to be
configured with a `.configrc` file that should look something like this:

```sh
# Backup path
export BACKUP_PATH=/path/to/backup

# SSH connection details
export REPO_USER=me
export REPO_HOST=ssh.example.com
export REPO_PORT=22

# Absolute path to BorgBackup repository
export REPO_PATH=/path/to/borg/repo

# Borg environment variables
# NOTE Don't set BORG_REPO or BORG_RSH
# export BORG_PASSPHRASE="hunter2"
```

You will also need to put your backup host's SSH private key alongside
this, named `.secret-key`.

## Running as a systemd service (NixOS)

To run on-shutdown, before networking is torn down:

```nix
systemd.services.backer-upper = {
  description = "Backup on shutdown";
  serviceConfig = {
    Type = "oneshot";
    User = "<USER_ID>";
    ExecStart = "${pkgs.coreutils}/bin/true";
    ExecStop = backerUpperWrapper;
    TimeoutStartSec = "6h";
    TimeoutStopSec = "6h";
    RemainAfterExit = true;
    KillMode = "process";
    KillSignal = "SIGTERM";
    SendSIGKILL = false;
    StandardOutput = "journal";
    StandardError = "journal";
  };

  after = [
    "network-online.target"
    "multi-user.target"
  ];
  wants = [ "network-online.target" ];
  wantedBy = [ "multi-user.target" ];
};
```

where `backerUpperWrapper` is defined as:

```nix
backerUpperWrapper = pkgs.writeShellScript "backer-upper-wrapper" ''
  export PATH=${
    lib.makeBinPath [
      pkgs.bash
      pkgs.borgbackup
      pkgs.openssh
    ]
  }:$PATH

  exec /path/to/backer-upper/backup.sh
'';
```

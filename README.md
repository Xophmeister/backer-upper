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
    User = "<USERNAME>";
    ExecStart = "/path/to/backup.sh";
    TimeoutStartSec = "6h";
  };

  path = with pkgs; [ borgbackup openssh ];

  wants = [ "network-online.target" ];
  before = [ "shutdown.target" "network.target" ];
  wantedBy = [ "shutdown.target" ];
};
```

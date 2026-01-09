

# sysgit 

![sysgit-logo](sysgit-small.png) 

sysgit is a small command-line tool that lets a sysadmin version scattered configuration files across the system (for example `/etc`, `/opt/myproject/config`, `/srv/...`) into a **single Git repository**, without reorganizing the filesystem.

The idea: provide the equivalent of `etckeeper`, but for the entire system.

[🇫🇷 Traduction en Français ?](Readme-fr.md)

## Goal

- Keep a **clear history** of sensitive file changes.
- Answer:
  - "Who changed what, and when?"
  - "What did this file look like 3 days ago?"
- Without imposing a heavy configuration management stack.

sysgit does not replace Ansible/Puppet/etc. It provides a **minimal Git-based journal** for admins who still make direct changes on their servers.

## How it works

- sysgit uses a bare Git repository (`--bare`) stored outside the system tree (default: `/var/lib/sysgit`).
- Git's **work-tree** is set to `/`:
  - Git can see the whole filesystem.
  - sysgit only tracks paths you explicitly add.
- sysgit wraps Git with the right parameters (`--git-dir` / `--work-tree`) and a few useful defaults (for example `status.showUntrackedFiles=no`).

In short:
> One Git repository, many tracked paths, no reorganization of existing files.

## Install

```bash
make install
```

Custom install paths:

```bash
make install PREFIX=/usr/local SYSCONFDIR=/etc DESTDIR=/tmp/pkgroot
```

This installs:
- `sysgit` into `PREFIX/bin`
- the default config into `/etc/sysgit.conf_default`
- a live config if `/etc/sysgit.conf` does not already exist
- APT hook and systemd timer/service units for optional integrations

## Update

If sysgit was installed from a Git repository, you can update it with:

```bash
sysgit -u
```

This pulls the configured version and reinstalls the tool with the same paths.

## Usage

```bash
# Initialize the system repository
sysgit init

# Start tracking a few paths
sysgit add /etc /usr/local/sbin /srv/myapp/config.yml

# Review and commit changes
sysgit status
sysgit diff
sysgit commit -m "Initial system configuration"

# Edit sysgit's global ignore list
sysgit ignore
```

## Options and integrations

Optional features controlled by config flags, with usage context:

- Automatic autocommit:
  - What it does: captures regular snapshots even if you forget to commit.
  - When to use: servers with frequent manual or scripted changes.
  - Set `AUTOCOMMIT=1`, then enable the timer:
    - `systemctl enable --now sysgit-autocommit.timer`
  - Or run `sysgit -autocommit` manually.
- Logout check:
  - What it does: reminds you to commit before leaving a session.
  - When to use: ad-hoc, interactive changes.
  - Set `LOGOUT_CHECK=1` to inject a logout reminder in `~/.bash_logout`.
- Multiple committer profiles:
  - What it does: keeps admin identities separate for cleaner history.
  - When to use: shared servers with multiple admins, or prod/staging roles.
  - Set `MULTI_GIT_COMMITTER=1` to select or create profiles.
  - Use `sysgit -p <name-or-index>` to force a profile.
- APT/Dpkg hook:
  - What it does: records changes tied to package installs/upgrades.
  - When to use: auditing after `apt upgrade` or critical installs.
  - The hook runs `sysgit -apt` after package operations.
- Self-update:
  - What it does: reinstalls sysgit from the configured repo/branch.
  - When to use: environments that deploy sysgit via Git.
  - `sysgit -u` pulls from the configured repo/branch and reinstalls.
- Always root:
  - What it does: avoids permission errors by reexecing via `sudo`.
  - When to use: interactive use where `sudo` is easy to forget.
  - Set `ALWAYS_ROOT=1` to auto-reexec via `sudo`.

## Configuration

Edit `/etc/sysgit.conf` (based on `/etc/sysgit.conf_default`).

Common settings:
- `SYSGIT_DIR`: location of the bare repo (default: `/var/lib/sysgit`) to isolate system history.
- `GIT`: path to the git binary if you use a specific version.
- `AUTOCOMMIT`: enables regular snapshots via the timer.
- `LOGOUT_CHECK`: adds a logout commit reminder.
- `MULTI_GIT_COMMITTER`: manages distinct admin profiles.
- `ALWAYS_ROOT`: auto-reexecs with `sudo`.
- `SYSGIT_IGNORE_FILE`: global ignore file (default: `/etc/sysgit.ignore`).
- `SYSGIT_IGNORE_TEMPLATE`: template used to prefill the ignore file.

## Command-line flags

```
sysgit [-apt] [-autocommit] [-c <config>] [-p <profile>] [-u] [-h] [ignore|init|git-args...]
```

## License

Beerware. Author: David Mercereau.
Sites: https://retzo.net and https://david.mercereau.info

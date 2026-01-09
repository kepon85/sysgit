# sysgit

sysgit is a small command-line tool that lets a sysadmin version scattered configuration files across the system (for example `/etc`, `/opt/myproject/config`, `/srv/...`) into a **single Git repository**, without reorganizing the filesystem.

The idea: provide the equivalent of `etckeeper`, but for the entire system.

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
```

## Options and integrations

These are optional features controlled by config flags:

- Autocommit snapshots:
  - Set `AUTOCOMMIT=1`, then enable the timer:
    - `systemctl enable --now sysgit-autocommit.timer`
  - Or run `sysgit -autocommit` manually.
- Logout check:
  - Set `LOGOUT_CHECK=1` to inject a logout reminder in `~/.bash_logout`.
- Multiple committer profiles:
  - Set `MULTI_GIT_COMMITTER=1` to select or create profiles.
  - Use `sysgit -p <name-or-index>` to force a profile.
- APT/Dpkg hook:
  - The hook runs `sysgit -apt` after package operations.
- Self-update:
  - `sysgit -u` pulls from the configured repo/branch and reinstalls.
- Always root:
  - Set `ALWAYS_ROOT=1` to auto-reexec via `sudo`.

## Configuration

Edit `/etc/sysgit.conf` (based on `/etc/sysgit.conf_default`).

Common settings:
- `SYSGIT_DIR`: location of the bare repo (default: `/var/lib/sysgit`)
- `GIT`: path to the git binary
- `AUTOCOMMIT`, `LOGOUT_CHECK`, `MULTI_GIT_COMMITTER`, `ALWAYS_ROOT`

## Command-line flags

```
sysgit [-apt] [-autocommit] [-c <config>] [-p <profile>] [-u] [-h] [init|git-args...]
```

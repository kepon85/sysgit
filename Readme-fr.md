# sysgit

sysgit est un petit outil en ligne de commande qui permet à un·e admin système de versionner des fichiers de configuration dispersés sur le système (par exemple `/etc`, `/opt/monprojet/config`, `/srv/…`) dans un **seul dépôt Git**, sans réorganiser l’arborescence.

L’idée : offrir l’équivalent d’un `etckeeper`, mais à l’échelle du système entier.

## Objectif

- Garder un **historique clair** des modifications de fichiers sensibles.
- Pouvoir répondre à :
  - « Qui a changé quoi et quand ? »
  - « À quoi ressemblait ce fichier il y a 3 jours ? »
- Sans imposer un outil lourd de gestion de configuration.

sysgit ne remplace pas Ansible/Puppet/etc. Il fournit un **journal minimaliste**, basé sur Git, pour les admins qui bricolent aussi directement sur leurs serveurs.

## Principe

- sysgit utilise un dépôt Git “nu” (`--bare`) stocké hors de l’arborescence système (par ex. `/var/lib/sysgit`).
- Le **work-tree** de Git est positionné sur `/` :
  - Git voit tout le système de fichiers.
  - sysgit ajoute uniquement les chemins explicitement déclarés.
- Les commandes fournies par sysgit encapsulent Git avec les bons paramètres (`--git-dir` / `--work-tree`) et quelques réglages utiles (par exemple `status.showUntrackedFiles=no`).

En résumé :
> Un seul dépôt Git, plusieurs chemins suivis, aucune réorganisation des fichiers existants.

## Installation

```bash
make install
```

Installation avec chemins personnalisés :

```bash
make install PREFIX=/usr/local SYSCONFDIR=/etc DESTDIR=/tmp/pkgroot
```

Cela installe :
- `sysgit` dans `PREFIX/bin`
- la config par défaut dans `/etc/sysgit.conf_default`
- une config active si `/etc/sysgit.conf` n’existe pas
- le hook APT et les unités systemd pour les intégrations optionnelles

## Usage

```bash
# Initialiser le dépôt “système”
sysgit init

# Commencer à suivre quelques chemins
sysgit add /etc /usr/local/sbin /srv/monapp/config.yml

# Vérifier et commiter
sysgit status
sysgit diff
sysgit commit -m "État initial de la configuration système"
```

## Options et intégrations

Fonctionnalités optionnelles pilotées par la config :

- Autocommit :
  - Activer `AUTOCOMMIT=1`, puis activer le timer :
    - `systemctl enable --now sysgit-autocommit.timer`
  - Ou lancer `sysgit -autocommit` manuellement.
- Vérification au logout :
  - Activer `LOGOUT_CHECK=1` pour ajouter un rappel dans `~/.bash_logout`.
- Profils multiples :
  - Activer `MULTI_GIT_COMMITTER=1` pour choisir/créer un profil.
  - Forcer un profil avec `sysgit -p <nom-ou-index>`.
- Hook APT/dpkg :
  - Le hook exécute `sysgit -apt` après une opération de paquets.
- Mise à jour :
  - `sysgit -u` récupère le dépôt configuré et réinstalle.
- Toujours root :
  - Activer `ALWAYS_ROOT=1` pour se relancer via `sudo`.

## Configuration

Éditer `/etc/sysgit.conf` (basé sur `/etc/sysgit.conf_default`).

Paramètres fréquents :
- `SYSGIT_DIR` : emplacement du dépôt bare (défaut : `/var/lib/sysgit`)
- `GIT` : chemin vers le binaire git
- `AUTOCOMMIT`, `LOGOUT_CHECK`, `MULTI_GIT_COMMITTER`, `ALWAYS_ROOT`

## Options en ligne de commande

```
sysgit [-apt] [-autocommit] [-c <config>] [-p <profil>] [-u] [-h] [init|git-args...]
```

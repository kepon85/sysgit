# sysgit

sysgit est un petit outil en ligne de commande qui permet à un·e admin système de versionner des fichiers de configuration dispersés sur le système (par exemple `/etc`, `/opt/monprojet/config`, `/srv/…`) dans un **seul dépôt Git**, sans réorganiser l’arborescence, en choisissant précisément ce qu’on souhaite suivre.

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

## Mise à jour

Si sysgit a été installé depuis un dépôt Git, vous pouvez le mettre à jour :

```bash
sysgit -u
```

Cela récupère la version configurée et réinstalle l’outil avec les mêmes chemins.

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

Fonctionnalités optionnelles pilotées par la config, avec un contexte d'usage :

- Autocommit automatique :
  - À quoi ça sert : capturer des instantanés réguliers même si on oublie de committer.
  - Contexte : pratique sur des serveurs modifiés souvent et par plusieurs scripts.
  - Activer `AUTOCOMMIT=1`, puis le timer :
    - `systemctl enable --now sysgit-autocommit.timer`
  - Ou lancer `sysgit -autocommit` manuellement.
- Vérification au logout :
  - À quoi ça sert : rappeler de committer avant de quitter une session.
  - Contexte : utile quand les changements sont faits à la main et de manière ponctuelle.
  - Activer `LOGOUT_CHECK=1` pour ajouter un rappel dans `~/.bash_logout`.
- Profils multiples :
  - À quoi ça sert : séparer l'identité Git des admins pour un historique clair.
  - Contexte : serveur partagé entre plusieurs admins, ou alternance prod/staging.
  - Activer `MULTI_GIT_COMMITTER=1` pour choisir/créer un profil.
  - Forcer un profil avec `sysgit -p <nom-ou-index>`.
- Hook APT/dpkg :
  - À quoi ça sert : enregistrer les changements liés aux mises à jour de paquets.
  - Contexte : audit rapide après un `apt upgrade` ou une installation critique.
  - Le hook exécute `sysgit -apt` après une opération de paquets.
- Mise à jour :
  - À quoi ça sert : réinstaller sysgit depuis le dépôt configuré.
  - Contexte : environnements où l'outil est déployé via Git.
  - `sysgit -u` récupère le dépôt configuré et réinstalle.
- Toujours root :
  - À quoi ça sert : éviter les erreurs de permissions en se relançant en root.
  - Contexte : usage interactif où l'on oublie parfois `sudo`.
  - Activer `ALWAYS_ROOT=1` pour se relancer via `sudo`.

## Configuration

Éditer `/etc/sysgit.conf` (basé sur `/etc/sysgit.conf_default`).

Paramètres fréquents :
- `SYSGIT_DIR` : emplacement du dépôt bare (défaut : `/var/lib/sysgit`) pour isoler l'historique système.
- `GIT` : chemin vers le binaire git si vous utilisez une version spécifique.
- `AUTOCOMMIT` : active les instantanés réguliers via timer.
- `LOGOUT_CHECK` : ajoute un rappel de commit à la déconnexion.
- `MULTI_GIT_COMMITTER` : gère des profils d'admins distincts.
- `ALWAYS_ROOT` : relance automatiquement avec `sudo`.

## Options en ligne de commande

```
sysgit [-apt] [-autocommit] [-c <config>] [-p <profil>] [-u] [-h] [init|git-args...]
```

## Licence

Beerware. Auteur : David Mercereau.
Sites : https://retzo.net et https://david.mercereau.info

# sysgit

![sysgit-logo](sysgit-small.png) 

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

Installation rapide (2 commandes) :

```bash
wget -O /tmp/sysgit-install.sh https://framagit.org/kepon/sysgit/-/raw/main/install.sh
sudo bash /tmp/sysgit-install.sh
```

Le script vérifie `make` + un outil de téléchargement (git/curl/wget), récupère le dépôt puis lance `make install`.
Variables utiles : `PREFIX=/opt SYSCONFDIR=/etc SYSGIT_BRANCH=main SYSGIT_REPO_URL=https://framagit.org/kepon/sysgit.git bash install.sh`.
Pour ne pas installer le timer autocommit (ex. pas de systemd ou planification gérée autrement) : `SYSGIT_INSTALL_AUTOCOMMIT_TIMER=0 bash install.sh` ou `make install INSTALL_AUTOCOMMIT_TIMER=0`.

```bash
make install
```

Installation personnalisés :

```bash
git clone https://framagit.org/kepon/sysgit.git
cd sysgit
make install PREFIX=/usr/local SYSCONFDIR=/etc DESTDIR=/tmp/pkgroot
```

Cela installe :
- `sysgit` dans `PREFIX/bin`
- la config par défaut dans `/etc/sysgit.conf_default`
- une config active si `/etc/sysgit.conf` n’existe pas
- le hook APT et les unités systemd pour les intégrations optionnelles (le `systemctl daemon-reload` est lancé automatiquement si disponible)

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

# Revenir à l'état du dernier commit (staging et fichier)
sysgit restore --staged -- /etc/maconf
sysgit checkout -- /etc/maconf

# Éditer l'ignore global de sysgit
sysgit ignore
# Arrêter de suivre un fichier déjà versionné après l'avoir ajouté à l'ignore
sysgit rm -r --cached -- /etc/getmail
```

## Rappels Git utiles avec sysgit

- `sysgit status --short` : aperçu rapide de ce qui est modifié sur le système.
- `sysgit add -u` : indexer toutes les modifications de fichiers déjà suivis (pratique en cron).
- `sysgit rm --cached -- /chemin` : après avoir ajouté un fichier à l'ignore, le retirer de l'index pour qu'il ne soit plus tracké.
- `sysgit log --oneline -p` : relire rapidement qui a modifié quoi (avec le diff).
- `sysgit restore --staged -- /chemin` ou `sysgit checkout -- /chemin` : revenir à l'état du dernier commit si une modification n'est pas souhaitée.

## Options et intégrations

Fonctionnalités optionnelles pilotées par la config, avec un contexte d'usage :

- Autocommit automatique :
  - À quoi ça sert : capturer des instantanés réguliers même si on oublie de committer.
  - Contexte : pratique sur des serveurs modifiés souvent et par plusieurs scripts.
  - Activer `AUTOCOMMIT=1`, puis le timer :
    - `systemctl enable --now sysgit-autocommit.timer`
    - L’installation peut ignorer le timer avec `SYSGIT_INSTALL_AUTOCOMMIT_TIMER=0` ou `INSTALL_AUTOCOMMIT_TIMER=0`.
  - Ou lancer `sysgit -autocommit` manuellement.
- Vérification au logout :
  - À quoi ça sert : rappeler de committer avant de quitter une session.
  - Contexte : utile quand les changements sont faits à la main et de manière ponctuelle.
  - Activer `LOGOUT_CHECK=1` pour ajouter un rappel dans `~/.bash_logout`.
- Profils multiples :
  - À quoi ça sert : séparer l'identité Git des admins pour un historique clair.
  - Contexte : serveur partagé entre plusieurs admins, ou alternance prod/staging. sysgit mémorise la provenance (SSH_CLIENT/SSH_CONNECTION/TTY) dans `sysgit.profile.history` et rattache automatiquement, pendant 7 jours, le dernier profil utilisé depuis la même source. Pratique sur un bastion ou une session tmux/screen qui vit longtemps.
  - Activer `MULTI_GIT_COMMITTER=1` pour choisir/créer un profil interactif dans `SYSGIT_DIR/sysgit.profile` au format `Nom|email`.
  - Forcer ou créer un profil explicitement (y compris en non-interactif) avec `sysgit -p "Nom|email@example.org"` ou `sysgit -p <index>` (l'index correspond à la ligne du fichier de profils). Cela évite d'avoir des commits "root" anonymes dans les hooks ou cron.
```
root@srvmail:~# sysgit status
Choisir un profil:
 1) David - david.*********@retzien.fr
 0) Creer un nouveau profil
Votre choix: 0
Nom: Serge
Email: serge.*********@retzien.fr
Sur la branche master
Modifications qui ne seront pas validées :
  (utilisez "git add <fichier>..." pour mettre à jour ce qui sera validé)
  (utilisez "git restore <fichier>..." pour annuler les modifications dans le répertoire de travail)
	modifié :         ../etc/sympa/sympa_transport
	modifié :         ../etc/sympa/sympa_transport.db

aucune modification n'a été ajoutée à la validation (utilisez "git add" ou "git commit -a")
root@srvmail:~# sysgit add /etc/sympa/sympa_transport*
En tant que Serge <serge.*********@retzien.fr> (preciser -p pour changer)
root@srvmail:~# sysgit commit -m "Suppressoin de mailing liste"
En tant que Serge <serge.*********@retzien.fr> (preciser -p pour changer)
sending incremental file list
root@srvmail:~# sysgit log
En tant que Serge <serge.*********@retzien.fr> (preciser -p pour changer)
commit 428bb2401993b91e90a4dabac53d8d129fb378b4 (HEAD -> master)
Author: Serge <serge.*********@retzien.fr>
Date:   Tue Jan 20 10:07:22 2026 +0100

    Suppressoin de mailing liste

commit e952c0fd43317cba8afead584b7933621eb307f7
Author: David <david.*********@retzien.fr>
Date:   Tue Jan 20 09:37:19 2026 +0100

    Changement éditeur par défaut
```
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
- `SYSGIT_IGNORE_FILE` : ignore global (défaut : `/etc/sysgit.ignore`).
- `SYSGIT_IGNORE_TEMPLATE` : modèle pour pré-remplir l'ignore s'il est absent.

## Options en ligne de commande

```
sysgit [-apt] [-autocommit] [-c <config>] [-p <profil>] [-u] [-h] [ignore|init|git-args...]
```

## Hooks Git (pre/post-commit, pre/post-push)

Les hooks Git se placent dans le dépôt bare de sysgit :
`SYSGIT_DIR/hooks` (par défaut `/var/lib/sysgit/hooks`).

Comment ça marche :
- Créez un script exécutable nommé `pre-commit`, `post-commit`, `pre-push`,
  `post-push`, etc.
- Git exécute automatiquement ces scripts quand la commande correspondante est
  appelée via `sysgit` (par exemple `sysgit commit` ou `sysgit push`).
- Utilisez-les pour ajouter des contrôles, des notifications, des exports ou
  des actions d'audit.
- Des exemples sont fournis dans `hooks/*.sample` (à copier/adapter).

Exemple (post-commit) pour loguer les commits dans syslog sur un serveur partagé :

```bash
#!/bin/bash
# Fichier : ${SYSGIT_DIR:-/var/lib/sysgit}/hooks/post-commit
logger -t sysgit "commit $(git rev-parse --short HEAD) par ${GIT_COMMITTER_NAME} <${GIT_COMMITTER_EMAIL}> : $(git show -s --format=%s)"
```

## Migration depuis etckeeper

Si vous avez deja un depot etckeeper dans `/etc/.git`, vous pouvez importer
son historique dans sysgit sans perdre le "passif" :

```bash
# En tant que root
./etckeeper-migrate.sh
```

Notes :
- Le script ajoute le prefixe `/etc` a tous les commits etckeeper puis les
  fusionne dans sysgit (branche `etckeeper-migrate`).
- La fusion utilise une strategie "ours" pour eviter les conflits (l'etat
  courant sysgit est conserve, l'historique etckeeper reste accessible).
- Le depot sysgit ne doit pas encore etre initialise (pas de `sysgit init`)
  avant la migration.
- Apres import, vous pouvez aligner l'etat courant :
  `sysgit add -A /etc && sysgit commit -m "Sync /etc"`.
- Si vous n'utilisez plus etckeeper, stoppez-le et supprimez `/etc/.git`
  (ou ajoutez-le a `SYSGIT_IGNORE_FILE`).

Exemple de sequence qui fonctionne :

```bash
bash etckeeper-migrate.sh
rm -rf /etc/.git
sysgit init
git add .
sysgit commit -m "etckeeper-migrate"
```

## Licence

Beerware. Auteur : David Mercereau.
Sites : https://retzo.net et https://david.mercereau.info

# sysgit

sysgit est un petit outil en ligne de commande qui permet à un·e admin système de versionner des fichiers de configuration dispersés sur le système (par exemple `/etc`, `/opt/monprojet/config`, `/srv/…`) dans un **seul dépôt Git**, sans réorganiser l’arborescence.

L’idée : offrir l’équivalent d’un `etckeeper`, mais à l’échelle du système entier.

## Objectif

- Garder un **historique clair** des modifications de fichiers sensibles.
- Pouvoir répondre à :  
  – « Qui a changé quoi et quand ? »  
  – « À quoi ressemblait ce fichier il y a 3 jours ? »  
- Sans imposer un outil lourd de gestion de configuration.

sysgit ne remplace pas Ansible/Puppet/etc. Il fournit un **journal minimaliste**, basé sur Git, pour les admins qui bricolent aussi directement sur leurs serveurs.

## Principe

- sysgit utilise un dépôt Git “nu” (`--bare`) stocké hors de l’arborescence système (par ex. `/root/.sysgit`).
- Le **work-tree** de Git est positionné sur `/` :
  - Git voit tout le système de fichiers.
  - sysgit ajoute uniquement les chemins explicitement déclarés.
- Les commandes fournies par sysgit encapsulent Git avec les bons paramètres (`--git-dir` / `--work-tree`) et quelques réglages utiles (par exemple `status.showUntrackedFiles=no`).

En résumé :  
> Un seul dépôt Git, plusieurs chemins suivis, aucune réorganisation des fichiers existants.


## Fonctionnalités prévues

- Initialisation du dépôt système :
  - `sysgit init`  
- Déclaration de fichiers ou répertoires à suivre :
  - `sysgit add /etc /root/bin /srv/monapp/config.yml`
- Consultation de l’état :
  - `sysgit status`  
  - `sysgit diff`  
  - `sysgit log`
- Commit rapide des changements :
  - `sysgit commit -m "message"`
- Intégration optionnelle :
  - Hooks APT/dpkg pour committer après des mises à jour de paquets.
  - Timer systemd / cron pour des snapshots automatiques (par exemple chaque nuit).

sysgit reste volontairement fin : tout ce qui touche à la politique de commit (fréquence, message, hooks) est configurable.

---

## Exemple d’usage

Initialisation :

```bash
# Initialiser le dépôt “système”
sysgit init

# Commencer à suivre quelques chemins
sysgit add /etc /usr/local/sbin /srv/monapp/config.yml

# Premier commit
sysgit commit -m "État initial de la configuration système"
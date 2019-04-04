#!/bin/bash

set -exu
USER=${USER:-$(id -un)}
ws_name=$(cd /srv/workspace && find * -maxdepth 0 -type d | tail -1)
(cd /tmp && mkdir "$ws_name" && cd "$ws_name" && ln -s "/srv/workspace/$ws_name"/ ./workspace && ln -s "/srv/shared"/ ./)
date
mkdir -p ~/some/arbitrary/path
touch ~/some/arbitrary/path/bad_news.file
sudo chown root ~/some/arbitrary/path/bad_news.file
chown_everything() {
  HOME=${HOME:-$(cd; pwd)}
  local target=${1:-$HOME}
  # (cd ~/ && ls -A | egrep -v '^app$' | while read x ; do chown -R $USER ~/"$x" ; done)
  (cd "$target" && find . -type d -name app -prune -o \! -user $USER -print | while read x ; do sudo chown $USER "$x" ; done)
}
sync_mount_keys() {
if [[ -d /srv/mount_keys ]] ; then
  if [[ -d /srv/mount_keys/.ssh ]] ; then
    rsync -av /srv/mount_keys/ ~/
  elif [[ -d /srv/mount_keys/id_rsa ]] ; then
    rsync -av /srv/mount_keys/ ~/.ssh
  elif [[ -d /srv/mount_keys/.aws ]] ; then
    rsync -av /srv/mount_keys/ ~/
    echo "WARNING: Found no .ssh folder in /srv/mount_keys"
  else
    echo "WARNING: Found nothing interesting in /srv/mount_keys"
    find /srv/mount_keys
    echo
  fi 1>&2
fi ;
}
set -x
time sync_mount_keys
date
for d in .ssh .aws ; do
  [[ -d ~/$d ]] || mkdir -p ~/$d
  [[ ! -d ~/$d ]] || time chmod -R go-rwx ~/$d
done
date
echo "WORKSPACE_USER=$WORKSPACE_USER"
[[ -z $WORKSPACE_USER ]] || echo -e "\nHost *\n  User $WORKSPACE_USER" >> ~/.ssh/config
time chown_everything
set +x
date



# [[ -z $WORKSPACE_USERPW ]] || auth="--auth $WORKSPACE_USERPW"

auth=''
[[ -z $WORKSPACE_USERPW ]] || auth="--auth $WORKSPACE_USERPW"



authf=${authf:-}
if [[ '' ]] ; then
  if echo "$WORKSPACE_USERPW" | egrep '[,]' >/dev/null ; then
    authf=$(mktemp)
    id=1
    echo "$WORKSPACE_USERPW" | tr ',' '\n' | while read pair; do
      echo "$pair" | sed 's/^\([^:]*\):/\1|/; s/$/||/' | sed "s/^/$id|/" >> $authf
      id=$((id+1))
    done
    ( echo "DEBUG: authf $authf:"
      cat $authf
    ) >&2
    # auth=''
    auth=$(head -1 "$authf" | awk -F'|' '{print $2 ":" $3}')
    auth="--auth $auth"

    # DOES NOT YET WORK authf="--authf $authf"
    authf=''

  fi
fi

# echo "DEBUG: WORKSPACE_USERPW=$WORKSPACE_USERPW" > /w/tmp.auth.txt
# echo "DEBUG: auth=$auth" > /w/tmp.auth.txt
set -x
node server.js -w "/tmp/$ws_name" --listen 0.0.0.0 --collab $auth $authf --debug

#!/bin/bash

USER=${USER:-$(id -un)}
[[ ! -d /srv/mount_keys ]] || rsync -av /srv/mount_keys/ ~/
(cd ~/ && ls -A | egrep -v '^app$' | while read x ; do chown -R $USER ~/"$x" ; done)
# [[ -z $WORKSPACE_USERPW ]] || auth="--auth $WORKSPACE_USERPW"

auth=''
[[ -z $WORKSPACE_USERPW ]] || auth="--auth $WORKSPACE_USERPW"
if [[ '' ]] ; then
  authf=''
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
echo "DEBUG: auth=$auth" > /w/tmp.auth.txt
set -x
node server.js -w /w --listen 0.0.0.0 --collab $auth $authf --debug

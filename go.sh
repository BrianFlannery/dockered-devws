#!/bin/bash

# # # USAGE: go.sh $ws_name
# # #   Where $ws_name is the name of your workspace and usually matches
# # #   a subfolder in your source code location ($WORKSPACE_REPOS, maybe ~/gits or ~/repos)
# # #   and a subfolder in your secret/key folder ($WORKSPACE_KEYS, ~/.ssh or ~/my_secret_files_do_not_look).
# # #   Like '~/repos/github-githubUsername-project14'
# # #   (where github-githubUsername-project14 is $ws_name).
# # #
# # #   Set $WORKSPACE_KEYS and $WORKSPACE_REPOS if you do not want their defaults:
# # #   Example: WORKSPACE_KEYS=~/some_secrets WORKSPACE_REPOS=~/work-git go.sh some-workspace

ws_name=${1:-defaultws} ; shift

USER=${USER:-$(id -un)}
HOME=${HOME:-$(cd;pwd)}
WORKSPACE_KEYS=${WORKSPACE_KEYS:-$HOME/.ssh/workspaces}
WORKSPACE_REPOS=${WORKSPACE_REPOS:-$HOME/repos}
WORKSPACE_PORT=${WORKSPACE_PORT:-8182}
export WORKSPACE_USER=${WORKSPACE_USER:-$USER}
export WORKSPACE_USERPW=${WORKSPACE_USERPW:-}

version=0.0.7
image='dockered-devws'
container="dockdevws-$ws_name"

PWD0=${PWD:-$(pwd)}
DIR0=$(dirname "$0")
MOUNT_WS="$WORKSPACE_REPOS/$ws_name"
MOUNT_KEYS="$WORKSPACE_KEYS/$ws_name"
MOUNT_SHARED="$WORKSPACE_REPOS/$image-shared"

main() {
  local arg1=${1:-}
  docker_build \
  && docker_run \
  && if [[ $arg1 == test ]] ; then
    testIt "$@"
  fi ;
}
die() { echo "${1:-ERROR}" 1>&2 ; exit ${2:-2} ; }

docker_build() {
  [[ ! -d tmp.d ]] || rm -rf tmp.d
  mkdir tmp.d
  cp -r image/* tmp.d/ || die "ERROR $?: Failed to cp the image folder to tmp.d"
  cp -r container tmp.d/ || die "ERROR $?: Failed to cp the container folder to tmp.d"
  cmd="docker build"
  # cmd="$cmd --build-arg PERMS_GID=$(id -g)"
  cmd="$cmd -t $image:$version ."
  cd tmp.d/ && {
    $cmd || die "ERROR $?: Failed to $cmd"
  } && cd ..
}
check_path_or_die() {
  local path=$1
  local name=$2
  local errorPrefix=${3:-ERROR: }
  local errorSuffix=${4:-}
  [[ -z $errorSuffix ]] || errorSuffix=" $errorSuffix"
  local isSecret=$(echo "$path" | egrep '/\.(not_public|secret(s)?|ssh)/')
  if [[ ! -d "$path" ]] ; then
    if [[ -z $isSecret ]] ; then
      mkdir -p "$path"
    else
      ( umask 077 && mkdir -p "$path" )
    fi ;
  fi ;
  [[ -d "$path" ]] || die "$errorPrefix $name '$path'$errorSuffix"
}
docker_run() {
  local msg0='ERROR: Failed to find'
  local msg1='be sure to set'
  local msg2="to a valid path with a workspace subfolder named $ws_name"

  # # [[ -d $MOUNT_WS ]] || die "$msg0 workspace path $MOUNT_WS ($msg1 \$WORKSPACE_REPOS $msg2)"
  # [[ -d $MOUNT_WS ]] || mkdir -p "$MOUNT_WS" \
  # || die "$msg0 workspace path $MOUNT_WS ($msg1 \$WORKSPACE_REPOS $msg2)"
  # [[ -d $MOUNT_KEYS ]] || (umask 077 && mkdir -p "$MOUNT_WS" ) \
  # || die "$msg0 keys/secrets path $MOUNT_KEYS ($msg1 \$WORKSPACE_KEYS $msg2)"
  check_path_or_die "$MOUNT_WS"              "workspace path"   "($msg1 \$WORKSPACE_REPOS $msg2)"
  check_path_or_die "$MOUNT_KEYS"            "keys/secret path" "($msg1 \$WORKSPACE_KEYS $msg2)"
  check_path_or_die "$MOUNT_SHARED/$ws_name" "shared path"      "($msg1 \$WORKSPACE_REPOS/\$image-shared $msg2)"

  MOUNT_WS=$(cd "$MOUNT_WS" && pwd)
  MOUNT_KEYS=$(cd "$MOUNT_KEYS" && pwd)
  MOUNT_SHARED=$(cd "$MOUNT_SHARED" && pwd)

  docker rm -f $container 2>/dev/null || true

  cmd="docker run --rm -d"
  cmd="$cmd --tmpfs /tmp --tmpfs /run"
  # cmd="$cmd -v /sys/fs/cgroup:/sys/fs/cgroup:ro"
  cmd="$cmd -v $MOUNT_KEYS:/srv/mount_keys:ro"
  cmd="$cmd -v $MOUNT_WS:/srv/workspace/$ws_name"
  cmd="$cmd -v $MOUNT_SHARED:/srv/shared"
  cmd="$cmd -v $(pwd)/container:/srv/container"
  cmd="$cmd -p $WORKSPACE_PORT:8181"

  [[ -z $WORKSPACE_USERPW ]] || cmd="$cmd -e WORKSPACE_USERPW"
  cmd="$cmd -e WORKSPACE_USERPW"
  cmd="$cmd -e WORKSPACE_USER"

  cmd="$cmd --name=$container $image:$version"
  $cmd || die "ERROR $?: Failed to $cmd"
  echo "NOTE: Container $container should be running." 1>&2
}
testIt() {
  set -x
  docker exec -it "$container" bash /srv/container/test-within.sh
}

cd "$DIR0" && main "$@"

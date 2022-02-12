#!/bin/bash
set -eu -o pipefail

usage() {
  cat << EOF
  usage:
  $0 [limafile]
  Options:
  limafile - File to be fed to limactl to configure the lima VM
EOF
}

limafile=${1:-"default.yaml"}

debian_install(){
    LIMA_VERSION=${LIMA_VERSION:-"v0.8.2"}
    ARCH="$(uname -m)"
    curl -o lima.tar.gz https://github.com/lima-vm/lima/releases/download/${LIMA_VERSION}/lima-${LIMA_VERSION}-Linux-${ARCH}.tar.gz
    #TODO Ubuntu Docker CLI installation
    #TODO Ubuntu Docker Compose installation
}

osx_install(){
  declare -a deps=(lima docker docker-compose)

  for dep in "${deps[@]}"; do
    echo "$dep"
    if ! command -v $dep 2>&1 >/dev/null ; then
      echo "installing $dep"
      brew install $dep
    fi
  done
}

if [[ "$OSTYPE" == "darwin"* ]]; then
  osx_install
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  debian_install
fi

limactl start $limafile

if [[ $limafile == "docker.yaml" ]]; then
  if ! docker context ls --format '{{ .Name }}' | grep -q docker; then
    docker context create lima-docker --docker "host=unix:///Users/tim.seagren/.lima/docker/sock/docker.sock"
  fi
  docker context use lima-docker
fi
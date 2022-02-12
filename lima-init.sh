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
  context="docker"
  if ! docker context ls --format '{{ .Name }}' | grep -q $context; then
    docker context create lima-docker --docker "host=unix:///${HOME}/.lima/$context/sock/docker.sock"
  fi
  docker context use $context
fi

if [[ $limafile == "k3d-lima.yaml" ]]; then
  context="k3d-lima"
  if ! docker context ls --format '{{ .Name }}' | grep -q $context; then
    docker context create $context --docker "host=unix:///${HOME}/.lima/$context/sock/docker.sock"
  fi
  docker context use $context
fi

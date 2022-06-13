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
  declare -a qemu_deps=(qemu qemu-system qemu-utils)
  for dep in "${qemu_deps[@]}"; do
    if ! dpkg -l | grep -q "\b$dep\b" 2>&1 >/dev/null; then
      sudo apt-get install $dep
    fi
  done
  # if ! command -v lima 2>&1 >/dev/null ; then
  #   LIMA_VERSION=${LIMA_VERSION:-"0.8.2"}
  #   ARCH="$(uname -m)"
  #   echo "Downloading lima $LIMA_VERSION"
    # curl -fsSL  https://github.com/lima-vm/lima/releases/download/v${LIMA_VERSION}/lima-${LIMA_VERSION}-Linux-${ARCH}.tar.gz | tar Cxzvm /usr/local
  # fi
  if ! command -v lima 2>&1 >/dev/null ; then
    LIMA_VERSION=${LIMA_VERSION:-"0.8.2"}
    ARCH="$(uname -m)"
    echo "Downloading lima $LIMA_VERSION"
    curl -fsSL https://github.com/lima-vm/lima/archive/refs/tags/v0.8.2.tar.gz | tar xzvf -
    cd lima-${LIMA_VERSION}
    make && sudo make install
    cd -
    rm -rf lima-${LIMA_VERSION}
  fi
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

limactl start --tty=false $limafile

if [[ $limafile == "docker.yaml" ]]; then
  context="docker"
  if ! docker context ls --format '{{ .Name }}' | grep -q $context; then
    docker context create $context --docker "host=unix:///${HOME}/.lima/$context/sock/docker.sock"
  fi
  docker context use $context
  docker run -d -p 5000:5000 registry:2
fi

if [[ $limafile == "k3s.yaml" ]]; then
  mkdir -p "${HOME}/.lima/k3s/conf"
  kubeconfig="${HOME}/.lima/k3s/conf/kubeconfig.yaml"
  limactl shell k3s sudo cat /etc/rancher/k3s/k3s.yaml >$kubeconfig
  if command -v kubeconfig-combine 2>&1 >/dev/null ; then
    kubeconfig-combine --allow-overwrite --all-name lima-k3s $kubeconfig
  fi
fi

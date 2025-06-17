#!/bin/bash

# Saving current work dir
pushd -n $(pwd) > /dev/null
# Creating temp work dir
dir_path="$HOME/$(uuidgen)"
mkdir ${dir_path} && cd ${dir_path}
echo "temp working dir is $(pwd)"

VERSION=3.13.5
VERSION_SHORT=3.13

# Install dependencies
sudo apt-get -yq install \
  wget \
  build-essential \
  pkg-config \
  ccache \
  gdb \
  lcov \
  libc6-dev \
  libb2-dev \
  libbz2-dev \
  libffi-dev \
  libgdbm-dev \
  libgdbm-compat-dev \
  liblzma-dev \
  libexpat1-dev \
  libdb5.3-dev \
  libgdm-dev \
  libncurses-dev \
  libncursesw5-dev \
  libncurses5-dev \
  libreadline-dev \
  libreadline6-dev \
  libreadline-gplv2-dev \
  libsqlite3-dev \
  libssl-dev \
  libzstd-dev \
  lzma \
  lzma-dev \
  strace \
  tk-dev \
  uuid-dev \
  xvfb \
  zlib1g-dev

  
if [ ! -f Python-${VERSION}.tgz ]; then
  wget -O Python-${VERSION}.tgz https://www.python.org/ftp/python/${VERSION}/Python-${VERSION}.tgz
fi

tar xzf Python-${VERSION}.tgz
cd Python-${VERSION}
if [ ! -f python ]; then
  ./configure --enable-optimizations --with-ensurepip=install
fi

make -j$(nproc)

sudo make altinstall

sudo update-alternatives --install /usr/bin/python python /usr/local/bin/python${VERSION_SHORT} 1
sudo update-alternatives --install /usr/bin/python3 python3 /usr/local/bin/python${VERSION_SHORT} 1

# /usr/local/bin/python${VERSION_SHORT} -m pip install --upgrade pip
sudo update-alternatives --install /usr/bin/pip pip /usr/local/bin/pip${VERSION_SHORT} 1
sudo update-alternatives --install /usr/bin/pip3 pip3 /usr/local/bin/pip${VERSION_SHORT} 1
  
# Removing temp dir
cd ~ && rm -rf ${dir_path}
#!/bin/bash

#############################################
# Install XZ Utils Library
#
# Created by Joshua Smith
# Created on 05-18-2020
#
#############################################

function InstallXZ {

  mkdir -p /Users/Shared/xz/latest

  # Download the latest copy of XZ Utils and extract the archive.

  curl -L https://sourceforge.net/projects/lzmautils/files/latest/download > /Users/Shared/xz/latest/xz-latest.tar.gz
  tar -xf /Users/Shared/xz/latest/xz-latest.tar.gz -C /Users/Shared/xz/latest

  # Create the Makefile and perform the installation.

  (cd /Users/Shared/xz/latest/xz* && ./configure)
  make -C /Users/Shared/xz/latest/xz*/ install

  # Clean up the installer archive, move the extracted files to the parent folder, and set permissions.

  rm /Users/Shared/xz/latest/xz-latest.tar.gz
  cp -rf /Users/Shared/xz/latest/xz* /Users/Shared/xz/
  chmod -R 777 /Users/Shared/xz

}

if [[ -d "/Users/Shared/xz/latest" ]]; then

  rm -rf /Users/Shared/xz/latest
  InstallXZ

else

  InstallXZ

fi

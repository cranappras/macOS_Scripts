#!/bin/bash

if [[ -d "/Users/Shared/lz4" ]]; then
  make -C /Users/Shared/lz4/ install
else
  git clone https://github.com/lz4/lz4.git /Users/Shared/lz4
  make -C /Users/Shared/lz4/ install
fi

#!/bin/bash
echo "#############################"
echo Installing NVM
echo "#############################"

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh | bash

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" 

nvm -v

echo "##################################"
echo Installing Nodejs $NODE_VERSION...
echo "##################################"

nvm install $NODE_VERSION
nvm use $NODE_VERSION
node -v
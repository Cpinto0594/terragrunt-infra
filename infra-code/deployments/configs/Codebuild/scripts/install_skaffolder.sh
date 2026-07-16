#!/bin/bash
echo Installing Skaffolder...

SKAFFOLDER_PATH=$1

cd $SKAFFOLDER_PATH
npm run skaffolder-install



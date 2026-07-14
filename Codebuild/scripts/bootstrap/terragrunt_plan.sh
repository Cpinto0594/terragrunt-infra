#!/bin/bash

cd deployment/$environment/$region/projects/$project

for i in $(ls -d */); do
    NAMESPACE="${i%%/}" 
    CURRENT_PLAN_FOLDER=$CODEBUILD_SRC_DIR/deployment/$environment/$region/projects/$project/$NAMESPACE
    PLAN_FILE_NAME="$environment-$project-$NAMESPACE.tfplan"
    PLAN_FILE_LOCATION="$CURRENT_PLAN_FOLDER/$PLAN_FILE_NAME"
    TF_PLANS_FOLDER="$CODEBUILD_SRC_DIR/outputs/tf-plans/$environment/$region/projects/$project/$NAMESPACE"


    echo
    echo
    echo "< ====================================================="
    echo "Running plan in folder $CURRENT_PLAN_FOLDER"
    echo "===================================================== >"
    echo
    echo

    terragrunt plan --terragrunt-non-interactive --terragrunt-working-dir "$CURRENT_PLAN_FOLDER"  -out="$PLAN_FILE_LOCATION"

    echo "Moving $PLAN_FILE_LOCATION to $TF_PLANS_FOLDER"
    mkdir -p "$TF_PLANS_FOLDER"
    cp "$PLAN_FILE_LOCATION" "$TF_PLANS_FOLDER/$PLAN_FILE_NAME"
done;


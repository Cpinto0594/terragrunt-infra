#!/bin/bash

cd deployment/$environment/$region/projects/$project

for i in $(ls -d */); do
    NAMESPACE="${i%%/}" 
    CURRENT_PLAN_FOLDER=$CODEBUILD_SRC_DIR/deployment/$environment/$region/projects/$project/$NAMESPACE
    TF_PLANS_FOLDER="$CODEBUILD_SRC_DIR_infra_code_plan/tf-plans/$environment/$region/projects/$project/$NAMESPACE"
    PLAN_FILE_NAME="$environment-$project-$NAMESPACE.tfplan"
    PLAN_FILE_LOCATION="$TF_PLANS_FOLDER/$PLAN_FILE_NAME"


    echo
    echo
    echo "< ====================================================="
    echo "Applying plan in folder $CURRENT_PLAN_FOLDER"
    echo "===================================================== >"
    echo
    echo

    terragrunt apply --terragrunt-non-interactive --terragrunt-working-dir "$CURRENT_PLAN_FOLDER" --parallelism=2  "$PLAN_FILE_LOCATION"
done;


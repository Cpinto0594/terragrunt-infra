#!/bin/bash

echo Signing in 


ACCOUNT_ID=324711057459
ROLE_NAME=Developer
SESSION_NAME=Developer_Session
CURR_DATE=$(date +"%Y-%m-%d_%H-%M-%S" )
ADMIN_USER_SSO_PROFILE=AdminSSO
LOGGED_IN_SSO=false

 DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
 echo "Current directory: $DIR"


echo "====================== Backing up old credentials file   =========================="
mkdir -p "$HOME/.aws/"

if [ -f $HOME/.aws/config ]; then
    cp "$HOME/.aws/config" "$HOME/.aws/config_backup_$CURR_DATE"
else
    cp "$DIR/configs/aws/config.sample" "$HOME/.aws/config"
fi;


STS_AUTH_RESPONSE=$(aws sts assume-role --role-arn "arn:aws:iam::$ACCOUNT_ID:role/$ROLE_NAME" --role-session-name $SESSION_NAME --profile $ADMIN_USER_SSO_PROFILE)
SSO_AUTH_RESPONSE=$(aws sts get-caller-identity --profile $ADMIN_USER_SSO_PROFILE)


##Make sure to add the default profile to the config file if it doesn't exist, to avoid issues with the AWS cli when using the assume-role command. 
if ! grep -q "^\[default\]" "$HOME/.aws/config"; then
    printf "\n[default]\nsource_profile=$ROLE_NAME\nrole_arn=arn:aws:iam::$ACCOUNT_ID:role/$ROLE_NAME\n" >> "$HOME/.aws/config"
fi
if ! grep -q "^\[profile $ROLE_NAME\]$" "$HOME/.aws/config"; then
    printf "\n[profile $ROLE_NAME]\nregion = us-west-2\noutput = json\n" >> "$HOME/.aws/config"
fi


if ! grep -q "^\[profile $ADMIN_USER_SSO_PROFILE\]" "$HOME/.aws/config"; then
    echo "====================== AWS Sign In =========================="
    aws sso login --profile $ADMIN_USER_SSO_PROFILE
    LOGGED_IN_SSO=true
fi

if [ -z "$SSO_AUTH_RESPONSE" ]; then
    echo "Error: Failed to get caller identity. Signing in to AWS SSO..."
    aws sso login --profile $ADMIN_USER_SSO_PROFILE
    SSO_AUTH_RESPONSE=$(aws sts get-caller-identity --profile $ADMIN_USER_SSO_PROFILE)
    if [ -z "$SSO_AUTH_RESPONSE" ]; then
        echo "Error: Failed to get caller identity after AWS SSO login."
        exit 1
    fi
fi

if [ -z "$STS_AUTH_RESPONSE" ]; then
    echo "Error: Failed to assume role. Signing in to AWS assuming role..."
    STS_AUTH_RESPONSE=$(aws sts assume-role --role-arn "arn:aws:iam::$ACCOUNT_ID:role/$ROLE_NAME" --role-session-name $SESSION_NAME --profile $ADMIN_USER_SSO_PROFILE)
    if [ -z "$STS_AUTH_RESPONSE" ]; then
        echo "Error: Failed to assume role after AWS SSO login."
        exit 1
    fi
fi


cp "$DIR/configs/aws/credentials.sample" "$HOME/.aws/credentials"
#sed '/role_arn/s/^/#/' $HOME/.aws/config > ./tmp_file && mv ./tmp_file $HOME/.aws/config

echo "====================== Assume Role   =========================="

ACC_KEY=$(echo "$STS_AUTH_RESPONSE" | jq -r '.Credentials.AccessKeyId ')
SEC_ACC_KEY=$(echo "$STS_AUTH_RESPONSE" | jq -r '.Credentials.SecretAccessKey ')
SEC_ACC_TOKEN=$(echo "$STS_AUTH_RESPONSE" | jq -r '.Credentials.SessionToken ')

echo ""
echo "Done"
echo ""
echo "====================== Assume Role Details =========================="
echo "Access Key: $ACC_KEY"
echo "Secret Access Key: $SEC_ACC_KEY"
echo "Session Token: $SEC_ACC_TOKEN"
echo ""
echo "====================== Creating new credentials file   =========================="
printf "[$ROLE_NAME]\naws_access_key_id = $ACC_KEY\naws_secret_access_key = $SEC_ACC_KEY\naws_session_token = $SEC_ACC_TOKEN" > "$HOME/.aws/credentials"
cat "$HOME/.aws/credentials"
echo ""
echo "Done"
echo ""
echo "====================== Calling get caller-identity =========================="
aws sts get-caller-identity


DEV_ROLE_NAME=Developer
DEV_USER_NAME=Developer
DEV_USER_POLICY_NAME=DevAssumeRolePolicy
DEV_ROLE_POLICY_NAME=DEVPolicyPermissionsForDevRole
DEV_ROLE_POLICY_DOCUMENT="file://aws-initial-config/resources/DEVPolicyPermissionsForDevRole.json"
DEV_USER_POLICY_DOCUMENT="file://aws-initial-config/resources/DevAssumeRolePolicy.json"
ACCOUNT_ID=324711057459
TRUST_POLICY_TEMPLATE=aws-initial-config/resources/RoleDeveloper_TrustPolicy.json
TRUST_POLICY_RENDERED=$(mktemp)
AWS_PROFILE=AdminSSO

sed "s/{{Account}}/$ACCOUNT_ID/g" "$TRUST_POLICY_TEMPLATE" > "$TRUST_POLICY_RENDERED"


echo "Creating IAM role with trust policy... RoleDeveloper_TrustPolicy.json"
if ! aws iam get-role --role-name "$DEV_ROLE_NAME" --profile "$AWS_PROFILE" >/dev/null 2>&1; then
	if ! aws iam create-role --role-name "$DEV_ROLE_NAME" --assume-role-policy-document "file://$TRUST_POLICY_RENDERED" --profile "$AWS_PROFILE" >/dev/null 2>&1; then
		echo "IAM role already exists: $DEV_ROLE_NAME"
	fi
else
	echo "IAM role already exists: $DEV_ROLE_NAME"
fi
rm -f "$TRUST_POLICY_RENDERED"

echo "Attaching policy to IAM role... $DEV_ROLE_POLICY_NAME - $DEV_ROLE_POLICY_DOCUMENT"
if ! aws iam get-role-policy --role-name "$DEV_ROLE_NAME" --policy-name "$DEV_ROLE_POLICY_NAME" --profile "$AWS_PROFILE" >/dev/null 2>&1; then
	aws iam put-role-policy --role-name "$DEV_ROLE_NAME" --policy-name "$DEV_ROLE_POLICY_NAME" --policy-document $DEV_ROLE_POLICY_DOCUMENT --profile "$AWS_PROFILE"
else
	echo "Role policy already exists on role: $DEV_ROLE_POLICY_NAME"
fi

echo "Ensuring user policy exists... $DEV_USER_POLICY_NAME"
DEV_USER_POLICY_ARN=$(aws iam list-policies --profile "$AWS_PROFILE"  --scope Local --query "Policies[?PolicyName=='$DEV_USER_POLICY_NAME'].Arn | [0]" --output text)

if [ -z "$DEV_USER_POLICY_ARN" ] || [ "$DEV_USER_POLICY_ARN" = "None" ]; then
	DEV_USER_POLICY_ARN=$(aws iam create-policy --profile "$AWS_PROFILE" --policy-name "$DEV_USER_POLICY_NAME"  --policy-document $DEV_USER_POLICY_DOCUMENT --query 'Policy.Arn' --output text --profile "$AWS_PROFILE")
fi

echo "Ensuring IAM user exists... $DEV_USER_NAME"
if ! aws iam get-user --user-name "$DEV_USER_NAME" --profile "$AWS_PROFILE" >/dev/null 2>&1; then
	aws iam create-user --user-name "$DEV_USER_NAME" --profile "$AWS_PROFILE" >/dev/null
fi

echo "Attaching policy to IAM user... $DEV_USER_POLICY_NAME"
aws iam attach-user-policy --user-name "$DEV_USER_NAME" --policy-arn "$DEV_USER_POLICY_ARN" --profile "$AWS_PROFILE"




#aws configure sso
#CarlosPntoAdmn
#c4rP@
ACCOUNT_ID=324711057459
AWS_PROFILE=AdminSSO

DEV_ROLE_NAME=Developer
DEV_ROLE_POLICY_NAME=PermissionsForDevRole_Policy

DEV_USER_POLICY_NAME=DevAssumeRole_Policy
DEV_USER_NAME=Developer


DEV_ROLE_POLICY_DOCUMENT="file://aws-initial-config/resources/policies/PermissionsForDevRole_Policy.json"
COST_EXPLORER_POLICY_DOCUMENT="file://aws-initial-config/resources/policies/CostExplorer_Policy.json"
DEV_USER_POLICY_DOCUMENT="file://aws-initial-config/resources/policies/DevAssumeRole_Policy.json"
ACCOUNT_COLOR_POLICY_DOCUMENT="file://aws-initial-config/resources/policies/GetAccountColors_Policy.json"

ACCOUNT_MANAGEMENT_POLICY_DOCUMENT="aws-initial-config/resources/policies/AccountManagement_Policy.json"
ROLE_TRUST_POLICY_DOCUMENT="aws-initial-config/resources/policies/RoleDeveloperTrust_Policy.json"


TRUST_POLICY_TEMPLATE=$ROLE_TRUST_POLICY_DOCUMENT
TRUST_POLICY_RENDERED=$(mktemp)

ACCOUNT_MANAGEMENT_TEMPLATE=$ACCOUNT_MANAGEMENT_POLICY_DOCUMENT
ACCOUNT_MANAGEMENT_RENDERED=$(mktemp)


Billing_Policy_Arn="arn:aws:iam::aws:policy/AWSBillingReadOnlyAccess"


validate_role_policy_by_name() {
	local role_name="$1"
	local policy_name="$2"

	aws iam get-role-policy --role-name "$role_name" --policy-name "$policy_name" --profile "$AWS_PROFILE" >/dev/null 2>&1
}

validate_managed_policy_attached() {
	local role_name="$1"
	local policy_arn="$2"

	local attached_count
	attached_count=$(aws iam list-attached-role-policies --role-name "$role_name" --profile "$AWS_PROFILE" --query "AttachedPolicies[?PolicyArn=='$policy_arn'] | length(@)" --output text)
	[ "$attached_count" != "0" ]
}


sed "s/{{Account}}/$ACCOUNT_ID/g" "$TRUST_POLICY_TEMPLATE" > "$TRUST_POLICY_RENDERED"
sed "s/{{Account}}/$ACCOUNT_ID/g" "$ACCOUNT_MANAGEMENT_TEMPLATE" > "$ACCOUNT_MANAGEMENT_RENDERED"


echo "Creating IAM role with trust policy... $TRUST_POLICY_RENDERED"
if ! aws iam get-role --role-name "$DEV_ROLE_NAME" --profile "$AWS_PROFILE" >/dev/null 2>&1; then
	if ! aws iam create-role --role-name "$DEV_ROLE_NAME" --assume-role-policy-document "file://$TRUST_POLICY_RENDERED" --profile "$AWS_PROFILE" >/dev/null 2>&1; then
		echo "IAM role already exists: $DEV_ROLE_NAME"
	fi
else
	echo "IAM role already exists: $DEV_ROLE_NAME"
fi


echo "Attaching policy to IAM role... $DEV_ROLE_POLICY_NAME - $DEV_ROLE_POLICY_DOCUMENT"
if ! validate_role_policy_by_name "$DEV_ROLE_NAME" "$DEV_ROLE_POLICY_NAME"; then
	aws iam put-role-policy --role-name "$DEV_ROLE_NAME" --policy-name "$DEV_ROLE_POLICY_NAME" --policy-document "$DEV_ROLE_POLICY_DOCUMENT" --profile "$AWS_PROFILE"
else
	echo "Role policy already exists on role: $DEV_ROLE_POLICY_NAME"
fi

echo "Attaching policy to IAM role... CostExplorer - $COST_EXPLORER_POLICY_DOCUMENT"
if ! validate_role_policy_by_name "$DEV_ROLE_NAME" "CostExplorer"; then
	aws iam put-role-policy --role-name "$DEV_ROLE_NAME" --policy-name "CostExplorer" --policy-document "$COST_EXPLORER_POLICY_DOCUMENT" --profile "$AWS_PROFILE"
else
	echo "Role policy already exists on role: CostExplorer"
fi

echo "Attaching policy to IAM role... AccountManagement - $ACCOUNT_MANAGEMENT_RENDERED"
if ! validate_role_policy_by_name "$DEV_ROLE_NAME" "AccountManagement"; then
	aws iam put-role-policy --role-name "$DEV_ROLE_NAME" --policy-name "AccountManagement" --policy-document "file://$ACCOUNT_MANAGEMENT_RENDERED" --profile "$AWS_PROFILE"
else
	echo "Role policy already exists on role: AccountManagement"
fi

echo "Attaching policy to IAM role... AccountColor - $ACCOUNT_COLOR_POLICY_DOCUMENT"
if ! validate_role_policy_by_name "$DEV_ROLE_NAME" "AccountColor"; then
	aws iam put-role-policy --role-name "$DEV_ROLE_NAME" --policy-name "AccountColor" --policy-document "$ACCOUNT_COLOR_POLICY_DOCUMENT" --profile "$AWS_PROFILE"
else
	echo "Role policy already exists on role: AccountColor"
fi

echo "Attaching managed policy to IAM role... Billing - $Billing_Policy_Arn"
if ! validate_managed_policy_attached "$DEV_ROLE_NAME" "$Billing_Policy_Arn"; then
	aws iam attach-role-policy --role-name "$DEV_ROLE_NAME" --policy-arn "$Billing_Policy_Arn" --profile "$AWS_PROFILE"
else
	echo "Managed policy already attached on role: $Billing_Policy_Arn"
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

rm -f "$TRUST_POLICY_RENDERED"
rm -f "$ACCOUNT_MANAGEMENT_RENDERED"



#aws configure sso
#CarlosPntoAdmn
#c4rP@
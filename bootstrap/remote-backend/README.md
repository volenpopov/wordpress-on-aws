DRAFT

Terraform remote backend infrastructure

What you need before you start provisioning:
 - aws cli
 - aws-vault
 - root user MFA and access keys

How to provision it:
- add your root user's mfa serial number to the mfa_serial variable inside of terraform.tfvars
- comment out the backend "s3" part
- run terraform init
- run aws-vault exec --no-session YOUR_ROOT_USER_PROFILE terraform apply
    - enter the name of the s3 bucket that will be used for the terraform backend
    - enter the mfa code generated on your authentication device for your root user
- GO TO AWS CONSOLE AND DELETE YOUR ROOT USER's ACCESS KEYS
- uncomment the backend part in backend.tf file
- populate your backend.hcl file with the correct values for the variables
- run terraform init -backend-config=backend.hcl -migrate-state
- delete the empty terraform.tfstate file from your local directory

Cleanup:
- disable MFADelete on your bucket by using the below command:
Command for Disabling MFADelete on the bucket:
aws-vault exec --no-session root@wordpress -- aws s3api put-bucket-versioning --bucket BUCKET_NAME  --versioning-configuration Status=Enabled,MFADelete=Disabled --mfa "ROOT_USER_MFA_SERIAL MFA_CODE"

aws-vault exec --no-session root@wordpress -- aws s3api put-bucket-versioning --bucket BUCKET_NAME  --versioning-configuration Status=Enabled,MFADelete=Disabled --mfa "ROOT_USER_MFA_SERIAL MFA_CODE"

- comment out the lifecycle = { prevent_destroy = true } part in s3.tf
- migrate the remote backend state file to your local machine run terraform state pull > terraform.tfstate
- comment the backend "s3" part in your backend.tf file
- init terraform again with the updated backend.tf file by running aws-vault exec PROFILE -- terraform init -migrate-state
- delete all objects from the s3 bucket by running aws s3 rm s3://BUCKET_NAME --recursive
- go to the aws console and manually delete all versions from your s3 bucket
- run terraform destroy through aws-vault you can ommit typing the variables that you are asked for

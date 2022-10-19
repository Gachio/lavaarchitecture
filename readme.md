Run terraform init to tell Terraform to scan the codebase.
By default, the provider code will b downloaded into a .terraform folder

The terraform plan command lets us see what Terraform will do before actually making any changes.
The plan command is useful for quick sanity checks and during code reviews.

Run the terraform apply command to create the Instance.

The .gitignore file tells Git to ignore certain types of files

AWS does not allow any incoming or outgoing traffc from an EC2 Instance. Hence, I create a security group to allow this EC2 Instance to receive traffic on port 8080.
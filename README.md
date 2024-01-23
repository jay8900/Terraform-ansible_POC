# Terraform-ansible_POC
AWS Infrastructure Deployment with Terraform
This Terraform script sets up an AWS infrastructure for a simple web application, including a VPC, public subnets, an internet gateway, a load balancer, EC2 instances, and an autoscaling group. The infrastructure is designed to host a web application and provide Ansible automation capabilities.

Prerequisites
Before you begin, ensure you have the following:

Terraform installed on your local machine.
AWS credentials configured with the necessary permissions.(AWS profile created with proper permission)
must have pem key for your specific region
Terraform Configuration
VPC and Subnets

Creates a VPC with a specified CIDR block.
Defines two public subnets in different availability zones.
hcl
Copy code
resource "aws_vpc" "jay-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "jay-vpc"
  }
}

resource "aws_subnet" "jay-pro-pub-00" {
  # ...
}

resource "aws_subnet" "jay-pro-pub-01" {
  # ...
}
Internet Gateway and Route Table

Attaches an internet gateway to the VPC.
Defines a route table with a default route pointing to the internet gateway.
hcl
Copy code
resource "aws_internet_gateway" "jay-ig" {
  # ...
}

resource "aws_route_table" "jay-rt-pub-main" {
  # ...
}
Load Balancer

Creates an application load balancer with a target group and listener.
hcl
Copy code
resource "aws_lb" "jay_lb" {
  # ...
}

resource "aws_lb_target_group" "jay_alb_tg" {
  # ...
}

resource "aws_lb_listener" "jay_front_end" {
  # ...
}
EC2 Instances and Autoscaling Group

Launches an EC2 instance for Ansible automation and an autoscaling group for the web application.
hcl
Copy code
resource "aws_instance" "ansible-engine" {
  # ...
}

resource "aws_launch_configuration" "autoscaling" {
  # ...
}

resource "aws_autoscaling_group" "autoscaling" {
  # ...
}
IAM Roles and Policies

Sets up IAM roles and policies for EC2 instances.
hcl
Copy code
resource "aws_iam_instance_profile" "jay_iampr" {
  # ...
}

resource "aws_iam_role" "jay_iamr" {
  # ...
}

resource "aws_iam_policy" "jay_iamp" {
  # ...
}

resource "aws_iam_role_policy_attachment" "jay_iampa" {
  # ...
}
Deployment
Clone the repository:

bash
Copy code
git clone <repository_url>
cd <repository_directory>
Initialize Terraform:

bash
Copy code
terraform init
Review and adjust the variables in terraform.tfvars if needed.

Deploy the infrastructure:

bash
Copy code
terraform apply
Confirm by typing "yes" when prompted.

Cleanup
To remove the infrastructure:

bash
Copy code
terraform destroy
Confirm by typing "yes" when prompted.

Notes
Ensure your AWS credentials are configured correctly by making profile (AWS CLI) before running Terraform.
must have pem key and replace with your pem key.
Review the variables.tf file for customizable variables.
Customize Ansible configurations in the user-data-ansible-engine.sh script.
Adjust security settings and policies based on your application requirements.
For more information on Terraform commands and options, refer to the Terraform Documentation.







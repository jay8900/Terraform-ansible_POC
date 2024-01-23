resource "aws_vpc" "jay-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "jay-vpc"
  }
}
# Subnet
resource "aws_subnet" "jay-pro-pub-00" {
  vpc_id                  = aws_vpc.jay-vpc.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-southeast-1b"
  tags = {
    Name = "jay-pro-pub-00"
  }
}
resource "aws_subnet" "jay-pro-pub-01" {
  vpc_id                  = aws_vpc.jay-vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-southeast-1a"
  tags = {
    Name = "jay-pro-pub-00"
  }
}
# Internet Gateway
resource "aws_internet_gateway" "jay-ig" {
  vpc_id = aws_vpc.jay-vpc.id
  tags = {
    Name = "jay-ig"
  }
}
# Routing table for public subnet (access to Internet)
resource "aws_route_table" "jay-rt-pub-main" {
  vpc_id = aws_vpc.jay-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.jay-ig.id
  }
  tags = {
    Name = "jay-rt-pub-main"
  }
}
# Set new main_route_table as main
resource "aws_main_route_table_association" "jay-rta-default" {
  vpc_id         = aws_vpc.jay-vpc.id
  route_table_id = aws_route_table.jay-rt-pub-main.id
}
## creating the load balancer
resource "aws_lb" "jay_lb" {
  name               = "jay-lb-asg"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ansible_access.id]
  subnets            = [aws_subnet.jay-pro-pub-00.id, aws_subnet.jay-pro-pub-01.id]
  depends_on         = [aws_internet_gateway.jay-ig]
}

resource "aws_lb_target_group" "jay_alb_tg" {
  name     = "jay-tf-lb-alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.jay-vpc.id
}

resource "aws_lb_listener" "jay_front_end" {
  load_balancer_arn = aws_lb.jay_lb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.jay_alb_tg.arn
  }
}
## "creating ansible-node"
resource "aws_instance" "ansible-engine" {
  ami                    = var.aws_ami_id
  instance_type          = "t2.micro"
  iam_instance_profile   = aws_iam_instance_profile.jay_iampr.name
  key_name               = "tf"
  subnet_id              = aws_subnet.jay-pro-pub-00.id
  vpc_security_group_ids = [aws_security_group.ansible_access.id]
  user_data              = file("user-data-ansible-engine.sh")

  # Create inventory and ansible.cfg on ansible-engine
  provisioner "remote-exec" {
    inline = [
      "echo '[ansible]' >> /home/ec2-user/inventory",
      "echo 'ansible-engine ansible_host=${aws_instance.ansible-engine.private_dns} ansible_connection=local' >> /home/ec2-user/inventory",
      "echo '[nodes]' >> /home/ec2-user/inventory",
      "echo '' >> /home/ec2-user/inventory",
      "echo '[all:vars]' >> /home/ec2-user/inventory",
      "echo 'ansible_user=devops' >> /home/ec2-user/inventory",
      "echo 'ansible_password=devops' >> /home/ec2-user/inventory",
      "echo 'ansible_connection=ssh' >> /home/ec2-user/inventory",
      "echo '#ansible_python_interpreter=/usr/bin/python3' >> /home/ec2-user/inventory",
      "echo 'ansible_ssh_private_key_file=/home/devops/.ssh/id_rsa' >> /home/ec2-user/inventory",
      "echo \"ansible_ssh_extra_args=' -o StrictHostKeyChecking=no -o PreferredAuthentications=password '\" >> /home/ec2-user/inventory",
      "echo '[defaults]' >> /home/ec2-user/ansible.cfg",
      "echo 'inventory = ./inventory' >> /home/ec2-user/ansible.cfg",
      "echo 'host_key_checking = False' >> /home/ec2-user/ansible.cfg",
      "echo 'remote_user = devops' >> /home/ec2-user/ansible.cfg",
    ]
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("tf.pem")
      host        = self.public_ip
      agent       = false
    }
  }
  # copy lw.conf
  provisioner "file" {
    source      = "lw.conf"
    destination = "/home/ec2-user/lw.conf"
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("tf.pem")
      host        = self.public_ip
    }
  }
  # copy index.html
  provisioner "file" {
    source      = "index.html"
    destination = "/home/ec2-user/index.html"
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("tf.pem")
      host        = self.public_ip
    }
  }

  # copy engine-config.yaml
  provisioner "file" {
    source      = "engine-config.yaml"
    destination = "/home/ec2-user/engine-config.yaml"
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("tf.pem")
      host        = self.public_ip
    }
  }

  # Execute Ansible Playbook
  provisioner "remote-exec" {
    inline = [
      "sleep 120; ansible-playbook engine-config.yaml"
    ]
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("tf.pem")
      host        = self.public_ip
    }
  }

  tags = {
    Name = "ansible-engine"
  }
  depends_on = [
    aws_vpc.jay-vpc
  ]
}
resource "aws_launch_configuration" "autoscaling" {
  name_prefix     = "autoscalling"
  image_id        = var.aws_ami_id
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.ansible_access.id]

}

resource "aws_autoscaling_group" "autoscaling" {
  name_prefix          = "autoscaling"
  launch_configuration = aws_launch_configuration.autoscaling.id
  max_size             = 5
  min_size             = 2
  vpc_zone_identifier  = [aws_subnet.jay-pro-pub-00.id, aws_subnet.jay-pro-pub-01.id]
}
resource "aws_iam_instance_profile" "jay_iampr" {
  name = "jay_iampr-instance-profile"

  role = aws_iam_role.jay_iamr.name
}

resource "aws_iam_role" "jay_iamr" {
  name = "jay-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy
resource "aws_iam_policy" "jay_iamp" {
  name        = "jay_iam-policy"
  description = "jay IAM policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = "ec2:RebootInstances",
        Effect   = "Allow",
        Resource = aws_instance.ansible-engine.arn
      }
    ]
  })
}

# Attach IAM Policy to IAM Role
resource "aws_iam_role_policy_attachment" "jay_iampa" {
  policy_arn = aws_iam_policy.jay_iamp.arn
  role       = aws_iam_role.jay_iamr.name
}

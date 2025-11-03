# packer.pkr.hcl
# Backend AMI: PHP + Apache + MySQL client

# -----------------------
# Variables
# -----------------------
variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region to build the AMI in."
}

variable "source_ami" {
  type        = string
  default     = ""
  description = "Base AMI to use as the source image (set via -var or a var-file)."
}

variable "instance_type" {
  type        = string
  # default     = "t4g.micro"
  # https://aws.amazon.com/ec2/instance-types/t4/
  default     = "t4g.small"
  description = "EC2 instance type to use for the temporary build instance."
}

variable "ssh_username" {
  type        = string
  default     = "ec2-user"
  description = "SSH user for the temporary build instance."
}

variable "vpc_id" {
  type        = string
  default     = ""
  description = "VPC id where the build instance will be launched."
}

variable "subnet_id" {
  type        = string
  default     = ""
  description = "Subnet id where the build instance will be launched."
}

variable "security_group_id" {
  type        = string
  default     = ""
  description = "Security group id attached to the build instance (single SG)."
}

variable "rds_sg_id" {
  type        = string
  default     = ""
  description = "(Unused in template) RDS security group id — kept for consistency if you want to reference it elsewhere."
}

variable "db_host" {
  type        = string
  default     = ""
  description = "Database host endpoint used by mysql client to run the schema/import step."
}

variable "db_port" {
  type        = string
  default     = "3306"
  description = "Database port (string to match original)."
}
variable "db_name" {
  type        = string
  default     = ""
  description = "Database Name"
}

variable "db_user" {
  type        = string
  default     = ""
  description = "DB user that has privileges to run the SQL in database_setup.sql."
}

variable "db_password" {
  type        = string
  default     = ""
  description = "DB password. Avoid committing secrets to source; use -var or a var-file."
  sensitive   = true
}
variable "s3_ssm_cw_instance_profile_name" {
  type        = string
  default     = ""
  description = "Instance profile for packer for ssm s3 and cw"
}
# variable "db_secret_name" {
#   type        = string
#   default     = ""
#   description = "secret to access from aws secret manager"
# }
variable "bucket_name" {
  type        = string
  default     = ""
  description = "s3  bucket name"
}
variable "server_key_name" {
  type        = string
  default     = ""
  description = "server key pair name"
}

variable "key_file_path" {
  type        = string
  default     = "../../modules/key/server_key"
  description = " key file path"
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

# i am already searching for latest amazon ami in build_ami.sh
# data "amazon-ami" "example" {
#   filters = {
#     virtualization-type = "hvm"
#     name                = "al2023-ami-2023.*-arm64"
#     root-device-type    = "ebs"
#   }
#   owners      = ["amazon"]
#   most_recent = true
#   region      = "us-east-1"
# }
# -----------------------
# Source (amazon-ebs builder)
# -----------------------
source "amazon-ebs" "backend" {
  region                      = var.aws_region
  source_ami                  = var.source_ami
  # source_ami                  = data.amazon-ami.example.id
  instance_type               = var.instance_type
  vpc_id                      = var.vpc_id
  subnet_id                   = var.subnet_id
  security_group_id           = var.security_group_id
  associate_public_ip_address = true
  ssh_username                = var.ssh_username
  temporary_key_pair_name     = "packer-${local.timestamp}"
  ssh_interface               = "public_ip"
  ssh_timeout                 = "6m"
  ssh_handshake_attempts      = 30
  communicator                = "ssh"
  ssh_pty                     = true
  # ssh_interface    = "session_manager"
  ssh_keypair_name     = var.server_key_name
  ssh_private_key_file = var.key_file_path

  iam_instance_profile        = var.s3_ssm_cw_instance_profile_name


  ami_name        = "three-tier-backend-${local.timestamp}"
  ami_description = "Backend AMI with NodeJS, MySQL client, and CloudWatch agent"

  tags = {
    Component   = "backend"
    Environment = "dev"
    Name        = "three-tier-backend"
  }

  launch_block_device_mappings {
      device_name = "/dev/xvda"
      encrypted = true
      volume_type = "standard"
      volume_size = 8
      delete_on_termination = true
  }
}

# -----------------------
# Build (connects source -> provisioners -> post-processors)
# -----------------------
build {
  sources = ["source.amazon-ebs.backend"]

  # provisioner "shell" {
  #   inline = [
  #     "sudo dnf upgrade -y",
  #     "sudo dnf install -y httpd wget php-fpm php-mysqli php-json php php-devel -y",
  #     "sudo dnf install mariadb105 -y",
  #     "sudo usermod -a -G apache ec2-user",
  #     "sudo chown -R ec2-user:apache /var/www",
  #     "sudo chmod 2775 /var/www && find /var/www -type d -exec sudo chmod 2775 {} \\;",
  #     "find /var/www -type f -exec sudo chmod 0664 {} \\;",
  #     "sudo systemctl enable httpd",
  #     "sudo dnf install git -y"
  #   ]
  # }
#   provisioner "shell" {
#   inline = [
#     "echo 'Starting app-tier setup...'",
#     "sudo bash -c 'cat <<EOF > /tmp/server.sh\n${file("server.sh")}\nEOF'",
#     "sudo chmod +x /tmp/app-setup.sh",
#     "sudo bash /tmp/app-setup.sh"
#   ]
# }

  provisioner "file" {
    source      = "server.sh"           # local file (in same dir as packer/terraform)
    destination = "/tmp/server.sh"      # remote path inside EC2
  }

  provisioner "shell" {
    environment_vars = [
      "db_host=${var.db_host}",
      "db_username=${var.db_user}",
      "db_password=${var.db_password}",
      "db_name=${var.db_name}",
      "bucket_name=${var.bucket_name}",
      "aws_region=${var.aws_region}"
  ]

    inline = [
      "echo 'Running lirw-app setup...'",
      "echo $db_name ",
      "echo Bucket: $bucket_name",
      "sudo chmod +x /tmp/server.sh",
      "sudo -E bash -x /tmp/server.sh "    
    ]
  }


  # provisioner "file" {
  #   source      = "appdb.sql"
  #   destination = "/tmp/appdb.sql"
  # }

  # provisioner "shell" {
  #   inline = [
  #     "# Run the database setup script to create schema and initial data",
  #     "mysql -h \"${var.db_host}\" -P ${var.db_port} -u \"${var.db_user}\" -p\"${var.db_password}\" < /tmp/appdb.sql"
  #   ]
  # }

  post-processor "manifest" {
    output = "manifest.json"
  }
}

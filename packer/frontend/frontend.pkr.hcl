
# -------- Variables --------
variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region where the AMI will be built."
}

variable "source_ami" {
  type        = string
  default     = ""
  description = "Base AMI id to use as the source image (set via -var or environment)."
}

variable "instance_type" {
  type    = string
  # default = "t4g.micro"
  default = "t4g.small"
}

variable "ssh_username" {
  type    = string
  default = "ec2-user"
}

variable "vpc_id" {
  type    = string
  default = ""
}

variable "subnet_id" {
  type    = string
  default = ""
}
variable "s3_ssm_cw_instance_profile_name" {
  type        = string
  default     = ""
  description = "Instance profile for packer for ssm s3 and cw"
}
variable "bucket_name" {
  type        = string
  default     = ""
  description = "s3  bucket name"
}
variable "internal_alb_dns_name" {
  type        = string
  default     = ""
  description = "alb dns to alter "
}
variable "client_key_name" {
  type        = string
  default     = ""
  description = "client key pair name"
}
variable "key_file_path" {
  type        = string
  # default     = "../../terraform/permissions/modules/key/client_key"
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
# -------- Source (amazon-ebs builder) --------
source "amazon-ebs" "frontend" {
  region                        = var.aws_region
  source_ami                    = var.source_ami
  # source_ami                  = data.amazon-ami.example.id
  instance_type                 = var.instance_type
  vpc_id                        = var.vpc_id
  subnet_id                     = var.subnet_id
  associate_public_ip_address   = true
  temporary_key_pair_name       = "packer-${local.timestamp}"
  ssh_username                  = var.ssh_username
  ssh_timeout                   = "6m"
  ssh_handshake_attempts        = 30
  communicator                  = "ssh"
  ssh_pty                       = true
  # ssh_interface                 = "public_ip"
  ssh_interface    = "session_manager"
  ssh_keypair_name     = var.client_key_name
  ssh_private_key_file = var.key_file_path

  iam_instance_profile        = var.s3_ssm_cw_instance_profile_name


  ami_name                      = "three-tier-frontend-${local.timestamp}"
  ami_description               = "Frontend AMI with Nginx and Git and react"
  tags = {
    Name        = "three-tier-frontend"
    Environment = "dev"
    Component   = "frontend"
  }
  
  launch_block_device_mappings {
      device_name = "/dev/xvda"
      encrypted = true
      volume_type = "standard"
      volume_size = 8
      delete_on_termination = true
  }


}

# -------- Build (ties source -> provisioners -> post-processors) --------
build {
  sources = ["source.amazon-ebs.frontend"]


  
  # provisioner "file" {
  #   source      = "client.sh"           # local file (in same dir as packer/terraform)
  #   destination = "/tmp/client.sh"      # remote path inside EC2
  # }

  # provisioner "shell" {
  #   environment_vars = [
  #     "bucket_name=${var.bucket_name}",
  #     "internal_alb_dns_name=${var.internal_alb_dns_name}"
  # ]

  #   inline = [
  #     "echo $internal_alb_dns_name  $bucket_name  ",
  #     "echo 'Running app-tier setup...'",
  #     "sudo chmod +x /tmp/client.sh",
  #     "sudo -E bash /tmp/client.sh "
  #   ]
  # }

  # Step 1: Install Ansible
  provisioner "shell" {
    inline = [
      "echo 'Installing Ansible on EC2 builder instance...'",
      "sudo yum update -y",
      "sudo yum install -y ansible ",
      # "sudo yum install -y python3-pip",
      # "sudo pip3 install ansible --break-system-packages || sudo yum install -y ansible",
      "ansible --version"
    ]
  }
  

    provisioner "file" {
    source      = "client-ansible.yml"           # local file (in same dir as packer/terraform)
    destination = "/tmp/client-ansible.yml"      # remote path inside EC2
  }
   # Run Ansible playbook instead of shell script
  provisioner "ansible" {
    playbook_file = "./client-ansible.yml"
    user             = "ec2-user"
    timeout       = "5m"
    # variables passed into Ansible
    extra_arguments = [
      "-vvvv",
      "--extra-vars", 
      "ansible_python_interpreter=/usr/bin/python3 bucket_name=${var.bucket_name} internal_alb_dns_name=${var.internal_alb_dns_name}"
    ]

    # Optional verbosity (remove if you prefer)
    ansible_env_vars = ["ANSIBLE_FORCE_COLOR=true"]
  }
  post-processor "manifest" {
    output = "manifest.json"
  }
}

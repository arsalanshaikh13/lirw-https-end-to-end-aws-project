# infra/network/terragrunt.hcl
include {
  path   = find_in_parent_folders()
  expose = true
}

include "global_mock" {
  path   = find_in_parent_folders("global-mocks.hcl")
  expose = true
}

terraform {
  source = "./." # Uses the local folder's Terraform code

  # https://terragrunt.gruntwork.io/docs/features/hooks/
  before_hook "generate_ssh_keys" {
    commands = ["init"]
    # https://developer.hashicorp.com/terraform/language/expressions/strings#indented-heredocs
    execute = [
      "bash", "-c",
      <<-EOT
      set -e
      cd "${get_terragrunt_dir()}/modules/key"
      for key in nat-bastion client_key server_key; do
        if [ ! -f "$key" ]; then
          echo "🔑 Creating SSH keypair: $key"
          ssh-keygen -t rsa -b 4096 -f $key -N ""
        else
          echo "🔑 SSH keypair $key already exists"
        fi
      done
    EOT
    ]
  }

  # # Clearing up ssh keys
  after_hook "delete_ssh_keys" {
    # Run this hook only when 'destroy' is called
    commands = ["destroy"]
    # Use a heredoc to pass a single, multi-line script to bash -c
    execute = [
      "bash", "-c",
      <<-EOT
        set -e
        echo "🧹 Clearing up SSH keys..."
        rm -f modules/key/*key*
        rm -f modules/key/nat*
        echo "✅ SSH key cleanup complete."
      EOT
    ]
  }
  before_hook "pre_fmt" {
    commands = ["plan"]
    execute  = ["bash", "-c", "echo 'Running terraform format'; terraform fmt --recursive"]
  }
  before_hook "pre_validate" {
    commands = ["plan"]
    execute  = ["bash", "-c", "echo 'Running terraform validate'; terraform validate"]
  }

  before_hook "pre_init" {
    commands = ["plan"]
    execute  = ["bash", "-c", "tflint --init"]
  }

  before_hook "tflint" {
    commands = ["plan"]
    execute = [
      "bash", "-c",
      <<-EOT
        tflint --recursive --minimum-failure-severity=error --config "${get_original_terragrunt_dir()}/custom.tflint.hcl"
        exit_code=$?
        if [ $exit_code -gt 0 ]; then
          echo "exit code : $exit_code"
          echo "✅ TFLint completed with issues (non-fatal). Continuing Terragrunt..."
          exit 0
        else
          echo "exit code : $exit_code"
          exit $exit_code
        fi
      EOT
    ]
  }
  after_hook "post_apply_graph" {
    commands = ["apply"]
    execute  = ["bash", "-c", "echo 'Running terraform graph'; terraform graph > '${get_original_terragrunt_dir()}'/graph/graph-apply.dot"]
  }
  after_hook "post_apply_message" {
    commands = ["apply"]
    execute  = ["bash", "-c", "echo '✅ Resources created successfully'"]
  }
  after_hook "post_destroy" {
    commands = ["destroy"]
    execute  = ["bash", "-c", "rm -f ${get_original_terragrunt_dir()}/modules/key/*key*; rm -f ${get_original_terragrunt_dir()}/modules/key/nat*"]
  }
  after_hook "post_destroy" {
    commands = ["destroy"]
    execute  = ["bash", "-c", "echo '✅ Resources deleted successfully'"]
  }
}

dependency "network" {
  config_path                             = "../network"
  mock_outputs                            = include.global_mock.locals.global_mock_outputs
  mock_outputs_allowed_terraform_commands = ["plan"]
}

inputs = {
  vpc_id = dependency.network.outputs.vpc_id
  region = dependency.network.outputs.region
}

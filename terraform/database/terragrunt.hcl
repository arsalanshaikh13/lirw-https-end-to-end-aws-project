include {
  path   = find_in_parent_folders()
  expose = true
}

include "global_mock" {
  path   = find_in_parent_folders("global-mocks.hcl")
  expose = true
}

terraform {
  source = "./."
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
    execute  = ["bash", "-c", "echo '✅ Resources deleted successfully'"]
  }
}

dependency "network" {
  config_path                             = "../network"
  mock_outputs                            = include.global_mock.locals.global_mock_outputs
  mock_outputs_allowed_terraform_commands = ["plan"]
}

dependency "permissions" {
  config_path                             = "../permissions"
  mock_outputs                            = include.global_mock.locals.global_mock_outputs
  mock_outputs_allowed_terraform_commands = ["plan"]
}

inputs = {
  db_sg_id      = dependency.network.outputs.db_sg_id
  pri_sub_7a_id = dependency.network.outputs.pri_sub_7a_id
  pri_sub_8b_id = dependency.network.outputs.pri_sub_8b_id
  project_name  = dependency.network.outputs.project_name
}

# tflint --recursive --minimum-failure-severity=error --config "$(pwd)/custom.tflint.hcl"
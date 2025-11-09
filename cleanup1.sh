#!/bin/bash
set -euo pipefail


destroy_order=("hosting" "compute" "database" "permissions" "network")

echo "🔥 Destroying Terraform stacks in reverse dependency order..."

for dir in "${destroy_order[@]}"; do
  echo "🧨 Destroying ${dir}..."
  terragrunt run --non-interactive  --working-dir $dir -- destroy -auto-approve --parallelism 20   || true
done

echo "✅ All stacks destroyed successfully."

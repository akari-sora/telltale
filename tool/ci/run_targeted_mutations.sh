#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

echo "=== Running AA-08 Targeted Mutation Testing ==="
python3 "${SCRIPT_DIR}/run_targeted_mutations.py" "$@"

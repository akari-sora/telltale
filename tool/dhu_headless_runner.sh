#!/usr/bin/env bash
# Headless Google Desktop Head Unit (DHU) 2.0 Automation Runner Entrypoint
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_BIN="${PYTHON_BIN:-python3}"

if ! command -v "$PYTHON_BIN" &>/dev/null; then
  echo "Error: Python 3 ($PYTHON_BIN) not found in PATH." >&2
  exit 1
fi

exec "$PYTHON_BIN" "${SCRIPT_DIR}/dhu_headless_runner.py" "$@"

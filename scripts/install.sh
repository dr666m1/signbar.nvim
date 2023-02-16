#!/bin/bash
set -euo pipefail

if ! command -v stylua; then
  cargo install stylua --features lua52
fi

#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
set -euo pipefail

exec mono "${SCRIPT_DIR}/protoc-gen-turbolink.exe" "$@"

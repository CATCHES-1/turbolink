#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
set -euo pipefail


# make sure input proto files exist
INPUT_PROTO_FILE=${1:?Please provide input proto file as first argument}
if [ ! -f "${INPUT_PROTO_FILE}" ]; then
    echo "Input proto file '${INPUT_PROTO_FILE}' not exist!"
    exit 1
fi

INPUT_PROTO_PATH=$(dirname "${INPUT_PROTO_FILE}")

# make sure output path exist
OUTPUT_PATH=${2:?Please provide output path as second argument}
if [ ! -d "${OUTPUT_PATH}" ]; then
    echo "Output path '${OUTPUT_PATH}' not exist!"
    exit 1
fi

# get turbolink plugin path
TL_UE_PLUGIN_PATH="${SCRIPT_DIR}/.."

TURBOLINK_PLUGIN_PATH=${TL_UE_PLUGIN_PATH}/Tools/protoc-gen-turbolink.sh
PROTOBUF_INC_PATH=${TL_UE_PLUGIN_PATH}/Source/ThirdParty/protobuf/include
FIX_PROTO_CPP=${TL_UE_PLUGIN_PATH}/Tools/fix_proto_cpp.txt
FIX_PROTO_H=${TL_UE_PLUGIN_PATH}/Tools/fix_proto_h.txt
CPP_OUTPUT_PATH=${OUTPUT_PATH}/Private/pb

if ! command -v protoc &> /dev/null; then
    echo "protoc not found! Try 'brew install protobuf'"
    exit 1
fi
if ! command -v grpc_cpp_plugin &> /dev/null; then
    echo "grpc_cpp_plugin not found! Try 'brew install grpc'"
    exit 1
fi
PROTOC_EXE_PATH=$(which protoc)
GRPC_CPP_PLUGIN_EXE_PATH=$(which grpc_cpp_plugin)

if [ ! -d "${CPP_OUTPUT_PATH}" ]; then
    mkdir -p "${CPP_OUTPUT_PATH}"
fi

# Print Variables for debugging
echo "Input proto file: ${INPUT_PROTO_FILE}"
echo "Output path: ${OUTPUT_PATH}"

echo "TURBOLINK_PLUGIN_PATH=${TURBOLINK_PLUGIN_PATH}"
echo "PROTOC_EXE_PATH=${PROTOC_EXE_PATH}"
echo "PROTOBUF_INC_PATH=${PROTOBUF_INC_PATH}"
echo "GRPC_CPP_PLUGIN_EXE_PATH=${GRPC_CPP_PLUGIN_EXE_PATH}"
echo "FIX_PROTO_CPP=${FIX_PROTO_CPP}"
echo "FIX_PROTO_H=${FIX_PROTO_H}"
echo "CPP_OUTPUT_PATH=${CPP_OUTPUT_PATH}"

echo "Checking existence of files or directories..."

variables=("TURBOLINK_PLUGIN_PATH" "PROTOBUF_INC_PATH" "FIX_PROTO_CPP" "FIX_PROTO_H" "CPP_OUTPUT_PATH")

errorFlag=0
for var in "${variables[@]}"; do
    if [ ! -e "${!var}" ]; then
        echo "not found: ${!var}"
        errorFlag=1
    fi
done

if [ "${errorFlag}" -eq 1 ]; then
    echo "Error: At least one required file or directory not found."
    exit 1
fi

echo "Generating code..."
args=(
    "${PROTOC_EXE_PATH}"
    --proto_path="${PROTOBUF_INC_PATH}"
    --proto_path="${INPUT_PROTO_PATH}"
    --cpp_out="${CPP_OUTPUT_PATH}"
    --plugin=protoc-gen-grpc="${GRPC_CPP_PLUGIN_EXE_PATH}" --grpc_out="${CPP_OUTPUT_PATH}"
    --plugin=protoc-gen-turbolink="${TURBOLINK_PLUGIN_PATH}" --turbolink_out="${OUTPUT_PATH}"
    --turbolink_opt="GenerateJsonCode=true"
)

# Check if there's a vendored google dir
cur_dir=${INPUT_PROTO_PATH}
upper_dir=$(dirname "${cur_dir}")
while [[ "${cur_dir}" != "${upper_dir}" ]]; do
    if [[ -d "${cur_dir}/google" ]]; then
        args+=(--proto_path="${cur_dir}")
        break
    fi
    cur_dir=${upper_dir}
    upper_dir=$(dirname "${cur_dir}")
done

set -x
"${args[@]}" "${INPUT_PROTO_FILE}"

FixCompileWarning() {
    FIX_FILE=$1
    FILE_PATH=$(dirname "$2")
    FILE_NAME=$(basename "${2%%.proto}").$3

    pushd "${FILE_PATH}"
    cat "${FIX_FILE}" "${FILE_NAME}" > "${FILE_NAME}.tmp"
    rm -f "${FILE_NAME}"
    mv "${FILE_NAME}.tmp" "${FILE_NAME}"
    popd
}
echo "Fixing protobuf compile warning..."
FixCompileWarning "${FIX_PROTO_H}" "${CPP_OUTPUT_PATH}/$(basename "${INPUT_PROTO_FILE}")" "pb.h"
FixCompileWarning "${FIX_PROTO_CPP}" "${CPP_OUTPUT_PATH}/$(basename "${INPUT_PROTO_FILE}")" "pb.cc"

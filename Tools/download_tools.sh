#!/bin/bash
set -euo pipefail
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

package=github.com/cfstras/go-protoc-gen-builtins/cmd
tool=protoc-gen-cpp
version=v1.26.1-0.20240326163943-f149adda5bcc

native=$(go env GOOS)_$(go env GOARCH)

install() {
    tool=$1
    GOOS=$2
    GOARCH=$3
    GOPATH=${SCRIPT_DIR}/.gopath
    BIN=${SCRIPT_DIR}/${GOOS}/${GOARCH}
    export GOARCH GOOS GOPATH
    mkdir -p "${BIN}"
    echo "Compiling ${tool} for ${GOOS}/${GOARCH}..."
    go install "${package}/${tool}@${version}"

    _out="${GOPATH}/bin/${tool}"
    _target_out="${BIN}/${tool}"
    if [[ "${GOOS}_${GOARCH}" != "${native}" ]]; then
        _out="${GOPATH}/bin/${GOOS}_${GOARCH}/${tool}"
    fi
    if [[ "${GOOS}" == "windows" ]]; then
        _out="${_out}.exe"
        _target_out="${_target_out}.exe"
    fi
    mv "${_out}" "${_target_out}"
}

install "${tool}" darwin arm64
install "${tool}" darwin amd64
install "${tool}" linux amd64
install "${tool}" linux arm64
install "${tool}" windows amd64

#!/usr/bin/env bash
set -euo pipefail
work=$(mktemp -d)
cd "$work"
go mod init warm >/dev/null 2>&1
go get github.com/fipe-api/go-sdk@v0.1.0 >/dev/null 2>&1
cd /
rm -rf "$work"

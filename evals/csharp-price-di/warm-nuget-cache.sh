#!/usr/bin/env bash
set -euo pipefail
export DOTNET_CLI_TELEMETRY_OPTOUT=1 DOTNET_NOLOGO=1
work=$(mktemp -d)
cd "$work"
dotnet new classlib -o lib >/dev/null
dotnet new xunit -o tests >/dev/null
dotnet add lib package Fipe.Api.Br --version 0.1.0 >/dev/null
dotnet add lib package Microsoft.Extensions.Http --version 8.0.1 >/dev/null
dotnet add lib package Microsoft.Extensions.Configuration.Abstractions --version 8.0.0 >/dev/null
dotnet add lib package Microsoft.Extensions.Configuration.Binder --version 8.0.2 >/dev/null
dotnet add tests package Microsoft.Extensions.Configuration --version 8.0.0 >/dev/null
dotnet add tests package Microsoft.Extensions.DependencyInjection --version 8.0.1 >/dev/null
dotnet restore lib >/dev/null
dotnet restore tests >/dev/null
cd /
rm -rf "$work"

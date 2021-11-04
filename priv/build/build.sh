#!/bin/bash
# Build a project for production in the form of a release

set -euo pipefail

MIX_ENV=${MIX_ENV-prod}

export MIX_ENV=$MIX_ENV

# Clean project and get dependencies
mix do local.rebar --force, \
       local.hex --force, \
       clean --only $MIX_ENV, \
       deps.get --only $MIX_ENV

# Build static assets and run project compilation
mix do assets.deploy, \
       compile --force, \
       release --overwrite

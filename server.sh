#!/bin/sh

PORT=4000 MIX_ENV=prod EFOSSILS_FOSSIL_BASE_URL="http://localhost:$PORT" EFOSSILS_FEDERATED_NAME="Efossils" EFOSSILS_FOSSIL_BIN="$HOME/bin/fossil" EFOSSILS_REPOSITORY_PATH="$PWD/efossils/priv/data/repositories" EFOSSILS_WORK_PATH="$PWD/efossils/priv/data/works" mix do compile, phx.server

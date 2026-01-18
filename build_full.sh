
# Remove the existing release directory and build the release
sudo rm -rf "_build"

#!/usr/bin/env bash
# Initial setup
mix deps.get --only prod
MIX_ENV=prod mix compile

# Release
MIX_ENV=prod mix release --overwrite

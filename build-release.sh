#!/bin/env sh

# Set environment to production
export MIX_ENV=prod

# Get dependencies
mix deps.get --only prod

# Compile the application
mix compile

# Build static assets (JavaScript, CSS)
mix assets.deploy

# Create the release
mix release

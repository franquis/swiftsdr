#!/bin/bash

# Add Homebrew to PATH
export PATH="/opt/homebrew/bin:$PATH"

# Set environment variables for Homebrew paths
export HOMEBREW_PREFIX=$(brew --prefix)
export HOMEBREW_INCLUDE_PATH="$HOMEBREW_PREFIX/include"
export HOMEBREW_LIB_PATH="$HOMEBREW_PREFIX/lib"
export PKG_CONFIG_PATH="$HOMEBREW_PREFIX/lib/pkgconfig"

# Set C_INCLUDE_PATH to include SoapySDR headers
export C_INCLUDE_PATH="$HOMEBREW_INCLUDE_PATH:$C_INCLUDE_PATH"
export CPLUS_INCLUDE_PATH="$HOMEBREW_INCLUDE_PATH:$CPLUS_INCLUDE_PATH"

# Build the package with additional flags
swift build -Xcc -I$HOMEBREW_INCLUDE_PATH -Xlinker -L$HOMEBREW_LIB_PATH 
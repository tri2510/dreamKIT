#!/bin/bash

# Directory to store the copied libraries
EXE_DIR="./exec"

# Create the directory if it doesn't exist
mkdir -p $EXE_DIR

# Use lddtree to list all dependencies and copy them to the LIB_DIR
lddtree -l ./dk_manager | xargs -I '{}' cp -v '{}' $EXE_DIR

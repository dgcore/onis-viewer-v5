#!/bin/bash

echo "Testing directory check..."

if [ -d "apps/onis_viewer" ]; then
    echo "Directory exists - running flutter analyze"
    cd apps/onis_viewer && flutter analyze
    cd ../..
else
    echo "Directory does not exist"
fi

echo "Test complete" 
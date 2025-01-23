#!/bin/bash

for dir in GFP*/; do
if [ -d "$dir" ]; then
new_dir="$dir/K=1.5_Min=20"
mkdir -p "$new_dir"
mv "$dir"/*binary.tif "$new_dir"
mv "$dir"/*.csv "$new_dir"
fi
done

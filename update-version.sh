#!/usr/bin/env bash

scriptPath=$(dirname "$0")
echo $scriptPath
. "$scriptPath/update-version-functions.sh"

source_service_name="$1"

find . -maxdepth 2 -type f -name 'umbrel-app.yml' | \
while read -r file; do
  process_manifest "$file" "$source_service_name"
done

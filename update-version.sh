#!/bin/sh

name="$1"

find . -type f -name 'umbrel-app.yml' | while read -r file; do
  echo "--- Found: $file"
  directory=$(dirname "$file")
  version=$(yq e ".services.$name.image" "$directory/docker-compose.yml" | grep -v null | sed -E 's/.*:([^@]+)@.*/\1/')
  if [ -n "$version" ]; then
    yq e -i ".version = \"$version\"" "$file"
  fi
  echo ""
done

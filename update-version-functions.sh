#!/usr/bin/env bash

check_not_empty() {
  local value="$1"
  local error_message="$2"

  if [[ -z "$value" ]]; then
    echo "Error: $error_message" >&2
    exit 1
  fi
}

resolve_service() {
  local source_service_name=$1
  local directory=$2

  if [ -n "$source_service_name" ]; then
    service_name="$source_service_name"
  else
    service_name=$(yq e ".services.app_proxy.environment.APP_HOST" "$directory/docker-compose.yml" | \
      grep -v null | \
      sed -E 's/^[^_]+_([^_]+)_[^_]+$/\1/') # Extract <service-name> from the convention <project-name>_<service-name>_<replica-number>
  fi

  echo $service_name
}

resolve_image() {
  local service_name=$1
  local directory=$2

  echo $(yq ".services.$service_name.image" "$directory/docker-compose.yml" | grep -v null)
}

resolve_version() {
  local image=$1
  local directory=$2

  version=$(echo "$image" | sed -E '/:.*@/!d; s/.*:([^@]+)@.*/\1/') # Extract the version part between ':' and '@' from the image string
  echo $version | grep -v null
}

process_manifest() {
  local file="$1"
  local source_service_name="$2"

  echo "- Found umbrel manifest: $file"
  local directory
  directory=$(dirname "$file")

  local service_name
  service_name=$(resolve_service "$source_service_name" "$directory")
  check_not_empty "$service_name" "Could not resolve service name in manifest '$file'"
  echo "- Resolved service name to: $service_name"

  local image
  image=$(resolve_image "$service_name" "$directory")
  check_not_empty "$image" "Could not resolve image of '$service_name' in manifest '$file'"
  echo "- Resolved image to: $image"

  local version
  version=$(resolve_version "$image" "$directory")
  check_not_empty "$version" "Could not resolve version of '$service_name' in manifest '$file'"
  echo "- Resolved version to: $version"

  yq e --inplace ".version = \"$version\"" "$file"
}

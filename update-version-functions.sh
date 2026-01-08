#!/usr/bin/env bash

command() {
  local message="$1"
  local command="$2"

  local file="${BASH_SOURCE[2]}"
  local line="${BASH_LINENO[2]}"
  local col=1  # Bash does not provide column info, so default to 1

  echo "::$2 file=${file},line=${line},col=${col}::${message}"
}

warn() {
  local message="$1"
  echo -en "\033[33m"
  command "$message" "warning"
  echo -en "\033[0m"
  echo "WARNINGS_EMITTED=true" >> "$GITHUB_ENV"
}

error() {
  local message="$1"
  command "$message" "error"
}

warn_if_empty() {
  local value="$1"
  local warning_message="$2"

  if [[ -z "$value" ]]; then
    warn "$warning_message"
  fi
}

resolve_service() {
  local source_service_name=$1
  local directory=$2
  local fallback_service_name=$3

  if [ -n "$source_service_name" ]; then
    service_name="$source_service_name"
  else
    service_name=$(yq e ".services.app_proxy.environment.APP_HOST" "$directory/docker-compose.yml" | \
      grep -v null | \
      sed -E 's/^[^_]+_([^_]+)_[^_]+$/\1/') # Extract <service-name> from the convention <project-name>_<service-name>_<replica-number>
  fi

  if [ "$(yq e ".services.\"$service_name\".image" "$directory/docker-compose.yml")" = "null" ]; then
    if [ -n "$fallback_service_name" ]; then
      service_name="$fallback_service_name"
    else
      service_name=""
    fi
  fi

  echo "$service_name"
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
  local fallback_service_name="$3"

  local directory
  directory=$(dirname "$file")

  local service_name=$(resolve_service "$source_service_name" "$directory" "$fallback_service_name")
  warn_if_empty "$service_name" "Could not resolve service name in manifest '$file'"
  echo "- Resolved service name to: $service_name"

  local image=$(resolve_image "$service_name" "$directory")
  warn_if_empty "$image" "Could not resolve image of '$service_name' in manifest '$file'"
  echo "- Resolved image to: $image"

  local version=$(resolve_version "$image" "$directory")
  warn_if_empty "$version" "Could not resolve version of '$service_name' in manifest '$file'"
  echo "- Resolved version to: $version"

  if [[ -n "$version" ]]; then
    sed -i -E "s/^\s*version:.*$/version: \"$version\"/" "$file"
  fi
}

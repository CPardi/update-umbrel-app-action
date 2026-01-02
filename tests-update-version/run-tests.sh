#!/usr/bin/env bash

setup() {
    echo "---- Begin setup ----"
  . ../update-version-functions.sh
    echo "----  End setup  ----"
}

assert_version() {
  directory=$1
  expected_version=$2


  version=$(yq ".version" "test-default-convention/umbrel-app.yml")
  if [[ "$version" != "$expected_version" ]]; then
    echo "FAILED: expected version '$expected_version' but got '$version'" >&2
    return 1
  fi

  echo "PASSED"
}

test_default_convention() {
  echo "---- Begin test-default-convention ----"
  process_manifest "test-default-convention/umbrel-app.yml"
  assert_version "test-default-convention" "v0.9.0"
  echo "---- End test-default-convention ----"
}

test_source_service_name() {
  echo "---- Begin test-source-service-name ----"
  process_manifest "test-source-service-name/umbrel-app.yml" "source"
  assert_version "test-source-service-name" "v0.9.0"
  echo "---- End test-source-service-name ----"
}

test_fallback_service_name() {
  echo "---- Begin test-fallback-service-name ----"
  process_manifest "test-fallback-service-name/umbrel-app.yml" "" "fallback"
  assert_version "test-fallback-service-name" "v0.9.0"
  echo "---- End test-fallback-service-name ----"
}

setup
test_default_convention
test_source_service_name
test_fallback_service_name

#!/usr/bin/env bash

setup() {
  echo "::group::Begin setup"
  . update-version-functions.sh
  echo "::endgroup::"
}

fail=0
assert_version() {
  local directory=$1
  local expected_version=$2

  local version
  version=$(yq ".version" "$directory/umbrel-app.yml")
  if [[ "$version" != "$expected_version" ]]; then
    error "FAILED: expected version '$expected_version' but got '$version'"
    fail=1
    return 1
  fi

  echo "PASSED"
}

run_test() {
  local expected_version=$1
  local test_name=$2
  local source_service_name=$3
  local fallback_service_name=$4

  echo "::group::$test_name"
  process_manifest "$test_name/umbrel-app.yml" "$source_service_name" "$fallback_service_name"
  assert_version "$test_name" "$expected_version"
  echo "::endgroup::"
}

setup

run_test "v0.9.0" "test-default-convention" "" ""
run_test "v0.9.0" "test-source-service-name" "source" ""
run_test "v0.9.0" "test-fallback-service-name" "" "fallback"
run_test "v1.8.2" "test-no-app-proxy" "" "web"
run_test "v1.8.2" "test-ip-app-host" "" "web"
run_test "v1.8.2" "test-missing-fallback" "" "web"

if [ "$fail" -eq 1 ]; then
  exit 1
fi

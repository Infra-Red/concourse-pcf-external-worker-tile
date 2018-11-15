#!/usr/bin/env bash

set -eu

root_dir=$(cd "$(dirname "$0")" && pwd)

fly -t ci set-pipeline -n \
  -p concourse-external-worker-tile-ci \
  -c $root_dir/pipeline.yml \
  -l <(lpass show --note "pcf:concourse-external-worker-tile-ci")

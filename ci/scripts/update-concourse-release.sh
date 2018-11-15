#!/usr/local/bin/dumb-init /bin/bash

set -exu -o pipefail

base=$PWD

concourse_version=$(cat "$base"/concourse-release/version)
concourse_blob="concourse-${concourse_version}.tgz"
garden_version=$(cat "$base"/garden-runc-release/version)
garden_blob="garden-runc-release-${garden_version}.tgz"

existing_concourse_blob=$(yq r "$base"/git-concourse-pcf-external-worker-release/tile.yml packages.[0].path | cut -d'/' -f2)

if [ $concourse_blob == $existing_concourse_blob ]; then
  echo "Concourse blob already up-to-date."
  exit 0
fi

cp -r git-concourse-pcf-external-worker-release/. git-concourse-pcf-external-worker-release-output

cp "$base"/concourse-release/release.tgz "$base"/git-concourse-pcf-external-worker-release-output/resources/"$concourse_blob"
cp "$base"/garden-runc-release/release.tgz "$base"/git-concourse-pcf-external-worker-release-output/resources/"$garden_blob"

(
cd git-concourse-pcf-external-worker-release-output

yq w -i tile.yml packages.[0].path "resources/${$concourse_blob}"
yq w -i tile.yml packages.[1].path "resources/${$garden_blob}"

tile build "${concourse_version}"
)

#!/usr/local/bin/dumb-init /bin/bash

set -exu -o pipefail

base=$PWD

concourse_version=$(cat "$base"/concourse-release/version)
concourse_blob="concourse-${concourse_version}.tgz"

existing_concourse_blob=$(yq r "$base"/git-concourse-pcf-external-worker-release/tile.yml packages.[0].path | cut -d'/' -f2)

if [ $concourse_blob == $existing_concourse_blob ]; then
  echo "Concourse blob already up-to-date."
  exit 0
fi

product="$(yq r "$base"/git-concourse-pcf-external-worker-release-output/tile.yml name)"

om="om -t $PCF_URL -u $PCF_USERNAME -p $PCF_PASSWORD -k"

echo "Retrieving current staged version of ${product}"

product_version=$(${om} deployed-products -f json | jq -r --arg product_name $product '.[] | select(.name == $product_name) | .version')

echo "Deleting product [${product}], version [${product_version}] , from ${PCF_URL}"

${om} unstage-product --product-name "$product"

${om} apply-changes --ignore-warnings true

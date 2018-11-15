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

tile_file=`cd git-concourse-pcf-external-worker-release-output/product; ls *-${concourse_version}.pivotal`
if [ -z "${tile_file}" ]; then
	echo "No files matching git-concourse-pcf-external-worker-release-output/product/*.pivotal"
	ls -lR artifacts
	exit 1
fi

stemcell_file=`cd stemcell; ls *bosh-stemcell-*.tgz`
if [ -z "${stemcell_file}" ]; then
	echo "No files matching stemcell/*.tgz"
	ls -lR stemcell
	exit 1
fi

product="$(yq r "$base"/git-concourse-pcf-external-worker-release-output/tile.yml name)"

om="om -t $PCF_URL -u $PCF_USERNAME -p $PCF_PASSWORD -k"

${om} upload-product --product "${base}/git-concourse-pcf-external-worker-release-output/product/${tile_file}"
${om} upload-stemcell --stemcell "stemcell/${stemcell_file}"
${om} available-products
${om} stage-product --product-name "${product}" --product-version "${concourse_version}"

echo "$PRODUCT_PROPERTIES" > properties.yml
echo "$PRODUCT_NETWORK_AZS" > network-azs.yml

properties_config=$(ruby -ryaml -rjson -e 'puts JSON.pretty_generate(YAML.load(ARGF))' < properties.yml)
properties_config=$(echo "$properties_config" | jq 'delpaths([path(.[][] | select(. == null))]) | delpaths([path(.[][] | select(. == ""))]) | delpaths([path(.[] | select(. == {}))])')

network_config=$(ruby -ryaml -rjson -e 'puts JSON.pretty_generate(YAML.load(ARGF))' < network-azs.yml)

${om} configure-product --product-name "$product" --product-network "$network_config" --product-properties "$properties_config"

staged=$(${om} curl --path /api/v0/staged/products)
result=$(echo "$staged" | jq --arg product_name "$product" 'map(select(.type == $product_name)) | .[].guid')
data=$(echo '{"deploy_products": []}' | jq ".deploy_products += [$result]")

${om} curl --path /api/v0/installations --request POST --data "$data"
${om} apply-changes --skip-deploy-products="true"
${om} delete-unused-products

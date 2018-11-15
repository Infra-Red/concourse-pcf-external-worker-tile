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

release_root="$base"/gh
repo_out="$base"/pushme
repo_root="$base"/git-concourse-pcf-external-worker-release-output
branch="${branch:-master}"

echo "v${concourse_version}" > ${release_root}/tag
echo "v${concourse_version}" > ${release_root}/name

cp "$base"/git-concourse-pcf-external-worker-release-output/product/*.pivotal ${release_root}/artifacts

cat > ${release_root}/notification <<EOF
<!here> New tile v${VERSION} released!
EOF

git config --global user.email "ci@infra-red.xyz"
git config --global user.name "CI BOT"

(cd ${repo_root}
 git merge --no-edit ${branch}
 git add -A
 git status
 git commit -m "Tile release v${concourse_version}")

# so that future steps in the pipeline can push our changes
cp -a ${repo_root} ${repo_out}

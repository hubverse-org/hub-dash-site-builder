#!/usr/bin/env bash
set -e

ORG=${1:-"hubverse-org"}
REPO=${2:-"hub-dashboard-predtimechart"}
BRANCH=${3:-"main"}
DIR=${4:-""}
if [[ $ORG == "hubverse-org" && $REPO == "hub-dashboard-predtimechart" ]]; then
  DIR="demo/"
fi
ROOT="https://raw.githubusercontent.com/$ORG/$REPO/refs/heads/$BRANCH/$DIR"

# copy resources to the user's site
echo "📂 Copying site skeleton"
cp -R /static/* /site/pages/
# modify the quarto to contain the pages and their ordering
bash modify-quarto-yml.sh \
  /site/pages/_quarto.yml \
  /site/site-config.yml \
  "${ORG}" "${REPO}"
# modify the predtimechart js to get content from the correct place
sed -i -E "s+\{ROOT\}+$ROOT+" /site/pages/resources/predtimechart.js
# render the site!
echo "🏗  Building the site"
quarto render /site/pages/
echo "😃 All done!"

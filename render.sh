#!/usr/bin/env bash
set -e

ORG=${1:-""}
REPO=${2:-""}
BRANCH=${3:-"main"}
DIR=${4:-""}
FORECASTS=${5:-"true"}
if [[ $ORG == "hubverse-org" && $REPO == "hub-dashboard-predtimechart" ]]; then
  DIR="demo/"
fi
if [[ -z $ORG && -z $REPO ]]; then
  # the default will be the repo from the config
  full=$(yq .hub /site/site-config.yml)
  ORG=${full%%/*} # bash expansion: delete longest match after '/'
  REPO=${full#*/} # bash expansion: delete shortest match before '/'
  REPO=${REPO%/*} # bash expansion: delete shortest match after '/'
fi
ROOT="https://raw.githubusercontent.com/$ORG/$REPO/refs/heads/$BRANCH/$DIR"

# copy resources to the user's site
echo "📂 Copying site skeleton"
cp -R /static/* /site/pages/
# modify the quarto to contain the pages and their ordering
bash /modify-quarto-yml.sh \
  /site/pages/_quarto.yml \
  /site/site-config.yml \
  "${ORG}" \
  "${REPO}" \
  "${FORECASTS}"
if [[ "${FORECASTS}" == "false" ]]; then
  echo "  Discarding forecasts page"
  rm /site/pages/forecast.qmd /site/pages/resources/predtimechart.js
else
  # modify the predtimechart js to get content from the correct place
  sed -i -E "s+\{ROOT\}+$ROOT+" /site/pages/resources/predtimechart.js
fi
# render the site!
echo "🏗  Building the site"
quarto render /site/pages/
echo "😃 All done!"

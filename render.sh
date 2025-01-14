#!/usr/bin/env bash
set -e

ORG=${1:-""}
REPO=${2:-""}
BRANCH=${3:-"ptc/data"}
DIR=${4:-""}
FORECASTS=${5:-""}
EVALS=${6:-""}
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
if [[ -z "${FORECASTS}" && -e "/site/predtimechart-config.yml" ]]; then
  # If the forecasts are not specified, we check for the existence of the
  # predtimechart-config.yml and set it to TRUE if it does exist
  FORECASTS="true"
else
  # if either of these is not true, then we take the value of forecasts,
  # but default to false because that means that predtimechart-config
  # does not exist
  FORECASTS=${FORECASTS:-"false"}
fi
if [[ -z "${EVALS}" && -e "/site/predeval-config.yml" ]]; then
  EVALS="true"
else
  EVALS=${EVALS:-"false"}
fi

# copy resources to the user's site
echo "📂 Copying site skeleton"
cp -R /static/* /site/pages/
# modify the quarto to contain the pages and their ordering
bash /modify-quarto-yml.sh \
  /site/pages/_quarto.yml \
  /site/site-config.yml \
  "${ORG}" \
  "${REPO}" \
  "${FORECASTS}" \
  "${EVALS}"
if [[ "${FORECASTS}" == "false" ]]; then
  echo "  Discarding forecasts page"
  rm /site/pages/forecast.qmd /site/pages/resources/predtimechart.js
else
  FORECAST_ROOT="https://raw.githubusercontent.com/$ORG/$REPO/refs/heads/$BRANCH/$DIR"
  # modify the predtimechart js to get content from the correct place
  sed -i -E "s+\{ROOT\}+${FORECAST_ROOT}+" /site/pages/resources/predtimechart.js
fi
if [[ "${EVALS}" == "false" ]]; then
  echo "  Discarding (experimental) evals page"
  rm /site/pages/eval.qmd /site/pages/resources/predeval_interface.js
else
  # TODO: change this when we publish
  EVAL_BRANCH="predeval/data"
  EVAL_ROOT="https://raw.githubusercontent.com/$ORG/$REPO/refs/heads/${EVAL_BRANCH}/$DIR"
  # modify the predtimechart js to get content from the correct place
  sed -i -E "s+\{ROOT\}+${EVAL_ROOT}+" /site/pages/resources/predeval_interface.js
fi
# render the site!
echo "🏗  Building the site"
quarto render /site/pages/
echo "😃 All done!"

#!/usr/bin/env bash
set -e

PTC=""
PREDEVALS=""

usage () {
  echo "Render a dashboard website"
  echo
  echo "USAGE"
  echo
  echo "  render.sh [-h] [-u <user> -r <repo>] [-p <ptc/data> -e <predevals/data>] [-o <outpath>]"
  echo
  echo "ARGUMENTS"
  echo
  echo "  -h  print help and exit"
  echo "  -u  the name of the github organization"
  echo "  -r  the name of the github repository"
  echo "  -p  _relative_ path to predtimechart data generated by hub-dashbaord-predtimechart."
  echo '       If this is missing, data are assumed to be fetched from the'
  echo '       `ptc/data` branch in the GitHub repository'
  echo "  -e  _relative_ path to data generated by hubPredEvalsData"
  echo '       If this is missing, data are assumed to be fetched from the'
  echo '       `predevals/data` branch in the GitHub repository'
  echo '  -o  _relative_ path to output directory.'
  echo '       If this is empty, it defaults to pages/_site/'
  echo
  echo 'EXAMPLES'
  echo
  echo '  The examples below will demonstrate how to build a website locally using'
  echo '  both remote and local data. We will use the flusight dashboard website'
  echo '  repository for this example. In both examples, the site will appear'
  echo '  in the pages/_site/ folder'
  echo
  echo '  ```'
  echo '  # setup: clone the dashboard repository'
  echo '  git clone https://github.com/reichlab/flusight-dashboard.git'
  echo '  cd flusight-dashboard'
  echo '  ```'
  echo
  echo '  Specify owner and repo to generate a website that pulls data from GitHub'
  echo '  ```'
  echo '  docker run --rm -it -v "$(pwd)":"/site" \'
  echo '  render.sh -u reichlab -r flusight-dashboard -o remote'
  echo '  # serve the site (and view in your browser by going to localhost:8080)'
  echo '  python -m http.server 8080 -d remote'
  echo '  ```'
  echo
  echo '  Specify local data folders to generate a standalone website that can be'
  echo '  be used offline.'
  echo
  echo '  ```'
  echo '  # additional setup: add worktrees for the data branches'
  echo '  mkdir -p data'
  echo '  git worktree add data/ptc ptc/data'
  echo '  git worktree add data/evals predevals/data'
  echo '  ```'
  echo
  echo '  ```'
  echo '  docker run --rm -it -v "$(pwd)":"/site" \'
  echo '  render.sh -p data/ptc -e data/evals -o local'
  echo '  # serve the site (and view in your browser by going to localhost:8080)'
  echo '  python -m http.server 8080 -d local'
  echo '  ```'
}

while getopts "o:r:p:e:s:h" opt; do
  case $opt in
    u)
      ORG="$OPTARG";
    ;;
    r)
      REPO="$OPTARG";
    ;;
    p)
      PTC="$OPTARG"
    ;;
    e)
      PREDEVALS="$OPTARG"
    ;;
    o)
      OUT="$OPTARG"
    ;;
    h)
      usage
      exit 0
    ;;
  esac
done

# Print the help if no arguments are given
if [ $OPTIND -eq 1 ]; then usage; exit 0; fi

if [[ (-z $ORG || -z $REPO) && (-z $PTC || -z $PREDEVALS) ]]; then
  usage
  echo
  echo "ERROR: The correct pair of arguments are REQUIRED"
  echo
  echo "FOR REMOTE DATA"
  echo "  -u (user) and -r (repo)"
  echo "  This provides information to construct a raw GitHub URL"
  echo "  (used for public data)"
  echo
  echo "FOR LOCAL DATA"
  echo "  -p (predtimechart data) and -e (predevals data)"
  echo "  These are local folders to be copied into the website"
  echo "  (best for private data)"
  echo
  exit 1
fi

# Do we need to build forecasts or evals? This is determined by the presence
# of the configuration files. If they _are_ present, we preferentially take
# the values of the PTC and PREDEVALS values (which correspond to the
# predtimechart and predevals data, respectively)
if [[ -e "$PWD/predtimechart-config.yml" ]]; then
  FORECASTS="${PTC:-true}"
else
  FORECASTS=""
fi
if [[ -e "$PWD/predevals-config.yml" ]]; then
  EVALS="${PREDEVALS:-true}"
else
  EVALS=""
fi

# Work in a temporary directory to not bork the users workspace
tmp="$(mktemp -d)"
cp -R $PWD/pages/* "$tmp"

# copy resources to the user's site
echo "📂 Copying site skeleton"
cp -R /static/* "$tmp"

# modify the quarto to contain the pages and their ordering
modify-quarto-yml.sh \
  "${tmp}/_quarto.yml" \
  "$PWD$PWD-config.yml" \
  "${ORG}" \
  "${REPO}" \
  "${FORECASTS}" \
  "${EVALS}"

# Prepare the visualizations
#
# IF THERE ARE NO VISUALIZATIONS:
#   discard the visualization page and set the root to nothing
# IF THE USER HAS SPECIFIED A DIRECTORY:
#   copy that directory to our temporary folder and set it as the ROOT
# OTHERWISE:
#   use the raw github content as the ROOT
if [[ -z "${FORECASTS}" ]]; then
  echo "  Discarding forecasts page"
  FORECAST_ROOT=""
  rm "${tmp}/forecast.qmd" "${tmp}/resources/predtimechart.js"
elif [[ ${FORECASTS} != "true" ]]; then
  FORECAST_ROOT="/resources/forecasts"
  cp -R "$PWD/${FORECASTS}/" "${tmp}${FORECAST_ROOT}"
else
  FORECAST_ROOT="https://raw.githubusercontent.com/$ORG/$REPO/refs/heads/ptc/data/$DIR"
fi
if [[ -z "${EVALS}" ]]; then
  echo "  Discarding (experimental) evals page"
  EVAL_ROOT=""
  rm "${tmp}/eval.qmd" "${tmp}/resources/predevals_interface.js"
elif [[ "${EVALS}" != "true" ]]; then
  EVAL_ROOT="/resources/evals/"
  cp -R "$PWD/${EVALS}/" "${tmp}${EVAL_ROOT}"
else
  EVAL_ROOT="https://raw.githubusercontent.com/$ORG/$REPO/refs/heads/predevals/data/$DIR"
fi

# modify the JavaScript to get content from the correct place
if [[ -n "${FORECAST_ROOT}" ]]; then
  sed -i -E "s+\{ROOT\}+${FORECAST_ROOT}+" "${tmp}/resources/predtimechart.js"
fi
if [[ -n "${EVAL_ROOT}" ]]; then
  sed -i -E "s+\{ROOT\}+${EVAL_ROOT}+" "${tmp}/resources/predevals_interface.js"
fi
# render the site!
echo "🏗  Building the site"
quarto render ${flag} ${tmp} && cp -R "${tmp}/_site/" "$PWD/${OUT:-pages/_site/}"
echo "😃 All done!"

#!/usr/bin/env bash
set -e
# This script uses yq, which is a command line utility to query and manipulate
# YAML files. One aspect of YQ is that the script must be presented as a string.
# I will do my best to add links to documentation about the syntax of the yq
# script.
#
# GOAL: We want to join site-config.yml (CFG) into _quarto.yml (YML)
# 
# CONVENTIONS: To document this with useful resources, I will be labelling
# individual steps with square brackets and ALL CAPS so that it's easy to search
# for them in in the script below.
# If you use emacs, you can use <M-s>. to search for the word
# If you use vim, you can use * in normal mode to search for the word
# On other editors, use <ctrl>+f
#
# Overall Guide to YQ: <https://mikefarah.gitbook.io/yq>
# Pipe operator [|]: <https://mikefarah.gitbook.io/yq/operators/pipe#multiple-updates>
#
# [CFG]:
#   load: <https://mikefarah.gitbook.io/yq/operators/load>
#   variables: <https://mikefarah.gitbook.io/yq/operators/variable-operators>
#
# [URL]:
#   assignment [|=]: <https://mikefarah.gitbook.io/yq/operators/assign-update>
#
# [RESOURCE]:
#   add [+=]: <https://mikefarah.gitbook.io/yq/operators/add>
#
# [HUB]:
#   with: <https://mikefarah.gitbook.io/yq/operators/with>
#   assignment [|=]: <https://mikefarah.gitbook.io/yq/operators/assign-update>
#   interpolation [\(.var)]: <https://mikefarah.gitbook.io/yq/operators/string-operators#interpolation>
#   split: <https://mikefarah.gitbook.io/yq/operators/string-operators#split-strings>
#
# [PAGES]:
#   assignment [|=]: <https://mikefarah.gitbook.io/yq/operators/assign-update>
#   with: <https://mikefarah.gitbook.io/yq/operators/with>
#
# [TITLE]:
#   assignment [|=]: <https://mikefarah.gitbook.io/yq/operators/assign-update>
#   with: <https://mikefarah.gitbook.io/yq/operators/with>
#
# [FORMAT]:
#   assignment [|=]: <https://mikefarah.gitbook.io/yq/operators/assign-update>
#   with: <https://mikefarah.gitbook.io/yq/operators/with>
#   merge: <https://mikefarah.gitbook.io/yq/operators/multiply-merge#merge-objects-together-returning-parent-object>
#   logic [select()]: <https://mikefarah.gitbook.io/yq/usage/tips-and-tricks#logic-without-if-elif-else>
#   delete [del()]: <https://mikefarah.gitbook.io/yq/operators/delete>
#
# [CSS]:
#   assignment [=]: <https://mikefarah.gitbook.io/yq/operators/assign-update>
#   with: <https://mikefarah.gitbook.io/yq/operators/with>
#   logic [select()]: <https://mikefarah.gitbook.io/yq/usage/tips-and-tricks#logic-without-if-elif-else>
#
# [FORECAST]:
#   assignment [=]: <https://mikefarah.gitbook.io/yq/operators/assign-update>
#   with: <https://mikefarah.gitbook.io/yq/operators/with>
#   filter: <https://mikefarah.gitbook.io/yq/operators/filter>
#   add [+=]: <https://mikefarah.gitbook.io/yq/operators/add>
#
# [EVAL]:
#   assignment [=]: <https://mikefarah.gitbook.io/yq/operators/assign-update>
#   with: <https://mikefarah.gitbook.io/yq/operators/with>
#   filter: <https://mikefarah.gitbook.io/yq/operators/filter>
#   add [+=]: <https://mikefarah.gitbook.io/yq/operators/add>
#
YML=${1:-"/site/pages/_quarto.yml"}
CFG=${2:-"/site/site-config.yml"}
ORG=${3:-"hubverse-org"}
REPO=${4:-"hub-dashboard-template"}
FORECAST=${5:-""}
EVAL=${6:-""}

echo "  Updating site config"
yq -i '
  # load the user site config
  # [CFG] ------------------------------------------------------
  load("'"${CFG}"'") as $cfg |

  # Set the github links of the repo to the org
  # [URL] ------------------------------------------------------
  .website.repo-url |= "https://github.com/'"${ORG}/${REPO}"'" |
  # ensure the resources are copied over
  # [RESOURCE] -------------------------------------------------
  .resources += $cfg.resources |

  # Set the right of the navbar to point to the hub
  # [HUB] ------------------------------------------------------
  with(.website.navbar.right;
    # Update Hub information 
    .[0].href |= "https://github.com/\($cfg.hub)" |
    # Title of the hub will be the repo name (without org)
    .[0].text |= $cfg.hub |
    .[0].text |= split("/")[1] 
  ) |

  # Add the pages to the navigation bar
  # [PAGES] ----------------------------------------------------
  with(.website.navbar.left;
    . += $cfg.pages
  ) |
  # Update the title
  # [TITLE] ----------------------------------------------------
  with(.website.title;
    . |= $cfg.title
  ) |

  # Update the HTML parameters
  # [FORMAT] ---------------------------------------------------
  # 1. back up the original parameters as a new node (will delete later).
  .bak = .format.html |
  # 2. attempt to merge the parameters.
  with(.format;
    . |= . * {"html":$cfg.html}
  ) |
  # 3. if the merge failed, restore original
  with(select(.format.html == null);
    .format.html = .bak
  ) |
  # 4. remove the backup
  del(.bak) |

  # Allow people to revert to default CSS
  # [CSS] ------------------------------------------------------
  with(select(.format.html.css == null);
    .format.html.css = "/dev/null"
  )
' "${YML}"

if [[ -z "${FORECAST}" ]]; then
  # remove the forecast page if it does not exist
  # [FORECAST] -------------------------------------------------
  yq -i 'with(.website.navbar.left; . |= filter(.href != "forecast.qmd"))' "${YML}"
elif [[ "${FORECAST}" != "true" ]]; then
  # otherwise, include the data (if it exists)
  yq -i '.resources += "/resources/forecasts"' "${YML}"
fi
if [[ -z "${EVAL}" ]]; then
  # remove the eval page if it does not exist
  # [EVAL] -----------------------------------------------------
  yq -i 'with(.website.navbar.left; . |= filter(.href != "eval.qmd"))' "${YML}"
elif [[ "${EVAL}" != "true" ]]; then
  # otherwise, include the data (if it exists)
  yq -i '.resources += "/resources/evals"' "${YML}"
fi

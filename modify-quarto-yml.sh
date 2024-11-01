#!/usr/bin/env bash
set -e

YML=${1:-"/site/pages/_quarto.yml"}
CFG=${2:-"/site/site-config.yml"}
ORG=${2:-"hubverse-org"}
REPO=${3:-"hub-dashboard-predtimechart"}

echo "  Updating site config"
yq -i '
  # load the user site config
  load("'"${CFG}"'") as $cfg |

  # Add the pages to the navigation bar
  with(.website.navbar.right;
    # Update Hub information 
    .[0].href |= "https://github.com/\($cfg.hub)" |
    # Title of the hub will be the repo name (without org)
    .[0].text |= $cfg.hub |
    .[0].text |= split("/")[1] 
    # Set the URL for the website source
    # .[1].href |= "https://github.com/'"${ORG}/${REPO}"'"
    # .[1].text |= "Website" |
  ) |

  # Add the pages to the navigation bar
  with(.website.navbar.left;
    . += $cfg.pages
  ) |
  # Update the title
  with(.website.title;
    . |= $cfg.title
  )
' "${YML}"

#!/usr/bin/env bash
set -e

YML=${1:-"/site/pages/_quarto.yml"}
CFG=${2:-"/site/site-config.yml"}
ORG=${3:-"hubverse-org"}
REPO=${4:-"hub-dashboard-template"}

echo "  Updating site config"
yq -i '
  # load the user site config
  load("'"${CFG}"'") as $cfg |

  # Set the github links of the repo to the org
  .website.repo-url |= "https://github.com/'"${ORG}/${REPO}"'" |

  # Set the right of the navbar to point to the hub
  with(.website.navbar.right;
    # Update Hub information 
    .[0].href |= "https://github.com/\($cfg.hub)" |
    # Title of the hub will be the repo name (without org)
    .[0].text |= $cfg.hub |
    .[0].text |= split("/")[1] 
  ) |

  # Add the pages to the navigation bar
  with(.website.navbar.left;
    . += $cfg.pages
  ) |
  # Update the title
  with(.website.title;
    . |= $cfg.title
  ) |
  with(.format;
    . |= . * {"html":$cfg.html}
  ) 
' "${YML}"

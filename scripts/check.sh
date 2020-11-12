#1/bin/bash
# Script to check for new kernel release
set -e
set -o pipefail

MAJOR=$(echo $1 | sed -e "s/^v//" -e "s/\.[^.]*$//")
CURRENT=$(scripts/version.sh -L)
NEW=$(curl -s https://www.kernel.org/releases.json | jq -r ".releases[]|select(.version | startswith(\"$MAJOR\")) | .version")

[[ "$CURRENT" = "$NEW" ]] || echo $NEW

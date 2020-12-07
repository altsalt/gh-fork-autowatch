#!/bin/bash
#
# GPL-3+ 🄯 2020 Wm Salt Hale <@altsalt (.net)>
#

##
# Auto-Watch GitHub Forks
#
# Use GitHub's API to place a watch on all forks of your repos.
#
# Useful for tracking changes which are not submitted as a PR, thus avoiding duplicate effort.
#
# Be sure to set your GitHub Username and OAuth2 token in `Step 0`
#
# StackExchange Question:
# - https://webapps.stackexchange.com/questions/30336/automatically-watch-all-github-repos-forked-from-my-original
#
# GitHub API References:
# - https://docs.github.com/v3/repos/forks/
# - https://docs.github.com/v3/activity/watching/
#

# `list_contains` utility function
# adapted from https://stackoverflow.com/a/20473191
function list_contains {
  local list="$1"
  local item="$2"
  if [[ $list =~ (^|[[:space:]])"$item"($|[[:space:]]) ]] ; then
    # yes, list contains item
    result=0
  else
    result=1
  fi
  return $result
}


# Step 0:
# Enter your GitHub username and OAuth2 token
# (How to generate an OAuth2 token: https://help.github.com/articles/creating-an-access-token-for-command-line-use)
GH_USR="changeme"
GH_AUTH="changeme"

# Step 1:
# Select the reposities and forks that you do not want included
INCLUDE_OWN_FORKS="true" # TODO: currently doesn't check for `"fork": true;`in response, but when it does, this is how to select only de novo
REPO_BLACKLIST="repo1 repo2 repo3"
FORK_BLACKLIST="forkusr1/repo1 forkusr2/repo1 forkusr3/repo1"

# Step 2:
# Script requests a list of your repositories
# TODO: add pagination as ?per_page max is 100
USR_REPOS=curl \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/users/$GH_USR/repos?type=owner \
  | grep '"name":' \
  | sed -e 's/^.*": "//g' -e 's/",.*$//g' -e 's/\n/ /g'

# Step 3:
# Script requests a list of forks for each of your repos, then subscribes you to notifications for each fork as it is updated
for R in ${USR_REPOS[@]}; do
  if `list_contains "$REPO_BLACKLIST" "$R"` ; then
    continue
  fi

  REPO_FORKS=curl \
    -H "Accept: application/vnd.github.v3+json" \
    https://api.github.com/repos/$GH_USR/$R/forks \
    | grep '"full_name":' \
    | sed -e 's/^.*": "//g' -e 's/",.*$//g' -e 's/\n/ /g'

  for F in ${REPO_FORKS[@]}; do
    if `list_contains "$FORK_BLACKLIST" "$F"` ; then
      continue
    fi

    curl \
      -X PUT \
      -H "Accept: application/vnd.github.v3+json" \
      -H "Authorization: token $GH_AUTH" \
      https://api.github.com/repos/$F/subscription \
      -d '{"subscribed":true}'
  done
done

# TODO: add a counter for output about how many repos were watched and what they were

echo ""
echo "End of script."

exit 0

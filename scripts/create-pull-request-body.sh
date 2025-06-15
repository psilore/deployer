#!/usr/bin/env bash

set -euo pipefail

command_exists() {
  command -v "$@" >/dev/null 2>&1
}

format_error() {
  printf '%sERROR: %s%s\n' "${FMT_RED}" "$*" "$FMT_RESET" >&2
}

format_log() {
  local date
  date="$(date +"%b %d %H:%M:%S")"
  printf "%s$date %s%s\n" "${FMT_BOLD}" "$*" "$FMT_RESET" >&2
}

setup_colors(){
FMT_RED=$(printf '\033[31m')
FMT_RESET=$(printf '\033[0m')
FMT_BOLD=$(printf '\033[1m')
}

get_repo_names() {
  local OWNER="$1"
  local TEAM_SLUG="$2"
  local URL

  if [ -z "$TEAM_SLUG" ]; then
    URL="orgs/$OWNER/repos"
  else
    URL="orgs/$OWNER/teams/$TEAM_SLUG/repos"
  fi

  fetch_and_save_repo_names "$URL"
}

fetch_and_save_repo_names() {
  local URL="$1"
  local ACTIVE_REPOS
  local REPO_NAMES

  ACTIVE_REPOS=$(gh api "$URL" 2>&1)
  if [ $? -ne 0 ]; then
    format_error "[ERROR] Failed to fetch data from GitHub API:"
    echo "$ACTIVE_REPOS"
    exit 1
  fi

  REPO_NAMES=$(echo "$ACTIVE_REPOS" | jq -r '.[].name' 2>&1)

  if [ $? -ne 0 ]; then
    format_error "[ERROR] Failed to parse JSON with jq:"
    echo "$REPO_NAMES"
    exit 1
  fi

  echo "$REPO_NAMES" > "$REPOS_FILE"
}

setup_pr_body() {
  local PR_BODY_FILE="$1"
  local REPOS_FILE="$2"

  if [ ! -f "$REPOS_FILE" ]; then
    format_error "[ERROR] Repositories file not found: $REPOS_FILE"
    exit 1
  fi
  { 
    printf "### 🦑 Deployer\n\n"
    printf "Select which repository to deploy:\n\n"

  } > "$PR_BODY_FILE"
}

append_checklist() {
  local PR_BODY_FILE="$1"
  local REPOS_FILE="$2"

  if [ ! -f "$REPOS_FILE" ]; then
    format_error "[ERROR] Repositories file not found: $REPOS_FILE"
    exit 1
  fi

  while read -r repo; do
    WORKFLOW_PATH=$(gh api repos/"$OWNER"/"$repo"/actions/workflows --jq '.workflows[] | select(.path | endswith("/deploy.yml")) | .path' 2>/dev/null | head -n1)
    if [[ -z "$WORKFLOW_PATH" ]]; then
      echo "- [ ] $repo" >> "$PR_BODY_FILE"
      continue
    fi

    WORKFLOW_FILE=$(basename "$WORKFLOW_PATH")
    UPDATED_DATE=$(gh run list -R "https://github.com/$OWNER/$repo" -w "$WORKFLOW_FILE" --limit 1 --json updatedAt -q '.[0].updatedAt' 2>/dev/null)

    if [[ -z "$UPDATED_DATE" ]]; then
      echo "- [ ] $repo (Last deploy: never)" >> "$PR_BODY_FILE"
    else
      NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
      RELATIVE=$(dateutils.ddiff "$UPDATED_DATE" "$NOW" -f '%dd %Hh %Mm ago')
      echo "DEBUG: $UPDATED_DATE $NOW $RELATIVE"
      RELATIVE_HUMAN=$(echo "$RELATIVE" | grep -oE '[1-9][0-9]*d|[1-9][0-9]*h|[1-9][0-9]*m' | head -n1)
      [[ -z "$RELATIVE_HUMAN" ]] && RELATIVE_HUMAN="just now"
      [[ "$RELATIVE_HUMAN" != "just now" ]] && RELATIVE_HUMAN="$RELATIVE_HUMAN ago"
      echo "- [ ] $repo (Last deploy: $RELATIVE_HUMAN)" >> "$PR_BODY_FILE"
    fi
  done < "$REPOS_FILE"

}

setup() {
  setup_colors

  command_exists git || {
    format_error "git is not installed"
    exit 1
  }

  command_exists dateutils.ddiff || {
    format_error "dateutils is not installed"
    exit 1
  }

  GIT_ROOT_DIR=$(git rev-parse --show-toplevel)
  CONFIG_DIR="$GIT_ROOT_DIR/config"
  REPOS_FILE="$CONFIG_DIR/active_repositories.txt"
  PR_BODY_FILE="pr_body.md"

  rm -rf config/*
  mkdir -p "$CONFIG_DIR"

  if [ -z "$TEAM_SLUG" ]; then
    format_log "[INFO] Fetching repository names: $OWNER repositories"
    get_repo_names "$OWNER"
  else
    format_log "[INFO] Fetching repository names for team: $TEAM_SLUG repositories"
    get_repo_names "$OWNER" "$TEAM_SLUG"
  fi


}
usage() {
  printf '%s\n' "Usage: $(basename "$0") [OPTIONS]"
  printf '\n'
  printf '%s\n' "Options:"
  printf '\n'
  printf '%s\n' "  -h               Show this help message"
  printf '\n'
  printf '%s\n' "  -o [Required]    Owner in GitHub"
  printf '\n'
  printf '%s\n' "  -t               Team name in GitHub, if no team name is provided,"
  printf '%s\n' "                   all repository names will be fetched from the owner"
  printf '\n'
}

main() {
  while getopts "ho:t:" opt; do
    case $opt in
      h)
        usage
        exit 0
        ;;
      o)
        OWNER="$OPTARG"
        ;;
      t)
        TEAM_SLUG="$OPTARG"
        ;;
      \?)
        usage
        exit 1
        ;;
    esac
  done

  if [[ -z "$OWNER" ]]; then
    format_error "Option [OWNER] is required"
    usage
    exit 1
  fi

  setup
  setup_pr_body "$PR_BODY_FILE" "$REPOS_FILE"
  append_checklist "$PR_BODY_FILE" "$REPOS_FILE"
  exit 0
}

main "$@"
#!/bin/bash

# env: TAP_NAME, GITHUB_TOKEN, GIT_COMMITTER_NAME, GIT_COMMITTER_EMAIL
# output: pr_numbers
# TODO

export HOMEBREW_GITHUB_API_TOKEN="$GITHUB_TOKEN"
export HOMEBREW_GIT_COMMITTER_NAME="$GIT_COMMITTER_NAME"
export HOMEBREW_GIT_COMMITTER_EMAIL="$GIT_COMMITTER_EMAIL"

# Colon-separated list of PR numbers created by `brew bump`.
pr_numbers=""

# Get formulae and casks from the tap.
tap_info_json="$(brew tap-info "$TAP_NAME" --json=v1)"
mapfile -t formulae < <(jq -r ".[]|.formula_names[]" <<< "$tap_info_json")
mapfile -t casks < <(jq -r ".[]|.cask_tokens[]" <<< "$tap_info_json")

# Update formulae from the given tap.
echo "==> Updating formulae..."

for formula in "${formulae[@]}"; do
  brew bump "$TAP_NAME/$formula" --full-name --open-pr --no-fork
  pr_nr="$(gh pr view --json "number" | jq -r ".number")"
  pr_numbers+="$pr_nr:"
done

# Update casks from the given tap.
echo "==> Updating casks..."

for cask in "${casks[@]}"; do
  brew bump "$TAP_NAME/$cask" --full-name --open-pr --no-fork
  pr_nr="$(gh pr view --json "number" | jq -r ".number")"
  pr_numbers+=":$pr_nr"
done

# Export PR numbers.
pr_numbers="${pr_numbers%:}"
pr_numbers="${pr_numbers#:}"
echo "pr_numbers=\"$pr_numbers\"" >> "$GITHUB_OUTPUT"

exit 0

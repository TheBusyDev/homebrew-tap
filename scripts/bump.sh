#!/bin/bash
# Update `version` and `sha265` for all the formulae/casks from the provided tap.
#
# Environment variables:
# - `GITHUB_TOKEN`: Token used for authentication in `gh`.
# - `GIT_COMMITTER_NAME`: The name of the committer.
# - `GIT_COMMITTER_EMAIL`: The email address of the committer.
#
# Input:
# 1. The name of the tap to be updated.
#
# Output (written into `GITHUB_OUTPUT`):
# - `pr_numbers`: Colon-separated list of pull requests numbers created by
#                 `brew bump`.
#

source ./scripts/_functions.sh

# Useful variables.
export HOMEBREW_GITHUB_API_TOKEN="$GITHUB_TOKEN"
export HOMEBREW_GIT_COMMITTER_NAME="$GIT_COMMITTER_NAME"
export HOMEBREW_GIT_COMMITTER_EMAIL="$GIT_COMMITTER_EMAIL"

pr_numbers="" # Colon-separated list of PR numbers created by `brew bump`.

# Get formulae and casks from the tap.
mapfile -t formulae < <(formulae_from_tap "$1")
mapfile -t casks < <(casks_from_tap "$1")

# Update formulae from the given tap.
echo "==> Updating formulae..."

for formula in "${formulae[@]}"; do
  brew_bump_formula "$formula"
  pr_numbers+=":$(current_pr_number)"
done

# Update casks from the given tap.
echo "==> Updating casks..."

for cask in "${casks[@]}"; do
  brew_bump_cask "$cask"
  pr_numbers+=":$(current_pr_number)"
done

# Export PR numbers.
pr_numbers="${pr_numbers%:}"
pr_numbers="${pr_numbers#:}"
echo "pr_numbers=\"$pr_numbers\"" >> "$GITHUB_OUTPUT"

exit 0

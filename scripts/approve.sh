#!/bin/bash
# Auto-approve some pull requests with certain criteria.
#
# Environment variables:
# - `GITHUB_TOKEN`: Token used for authentication in `gh`.
#
# Input:
# 1. Colon-separated list of pull request numbers.
#
# TODO: add criteria list to README.md

# Useful variables.
# Match `version` entries in `.rb` files.
VERSION_REGEX='^\s*version\s+".*"$'
# Match `sha256` entries in `.rb` files.
SHA256_REGEX='^\s*sha256\s+("[a-z0-9]+"|arm:\s+"[a-z0-9]+",\\n\s*intel:\s+"[a-z0-9]+")$'

# Check for every PR in `pr_numbers`.
mapfile -d ":" -t pr_numbers <<< "$1"
failed_pr_urls="" # Newline-separated list of URLs for non-approved pull requests.
success=true      # Have all the approvals run successfully?

for pr_nr in "${pr_numbers[@]}"; do
  echo "==> Checking pull request #$pr_nr..."

  if [[ ! "$pr_nr" =~ [0-9] ]]; then
    echo "::error ::\"$pr_nr\" is not a valid PR number."
    success=false
    continue
  fi

  # Get relevant info from PR.
  pr_json="$(gh pr view "$pr_nr" --json "headRefName,state,url,files")"
  pr_branch="$(jq -r ".headRefName" <<< "$pr_json")"
  pr_state="$(jq -r ".state" <<< "$pr_json")"
  pr_url="$(jq -r ".url" <<< "$pr_json")"

  pr_state="${pr_state,,}"

  # Start checks on the PR.
  safe_to_approve=true

  # Check the PR state.
  if [[ "$pr_state" != "open" ]]; then
    echo "::error ::The pull request #$pr_nr is not open."
    safe_to_approve=false
  fi

  # Get the changed files and check them.
  mapfile -t pr_files < <(jq -r ".files[].path" <<< "$pr_json")

  for file in "${pr_files[@]}"; do
    echo "==> Checking file \`$file\` from pull request #$pr_nr..."

    # Check if not only formula/cask files are modified.
    if [[ ! "$file" =~ ^(Formula|Casks)/.*\.rb$ ]]; then
      echo "::error file=$file::This PR does not modify \`.rb\` files only."
      safe_to_approve=false
      continue
    fi

    # Check difference between files modified in PR and the ones on default branch.
    all_changes="$(git diff -U0 "origin/main...origin/$pr_branch" -- "$file" \
      | grep "^[+-]" \
      | grep -v "^+++" \
      | grep -v "^---" \
      | sed "s/^[+-]//g" \
      || true)"

    unauthorized_changes="$(echo "$all_changes" \
      | grep -vE "$VERSION_REGEX" \
      | grep -vE "$SHA256_REGEX" \
      || true)"

    if [[ -n "$unauthorized_changes" ]]; then
      echo "::error file=$file::Unauthorized changes found."
      safe_to_approve=false
      continue
    fi
  done

  if ! $safe_to_approve; then
    # Append the PR URL to the failed ones.
    failed_pr_urls+="\n$pr_url"
    success=false
  else
    # Finally, approve the PR.
    echo "==> Approving pull request #$pr_nr..."
    gh pr review "$pr_nr" --approve
  fi
done

failed_pr_urls="${failed_pr_urls%\\n}"
failed_pr_urls="${failed_pr_urls#\\n}"

if [[ -n "$failed_pr_urls" ]]; then
  echo -e "::error ::The following PRs require manual approval:\n$failed_pr_urls"
fi

if ! $success; then
  exit 1
fi

exit 0

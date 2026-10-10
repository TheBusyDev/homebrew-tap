#!/bin/bash
# Auto-approve some pull requests with certain criteria.
# Expected environment variables:
# - `GITHUB_TOKEN`: Token used for authentication in `gh`.
# - `PR_NUMBERS`: Colon-separated list of pull request numbers.
# TODO: add criteria list to README.md

# Check for every PR in `PR_NUMBERS``.
mapfile -d ":" -t pr_numbers <<< "$PR_NUMBERS"
failed_pr_urls="" # Newline-separated list of URLs for non-approved pull requests.

for pr_nr in "${pr_numbers[@]}"; do
  echo "==> Checking pull request #$pr_nr..."

  # Get relevant info from PR.
  pr_json="$(gh pr view "$pr_nr" --json "headRefName,state,url,files")"
  pr_branch="$(jq -r ".headRefName" <<< "$pr_json")"
  pr_state="$(jq -r ".state" <<< "$pr_json")"
  pr_url="$(jq -r ".url" <<< "$pr_json")"

  pr_state="${pr_state,,}"

  # Start checks on the PR.
  safe_to_approve=1

  # Check the PR state.
  if [[ "$pr_state" != "open" ]]; then
    echo "::error ::The pull request #$pr_nr is not open."
    safe_to_approve=0
  fi

  # Get the changed files and check them.
  mapfile -t pr_files < <(jq -r ".files[].path" <<< "$pr_json")

  for file in "${pr_files[@]}"; do
    echo "==> Checking file \`$file\` from pull request #$pr_nr..."

    # Check if not only formula/cask files are modified.
    if [[ ! "$file" =~ ^(Formula|Casks)/.*\.rb$ ]]; then
      echo "::error file=$file::This PR does not modify \`.rb\` files only."
      safe_to_approve=0
      continue
    fi

    # Extract URLs from the main branch and the PR branch.
    old_urls=$(git show "origin/HEAD:$file" | grep -E "^\s*url\s+") \
      || {
        echo "::error file=$file::Failed to extract URLs from default brach."
        safe_to_approve=0
        continue
      }

    new_urls=$(git show "origin/$pr_branch:$file" | grep -E "^\s+url\s+") \
      || {
        echo "::error file=$file::Failed to extract URLs from brach \`$pr_branch\`."
        safe_to_approve=0
        continue
      }

    # Check for any modifications in URLs.
    if [[ -z "$old_urls" || -z "$new_urls" ]]; then
      echo "::error file=$file::Cannot retrieve URLs."
      safe_to_approve=0
      continue
    fi

    if [[ "$old_urls" != "$new_urls" ]]; then
      echo "::error file=$file::The original URLs differs from the ones in the new PR."
      safe_to_approve=0
      continue
    fi
  done

  if ((! safe_to_approve)); then
    # Append the PR URL to the failed ones.
    failed_pr_urls="$pr_url\n$failed_pr_urls"
  else
    # Finally, approve the PR.
    gh pr review "$pr_nr" --approve
  fi
done

if [[ ! -z "$failed_pr_urls" ]]; then
  echo -e "::error ::The following PRs require manual approval:\n$failed_pr_urls"
  exit 1
fi

exit 0

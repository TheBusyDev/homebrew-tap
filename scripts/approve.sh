#!/bin/bash

# env vars: PR_LINK, GITHUB_TOKEN. TODO

# Get state and number of the PR.
pr_json="$(gh pr view "$PR_LINK" --json "headRefName,number,state,files")"
pr_branch="$(jq -r ".headRefName" <<< "$pr_json")"
pr_number="$(jq -r ".number" <<< "$pr_json")"
pr_state="$(jq -r ".state" <<< "$pr_json")"
pr_state="${pr_state,,}"

# Start checks on the PR.
safe_to_approve=1

# Check the PR state.
if [[ "$pr_state" != "open" ]]; then
  echo "::error ::The merge request #$pr_number is not open."
  safe_to_approve=0
fi

# Get the changed files and check them.
mapfile -t pr_files < <(jq -r ".files[].path" <<< "$pr_json")

for file in "${pr_files[@]}"; do
  # Check if not only formula/cask files are modified.
  if [[ ! "$file" =~ ^(Formula|Casks)/.*\.rb$ ]]; then
    echo "::error file=$file::This PR does not modify \`.rb\` files only."
    safe_to_approve=0
    continue
  fi

  # Extract URLs from the main branch and the PR branch.
  old_urls=$(git show "origin/HEAD:$file" | grep -E "^\s+url\s+") \
    || {
      echo "::error file=$file::Failed to extract URLs from default brach."
      safe_to_approve=0
    }

  new_urls=$(git show "origin/$pr_branch:$file" | grep -E "^\s+url\s+") \
    || {
      echo "::error file=$file::Failed to extract URLs from brach \`$pr_branch\`."
      safe_to_approve=0
    }

  # Check for any modifications in URLs.
  if [[ -z "$old_urls" || -z "$new_urls" ]]; then
    echo "::error file=$file::Cannot retrieve URLs."
    safe_to_approve=0
  fi

  if [[ "$old_urls" != "$new_urls" ]]; then
    echo "::error file=$file::The original URLs differs from the ones in the new PR."
    safe_to_approve=0
  fi

  # TODO: virustotal
done

if ((! safe_to_approve)); then
  echo "::error ::Manual approval is required. See the link: $PR_LINK"
  exit 1
fi

# Finally, approve the PR.
gh pr review --approve "$PR_LINK"

exit $?

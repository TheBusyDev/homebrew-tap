#!/bin/bash
# Set of functions used to execute the other scripts.

# Get all the formulae/casks from a given tap.
#
# Input:
# 1. The name of the tap.
# 2. Literal string: "formulae" or "casks".
#
# Output:
# Writes a newline-separated list to stdout.
#
function _formulae_or_casks_from_tap() {
  case "$2" in
    casks)
      brew tap-info "$1" --json=v1 | jq -r ".[]|.cask_tokens[]"
      ;;
    *)
      brew tap-info "$1" --json=v1 | jq -r ".[]|.formula_names[]"
      ;;
  esac
}

# Get all the formulae from a given tap.
#
# Input:
# 1. The name of the tap.
#
# Output:
# Writes a newline-separated list of formulae to stdout.
#
function formulae_from_tap() {
  _formulae_or_casks_from_tap "$1" "formulae"
}

# Get all the casks from a given tap.
#
# Input:
# 1. The name of the tap.
#
# Output:
# Writes a newline-separated list of casks to stdout.
#
function casks_from_tap() {
  _formulae_or_casks_from_tap "$1" "casks"
}

# Bump the selected formula/cask, creating a new pull request.
#
# Input:
# 1. The fully-qualified name of the formula/cask.
# 2. Literal string: "formula" or "cask".
#
function _brew_bump_formula_or_cask() {
  brew bump "$1" --"$2" --full-name --open-pr --no-fork
}

# Bump the selected formula, creating a new pull request.
#
# Input:
# 1. The fully-qualified name of the formula.
#
function brew_bump_formula() {
  _brew_bump_formula_or_cask "$1" "formula"
}

# Bump the selected cask, creating a new pull request.
#
# Input:
# 1. The fully-qualified name of the cask.
#
function brew_bump_cask() {
  _brew_bump_formula_or_cask "$1" "cask"
}

# Obtain the number of the pull request from the current branch.
#
# Output:
# Writes the number of the pull request to stdout.
#
function current_pr_number() {
  gh pr view --json "number" | jq -r ".number"
}

# Retrieve JSON file from the selected formula/cask.
#
# Input:
# 1. The fully-qualified name of the formula/cask.
# 2. Literal string: "formula" or "cask".
#
# Output:
# Writes JSON file to stdout.
#
function _json_from_formula_or_cask() {
  local array_name

  case "$2" in
    cask)
      array_name="casks"
      ;;
    *)
      array_name="formulae"
      ;;
  esac

  brew info "$1" --"$2" --json=v2 | jq -r ".${array_name}[0]"
}

# Retrieve ruby source file from the selected formula/cask.
#
# Input:
# 1. The fully-qualified name of the formula/cask.
# 2. Literal string: "formula" or "cask".
#
# Output:
# Writes ruby source filepath to stdout.
#
function _formula_or_cask_source_file() {
  _json_from_formula_or_cask "$1" "$2" | jq -r ".ruby_source_path"
}

# Retrieve ruby source file from the selected formula.
#
# Input:
# 1. The fully-qualified name of the formula.
#
# Output:
# Writes ruby source filepath to stdout.
#
function formula_source_file() {
  _formula_or_cask_source_file "$1" "formula"
}

# Retrieve ruby source file from the selected cask.
#
# Input:
# 1. The fully-qualified name of the cask.
#
# Output:
# Writes ruby source filepath to stdout.
#
function cask_source_file() {
  _formula_or_cask_source_file "$1" "cask"
}

# Check if the selected formula/cask depends on Linux/MacOS.
#
# Input:
# 1. The fully-qualified name of the formula/cask.
# 2. Literal string: "formula" or "cask".
# 3. Literal string: "linux" or "macos".
#
# Output:
# Write "true" to stdout if depending on Linux/MacOS. "false" otherwise.
#
function _formula_or_cask_depends_on_linux_or_macos() {
  local depends_on
  depends_on="$(_json_from_formula_or_cask "$1" "$2" | jq -r ".depends_on.$3")"

  if [[ "$depends_on" != "null" ]]; then
    echo "true"
  else
    echo "false"
  fi
}

# Check if the selected formula depends on Linux.
#
# Input:
# 1. The fully-qualified name of the formula.
#
# Output:
# Write "true" to stdout if depending on Linux. "false" otherwise.
#
function formula_depends_on_linux() {
  _formula_or_cask_depends_on_linux_or_macos "$1" "formula" "linux"
}

# Check if the selected formula depends on MacOS.
#
# Input:
# 1. The fully-qualified name of the formula.
#
# Output:
# Write "true" to stdout if depending on MacOS. "false" otherwise.
#
function formula_depends_on_macos() {
  _formula_or_cask_depends_on_linux_or_macos "$1" "formula" "macos"
}

# Check if the selected cask depends on Linux.
#
# Input:
# 1. The fully-qualified name of the cask.
#
# Output:
# Write "true" to stdout if depending on Linux. "false" otherwise.
#
function cask_depends_on_linux() {
  _formula_or_cask_depends_on_linux_or_macos "$1" "cask" "linux"
}

# Check if the selected cask depends on MacOS.
#
# Input:
# 1. The fully-qualified name of the cask.
#
# Output:
# Write "true" to stdout if depending on MacOS. "false" otherwise.
#
function cask_depends_on_macos() {
  _formula_or_cask_depends_on_linux_or_macos "$1" "cask" "macos"
}

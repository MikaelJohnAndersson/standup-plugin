#!/usr/bin/env bash
# lib.sh: shared helpers, sourced by the other scripts after they set $data.
config="$data/config.json"

# One config value as jq prints it raw; arrays one item per line
conf() { [ -r "$config" ] && jq -r "$1 // empty | if type == \"array\" then .[] else . end" "$config"; }

expand() { case $1 in "~"|"~/"*) printf '%s' "$HOME${1#\~}" ;; *) printf '%s' "$1" ;; esac; }

# The GitHub owner of a repo's origin, from git@host:owner/repo or https://host/owner/repo
owner() {
  git -C "$1" remote get-url origin 2>/dev/null | sed -E 's#\.git$##; s#.*[:/]([^/]+)/[^/]+$#\1#'
}

# Whether a folder belongs to a repo the config includes: a path in include, or an
# origin owned by one of orgs, and not under a path in exclude
in_scope() {
  local top path o
  top=$(git -C "$1" rev-parse --show-toplevel 2>/dev/null) || return 1
  while IFS= read -r path; do
    path=$(expand "$path"); [ -n "$path" ] || continue
    case $top/ in "${path%/}"/*) return 1 ;; esac
  done < <(conf .exclude)
  while IFS= read -r path; do
    path=$(expand "$path"); [ -n "$path" ] || continue
    case $top/ in "${path%/}"/*) return 0 ;; esac
  done < <(conf .include)
  o=$(owner "$top")
  [ -n "$o" ] && conf .orgs | grep -qixF -- "$o"
}

# Every git repo up to two levels under the config's roots, one path per line
all_repos() {
  local root
  while IFS= read -r root; do
    root=$(expand "$root"); [ -d "$root" ] || continue
    find "$root" -mindepth 1 -maxdepth 3 -name .git -type d -prune 2>/dev/null | sed 's#/\.git$##'
  done < <(conf .roots) | sort -u
}

repos() { local r; all_repos | while IFS= read -r r; do in_scope "$r" && echo "$r"; done; }

# A date shifted by whole days, as YYYY-MM-DD, on BSD or GNU date
day() { date -v"$1"d +%F 2>/dev/null || date -d "$1 days" +%F; }

# The workday before today: Friday on a Monday or weekend
last_workday() {
  case $(date +%u) in 1) day -3 ;; 7) day -2 ;; *) day -1 ;; esac
}

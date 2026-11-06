#!/usr/bin/env bash
# config.sh <data folder> [write <json>]: shows the config and the repos it includes, or
# replaces the config with the given JSON once it parses and has the right shape.
data=$1
. "$(dirname "$0")/lib.sh"

if [ "$2" = write ]; then
  json=$(jq '{
      roots: (.roots // ["~/Documents"]), orgs: (.orgs // []), include: (.include // []),
      exclude: (.exclude // []), authors: (.authors // []),
      linearWorkspace: (.linearWorkspace // null), retentionDays: (.retentionDays // 14)
    }' <<<"$3") || { echo "That isn't valid JSON; the config is unchanged."; exit 1; }
  mkdir -p "$data" && printf '%s\n' "$json" >"$config" && echo "Config saved."
fi

[ -r "$config" ] || { echo "Not set up yet: run /standup:setup."; exit 0; }
echo "Config ($config):"
cat "$config"
echo
echo "Repos included:"
repos | sed 's#^#  #'

#!/usr/bin/env bash
# Headless regression tests for ../init.lua. Neovim never loads this folder.
#
#   tests/run.sh              run every mode
#   tests/run.sh base indent  run only the named modes (see `modes` at the bottom of spec.lua)
#
# Everything runs in a throwaway sandbox (temp XDG dirs, NVIM_APPNAME=nvim-test), so it never touches
# ~/.config, ~/.local or ~/.cache, and spec.lua refuses to run if it is not inside that sandbox.
set -u

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(dirname "$HERE") # the nvim config dir (holds init.lua)
T=$(mktemp -d "${TMPDIR:-/tmp}/nvim-test.XXXXXX")
trap 'rm -rf "$T"' EXIT

bash "$HERE/fixtures.sh" "$T" "$ROOT" || { echo "fixture build failed"; exit 2; }

export NVIM_APPNAME=nvim-test
export XDG_CONFIG_HOME="$T/cfg" XDG_DATA_HOME="$T/data" XDG_STATE_HOME="$T/state" XDG_CACHE_HOME="$T/cache"
export SANDBOX="$T" FX="$T/fx"

MODES=${*:-base rg nohl nohl2 badopts badsection nopack old nowild}
rc=0
for m in $MODES; do
  extra=""
  [ "$m" = rg ] && extra="$FX/bin:" # a fake `rg` first on PATH
  SPEC=$m PATH="$extra$PATH" perl -e 'alarm shift; exec @ARGV' 90 \
    nvim --headless --cmd "luafile $HERE/inject.lua" -c "luafile $HERE/spec.lua" 2>&1 | tail -n 40
  [ "${PIPESTATUS[0]}" -eq 0 ] || rc=1
done

# startup time of the real config, in ms
SPEC=base nvim --headless --startuptime "$T/startup.log" +qa >/dev/null 2>&1
echo "startup: $(grep 'NVIM STARTED' "$T/startup.log" | awk '{print $1}') ms"

[ "$rc" -eq 0 ] && echo "ALL PASSED" || echo "FAILURES"
exit $rc

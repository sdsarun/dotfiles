#!/usr/bin/env bash
# Builds the sandbox dirs and throwaway fixture files for run.sh.  Usage: fixtures.sh <sandbox> <config dir>
set -euo pipefail
S="$1"
ROOT="$2"
mkdir -p "$S"/{cfg,data,state,cache} "$S/fx"
ln -s "$ROOT" "$S/cfg/nvim-test"

# a real git repo: noisy dirs, dotfiles and a gitignored file for :find, and a match for grep
P="$S/fx/proj"
mkdir -p "$P"/{src,node_modules/x,dist,build,coverage,deep/very/nested,.hidden}
printf 'const needle = 1\n' > "$P/src/main.ts"
printf 'module.exports = 1\n' > "$P/node_modules/x/index.js"
printf 'SECRET=1\n' > "$P/.env"
printf 'out\n' > "$P/dist/out.js"
printf 'b\n' > "$P/build/b.js"
printf 'c\n' > "$P/coverage/c.html"
printf 'deep\n' > "$P/deep/very/nested/file.txt"
printf 'h\n' > "$P/.hidden/h.txt"
printf 'needle in secret\n' > "$P/secret.txt"
printf 'secret.txt\n' > "$P/.gitignore"
git -C "$P" init -q
git -C "$P" add -A 2>/dev/null || true

# no repo at all, and a fake .git (git grep fails there, so grep must take over)
mkdir -p "$S/fx/plain" "$S/fx/fakegit/.git"
printf 'needle here\n' > "$S/fx/plain/notes.txt"
printf 'needle fake\n' > "$S/fx/fakegit/a.txt"

# a stand-in rg, to prove it is preferred when present
mkdir -p "$S/fx/bin"
printf '#!/bin/sh\necho "fake.txt:1:1:needle via fake rg"\n' > "$S/fx/bin/rg"
chmod +x "$S/fx/bin/rg"

# indentation fixtures
I="$S/fx/indent"
mkdir -p "$I/ec"
printf 'function a() {\n  if (x) {\n    b();\n  }\n}\nfunction c() {\n  return 1;\n}\n' > "$I/two.js"
printf 'function a() {\n    if (x) {\n        b();\n    }\n}\nfunction c() {\n    return 1;\n}\n' > "$I/four.js"
printf 'function a() {\n\tif (x) {\n\t\tb();\n\t}\n}\nfunction c() {\n\treturn 1;\n}\n' > "$I/tabs.js"
printf 'package main\n\nfunc main() {\n\tif x {\n\t\tb()\n\t}\n}\n\nfunc c() {\n\treturn\n}\n' > "$I/tabs.go"
printf 'package main\n\nfunc main() {\n    if x {\n        b()\n    }\n}\n\nfunc c() {\n    return\n}\n' > "$I/spaces.go"
printf 'a:\n  b:\n    c: 1\n  d: 2\ne:\n  f: 3\n' > "$I/two.yaml"
: > "$I/empty.js"
printf 'a\n\tb\n  c\n\td\n  e\n' > "$I/mixed.js" # as many tab lines as space lines: ambiguous
printf '(function(){' > "$I/minified.js"
head -c 200000 /dev/zero | tr '\0' 'x' >> "$I/minified.js"
printf '})()\n' >> "$I/minified.js"
printf 'root = true\n\n[*.js]\nindent_style = tab\nindent_size = 8\n' > "$I/ec/.editorconfig"
printf 'function a() {\n  if (x) {\n    b();\n  }\n}\n' > "$I/ec/a.js"
printf '# T\n\ntext\n' > "$I/doc.md"
printf -- '-- lua\nlocal x = 1\n' > "$I/a.lua"

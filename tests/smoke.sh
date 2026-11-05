#!/usr/bin/env sh
set -eu

repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# Fake rex: logs each call on one line (newlines as |), answers split with a
# block ID, and fails one send if $REX_DEAD exists, like a closed pane.
cat > "$tmp/rex" <<'EOF'
#!/usr/bin/env sh
printf '%s' "$*" | tr '\n' '|' >> "$REX_LOG"; echo >> "$REX_LOG"
if [ "$3" = send ] && [ -f "$REX_DEAD" ]; then
  rm "$REX_DEAD"
  exit 3
fi
if [ "$3" = split ]; then
  printf '%s\n' '{' '  "anchor_id": "block:editor",' '  "block_ids": [' '    "block:runner"' '  ],' '  "revision": 2' '}'
fi
EOF
chmod +x "$tmp/rex"

check() {
  editor=$1
  mode=--headless
  [ "$editor" = vim ] && mode=-es
  : > "$tmp/log"
  REX_SESSION=session:test REX_BLOCK=block:editor REX_LOG="$tmp/log" REX_DEAD="$tmp/dead" PATH="$tmp:$PATH" "$editor" --clean "$mode" --cmd "set rtp^=$repo" \
    '+runtime plugin/vim-test-rex.vim' \
    '+call assert_equal(1, exists("*RexStrategy")) | call assert_equal(2, exists(":RexCloseRunner")) | call assert_true(has_key(g:test#custom_strategies, "rex"))' \
    '+call call(g:test#custom_strategies.rex, ["true"]) | call call(g:test#custom_strategies.rex, ["true"])' \
    '+call writefile([], $REX_DEAD) | let g:test#preserve_screen = 0 | call call(g:test#custom_strategies.rex, ["true"]) | RexCloseRunner' \
    '+if len(v:errors) | cquit | endif' +qa
  # split, send; send; failed send, split, send with clear; close
  test "$(wc -l < "$tmp/log" | tr -d ' ')" = 7
  test "$(grep -c '^-s session:test split -b block:editor --split=below' "$tmp/log")" = 2
  test "$(grep -c '^-s session:test send -b block:runner true|$' "$tmp/log")" = 2
  test "$(grep -c '^-s session:test send -b block:runner clear|true|$' "$tmp/log")" = 2
  grep -q '^-s session:test block close block:runner$' "$tmp/log"
}

check nvim
check vim
echo ok

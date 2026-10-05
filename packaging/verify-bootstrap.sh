#!/usr/bin/env bash
#
# 부트스트랩 zip 확인 — 경로가 정말 우리 것인지(1판 교훈), 빼기로 한 패키지가 빠졌는지(DEC-014·016).
#
#   사용법: packaging/verify-bootstrap.sh <bootstrap zip>
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/jc-packages.conf"
zip="${1:?부트스트랩 zip}"
x="$(mktemp -d)"; trap 'rm -rf "$x" "$x.strings"' EXIT
unzip -q "$zip" -d "$x"
fail() { echo "::error::$*"; exit 1; }
# strings 를 파일로 — 파이프에 grep -q 를 물리면 pipefail 에서 SIGPIPE 가 실패로 보인다
strings "$x/bin/bash" > "$x.strings"
grep -q '/data/data/com.termux/' "$x.strings" && fail "bash 에 com.termux 경로가 남았습니다"
grep -qF "$JC_PREFIX" "$x.strings" || fail "bash 에 우리 경로가 없습니다"
left=$(grep -rIl '/data/data/com\.termux/' "$x" | while read -r f; do
	grep -vE '^[[:space:]]*(#|//|\*|/\*)' "$f" | grep -q '/data/data/com\.termux/' && echo "${f#"$x"/}"; done || true)
[ -z "$left" ] || fail "com.termux 경로가 남은 파일: $left"
pkgs="$(awk '/^Package: /{print $2}' "$x/var/lib/dpkg/status")"
for p in $JC_BOOTSTRAP_EXCLUDE; do
	grep -qx "$p" <<< "$pkgs" && fail "부트스트랩에 빼기로 한 $p 가 있습니다"
done
for p in $JC_BOOTSTRAP_EXTRA; do
	grep -qx "$p" <<< "$pkgs" || fail "부트스트랩에 $p 가 없습니다"
done
echo "[*] 부트스트랩 확인 완료 — 패키지 $(wc -l <<< "$pkgs")개"

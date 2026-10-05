#!/usr/bin/env bash
#
# 패키지들의 소스 묶음(src-<레시피>-<판>.tar)을 릴리스 `sources` 에 판별로 쌓는다 — 이미 있는 것은 건너뛴다
# (jc-terminal-v2 DEC-002, V2-PKG-04). GH_TOKEN 필요.
#
#   사용법: packaging/upload-sources.sh <termux-packages 경로> <패키지 …>
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
tp="${1:?termux-packages 경로}"; shift
tag=sources
if ! gh release view "$tag" >/dev/null 2>&1; then
	gh release create "$tag" --title "Sources — 패키지 원본 소스·레시피·패치" --notes "JC Terminal V2 패키지의 원본 소스와 termux-packages 레시피·패치를 레시피·판별로 둡니다 (\`src-<레시피>-<판>.tar\`). 옛 판도 지우지 않습니다. 빌드 스크립트: 이 저장소의 \`packaging/\`, termux-packages 고정 판은 \`packaging/jc-packages.conf\` 의 \`JC_TERMUX_PACKAGES_REF\`."
fi
existing="$(mktemp)"; out="$(mktemp -d)"
trap 'rm -rf "$existing" "$out"' EXIT
gh release view "$tag" --json assets --jq '.assets[].name' > "$existing"
"$here/fetch-sources.sh" "$tp" "$out" "$existing" "$@"
shopt -s nullglob
files=("$out"/*.tar)
if [ ${#files[@]} -eq 0 ]; then echo "[*] 새로 올릴 소스가 없습니다"; exit 0; fi
gh release upload "$tag" "${files[@]}"
echo "[*] 소스 ${#files[@]}개를 릴리스 $tag 에 올렸습니다"

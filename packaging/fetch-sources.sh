#!/usr/bin/env bash
#
# GPL 등 소스 제공 (jc-terminal-v2 DEC-002, V2-PKG-04) — 패키지마다 그 판의 원본 소스와 레시피·패치를 묶는다.
#
#   사용법: packaging/fetch-sources.sh <termux-packages 경로> <내보낼 폴더> <이미 있는 목록 파일|-> <패키지 …>
#
# 레시피마다 src-<레시피>-<판>.tar 하나: 레시피 폴더(build.sh·패치) + TERMUX_PKG_SRCURL 의 원본(받은 그대로).
# 이미 있는 목록(파일 이름 한 줄씩)에 있는 것은 건너뛴다 — 릴리스 `sources` 에 판별로 쌓는다.
# 원본이 git 저장소(git+https)인 레시피는 주소·커밋이 build.sh 에 있으므로 레시피만 묶고 SOURCE-URL 파일에 적는다.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/recipes.sh"

tp="$(cd "${1:?termux-packages 경로}" && pwd)"; out="${2:?내보낼 폴더}"; existing="${3:?이미 있는 목록 파일 또는 -}"; shift 3
mkdir -p "$out"; out="$(cd "$out" && pwd)"
declare -A skip=()
if [ "$existing" != "-" ] && [ -f "$existing" ]; then
	while read -r f; do [ -n "$f" ] && skip["$f"]=1; done < "$existing"
fi

declare -A seen=()
work="$(mktemp -d)"; trap 'rm -rf "$work"' EXIT
for pkg in "$@"; do
	dir="$(jc_recipe_dir "$tp" "$pkg")" || { echo "[!] 레시피 없음: $pkg — 건너뜀" >&2; continue; }
	recipe="$(basename "$dir")"
	[ -n "${seen[$recipe]:-}" ] && continue
	seen["$recipe"]=1
	ver="$(jc_recipe_version "$tp" "$dir")"
	[ -n "$ver" ] || { echo "[!] $recipe 의 판을 알아내지 못했습니다" >&2; exit 1; }
	name="src-$recipe-${ver//[:\/]/_}.tar"
	[ -n "${skip[$name]:-}" ] && { echo "[ ] $name 있음" >&2; continue; }

	urls="$(cd "$tp" && bash -c 'set +eu; export TERMUX_ARCH=aarch64; . scripts/properties.sh >/dev/null 2>&1; . "$1/build.sh" >/dev/null 2>&1; for u in "${TERMUX_PKG_SRCURL[@]}"; do echo "$u"; done' _ "$dir")"
	stage="$work/$recipe"; rm -rf "$stage"; mkdir -p "$stage/upstream"
	cp -a "$dir" "$stage/recipe"
	printf '%s\n' "$urls" > "$stage/SOURCE-URL"
	ok=true
	while read -r u; do
		[ -z "$u" ] && continue
		case "$u" in
			git+*) continue ;;  # 주소·커밋은 레시피에
		esac
		f="$stage/upstream/$(basename "${u%%\?*}")"
		curl -fsSL --retry 3 -o "$f" "$u" || { echo "[!] 받지 못함: $recipe $u" >&2; ok=false; }
	done <<< "$urls"
	$ok || { echo "[!] $recipe 원본을 다 받지 못해 묶지 않습니다 — 다음 실행에서 다시" >&2; continue; }
	tar -C "$stage" -cf "$out/$name" .
	echo "[*] $name ($(du -h "$out/$name" | cut -f1))" >&2
done

#!/usr/bin/env bash
#
# 구울 레시피를 고른다 — 우리 apt 저장소에 같은 판이 이미 있으면 건너뛴다 (DEC-015: 바뀐 것만 다시 굽기).
#
#   사용법: packaging/plan-builds.sh <termux-packages 경로> <Packages 파일> [--force] <패키지 …>
#
# 패키지 이름(하위 패키지 포함)을 레시피로 바꾸고, 레시피의 판이 Packages 의 판과 다르거나 없으면 출력한다.
# --force 면 모두 출력한다. 한 줄에 레시피 하나.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/recipes.sh"

tp="${1:?termux-packages 경로}"; packages_file="${2:?Packages 파일}"; shift 2
force=false
[ "${1:-}" = "--force" ] && { force=true; shift; }

declare -A have=()
if [ -f "$packages_file" ]; then
	while read -r name ver; do have["$name"]="$ver"; done < <(
		awk '/^Package: /{p=$2} /^Version: /{print p, $2}' "$packages_file")
fi

declare -A seen=()
for pkg in "$@"; do
	dir="$(jc_recipe_dir "$tp" "$pkg")" || { echo "[!] 레시피를 찾지 못했습니다: $pkg" >&2; exit 1; }
	recipe="$(basename "$dir")"
	[ -n "${seen[$recipe]:-}" ] && continue
	seen["$recipe"]=1
	want="$(jc_recipe_version "$tp" "$dir")"
	[ -n "$want" ] || { echo "[!] $recipe 의 판을 알아내지 못했습니다" >&2; exit 1; }
	got="${have[$recipe]:-}"
	if $force || [ "$want" != "$got" ]; then
		echo "[*] $recipe: 저장소 ${got:-없음} → $want" >&2
		echo "$recipe"
	else
		echo "[ ] $recipe: $want 그대로" >&2
	fi
done

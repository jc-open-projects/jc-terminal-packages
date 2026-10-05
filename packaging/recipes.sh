#!/usr/bin/env bash
#
# 레시피 도우미 — 다른 packaging/*.sh 가 source 한다 (bash 4 이상).
#
#   jc_recipe_dir <tp> <패키지>   패키지(하위 패키지 포함)를 굽는 레시피 폴더
#   jc_recipe_version <tp> <폴더>  레시피가 만드는 데비안 판 (VERSION[-REVISION])

jc_recipe_dir() {
	local tp="$1" name="$2" d f
	name="${name%-static}"   # -static 은 레시피가 저절로 나누는 하위 패키지
	for d in packages root-packages x11-packages; do
		[ -f "$tp/$d/$name/build.sh" ] && { echo "$tp/$d/$name"; return 0; }
	done
	for f in "$tp"/packages/*/"$name".subpackage.sh "$tp"/root-packages/*/"$name".subpackage.sh "$tp"/x11-packages/*/"$name".subpackage.sh; do
		[ -f "$f" ] && { dirname "$f"; return 0; }
	done
	return 1
}

jc_recipe_version() {
	local tp dir
	tp="$(cd "$1" && pwd)"; dir="$(cd "$2" && pwd)"   # 아래에서 cd 하므로 절대 경로로
	(
		cd "$tp" || exit 1
		set +eu
		export TERMUX_ARCH=aarch64
		. scripts/properties.sh >/dev/null 2>&1
		. scripts/build/termux_extract_dep_info.sh
		termux_extract_dep_info "$(basename "$dir")" "$dir" | cut -d' ' -f2
	)
}

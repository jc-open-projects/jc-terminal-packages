#!/usr/bin/env bash
#
# termux-packages 를 고정 판(JC_TERMUX_PACKAGES_REF)으로 받고 우리 패치를 건다 (DEC-013).
#
#   사용법: packaging/checkout-termux-packages.sh <받을 폴더>
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/jc-packages.conf"
tp="${1:?받을 폴더}"
if [ ! -d "$tp/.git" ]; then
	git init -q "$tp"
	git -C "$tp" remote add origin "$JC_TERMUX_PACKAGES_REPO"
fi
git -C "$tp" fetch -q --depth 1 origin "$JC_TERMUX_PACKAGES_REF"
git -C "$tp" checkout -q -f FETCH_HEAD
git -C "$tp" clean -q -fdx -e output/
echo "[*] termux-packages $(git -C "$tp" rev-parse HEAD)"
"$here/patch-termux-packages.sh" "$tp"

#!/usr/bin/env bash
#
# termux-packages 체크아웃을 JC Terminal V2 경로로 바꾼다 (jc-terminal-v2 docs/03 §6.1, DEC-013).
# JC Terminal 1판(jc-terminal-android) packaging/patch-termux-packages.sh 를 바탕으로 했다 (우리가 쓴 스크립트).
#
#   사용법: packaging/patch-termux-packages.sh <termux-packages 경로>
#
# 1. scripts/properties.sh 의 TERMUX_APP__PACKAGE_NAME 한 줄 — 여기서 $PREFIX·$HOME 이 파생된다.
#    TERMUX__INTERNAL_NAME("termux")은 그대로 둔다 (~/.termux·termux-* 명령 이름).
# 2. 경로 변수를 export 한다 — termux-tools 등의 configure 가 환경 변수가 있을 때만 쓰고 없으면
#    com.termux 로 굽는다 (1판에서 login·pkg 에 com.termux 가 박혔던 원인).
# 3. termux-am 의 BuildConfig 앱 이름.
# 4. termux-keyring 에 우리 저장소 공개 키를 더한다 — apt 가 우리 서명을 믿게 (DEC-012).
# 5. repo.json 을 우리 저장소로 — 의존성을 우리 deb 에서 받는다 (-i, DEC-015).
# 6. build-package.sh 가 의존성 저장소 서명을 우리 키로 확인하게.
# 7. termux-tools 의 의존에서 termux-am-socket 을 뺀다 (DEC-016).
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/.." && pwd)"
# shellcheck source=packaging/jc-packages.conf
. "$here/jc-packages.conf"

tp="${1:?termux-packages 경로를 인자로 주세요}"
props="$tp/scripts/properties.sh"
[ -f "$props" ] || { echo "[!] $props 가 없습니다 — termux-packages 체크아웃 경로가 맞나요?" >&2; exit 1; }

# 1
before='TERMUX_APP__PACKAGE_NAME="com.termux"'
after="TERMUX_APP__PACKAGE_NAME=\"$JC_APP_PACKAGE_NAME\""
if grep -qF "$after" "$props"; then
	echo "[*] 이미 패치되어 있습니다: $after"
else
	grep -qF "$before" "$props" || {
		echo "[!] '$before' 를 찾지 못했습니다. upstream 이 바뀐 것 같습니다 — 패치를 다시 맞춰야 합니다." >&2
		exit 1
	}
	perl -pi -e "s/\Q$before\E/$after/" "$props"
	echo "[*] 패치 완료: $after"
fi

# 2
if ! grep -q "JC Terminal: 경로 변수를 내보낸다" "$props"; then
	cat >> "$props" <<'EOF'

# JC Terminal: 경로 변수를 내보낸다 (packaging/patch-termux-packages.sh)
export TERMUX_APP_PACKAGE="$TERMUX_APP__PACKAGE_NAME"
export TERMUX_BASE_DIR TERMUX_PREFIX TERMUX_ANDROID_HOME TERMUX_CACHE_DIR
EOF
	echo "[*] 경로 변수 export 를 properties.sh 끝에 붙였습니다"
fi

# 3
am_build="$tp/packages/termux-am/build.sh"
if [ -f "$am_build" ] && ! grep -q "JC Terminal" "$am_build"; then
	cat >> "$am_build" <<'EOF'

# JC Terminal: BuildConfig 의 앱 이름을 우리 것으로
termux_step_pre_configure() {
	# buildConfigField 줄에서만 바꾼다. applicationId "com.termux.termuxam" 은 그 앱 자신의 id 라 그대로 둔다
	sed -i'' -E \
		-e "/buildConfigField.*TERMUX_PACKAGE_NAME/ s|com\\.termux|${TERMUX_APP__PACKAGE_NAME}|" \
		"$TERMUX_PKG_SRCDIR/app/build.gradle"
	grep -n "TERMUX_PACKAGE_NAME" "$TERMUX_PKG_SRCDIR/app/build.gradle"
}
EOF
	echo "[*] termux-am 의 앱 이름을 $JC_APP_PACKAGE_NAME 로 바꾸는 단계를 추가했습니다"
fi

# 4
kr="$tp/packages/termux-keyring"
if [ -d "$kr" ] && ! grep -q "jc-terminal-packages.gpg" "$kr/build.sh"; then
	gpg --batch --yes --dearmor -o "$kr/jc-terminal-packages.gpg" "$root/$JC_KEY_FILE"
	perl -0pi -e 's|(\tinstall -Dm600 "\$TERMUX_PKG_BUILDER_DIR/termux-autobuilds.gpg" "\$GPG_SHARE_DIR"\n)|$1\n\t# JC Terminal 패키지 저장소 키 (jc-terminal-packages)\n\tinstall -Dm600 "\$TERMUX_PKG_BUILDER_DIR/jc-terminal-packages.gpg" "\$GPG_SHARE_DIR"\n|' "$kr/build.sh"
	grep -q 'jc-terminal-packages.gpg' "$kr/build.sh" || { echo "[!] termux-keyring 에 키를 넣지 못했습니다 — 레시피가 바뀐 것 같습니다" >&2; exit 1; }
	echo "[*] termux-keyring 에 우리 공개 키를 더했습니다"
fi

# 5. 의존성을 받을 저장소를 우리 apt 저장소로 (build-package.sh -i) — 공식 deb 는 com.termux 경로라 섞으면 안 된다.
#    키(packages, x11-packages …)는 레시피 폴더 이름이라 그대로 두고 주소만 바꾼다 (DEC-015).
rj="$tp/repo.json"
if [ -f "$rj" ] && ! grep -qF "$JC_REPO_URL" "$rj"; then
	jq --arg url "$JC_REPO_URL" 'reduce (del(.pkg_format) | keys[]) as $k (.; .[$k] |= (.url = $url | .distribution = "stable" | .component = "main"))' "$rj" > "$rj.new"
	mv "$rj.new" "$rj"
	echo "[*] repo.json 을 우리 저장소로 바꿨습니다"
fi
# 저장소가 어느 앱 경로로 구운 것인지 (TERMUX_REPO_*) — 우리 앱과 같아야 -i 가 받는다. 다르면 -i 를 무시하고 다 굽는다
if grep -q '^TERMUX_REPO_APP__PACKAGE_NAME="com.termux"' "$props"; then
	perl -pi -e 's|^(TERMUX_REPO_\w+=")(/data/data/)?com\.termux|$1$2'"$JC_APP_PACKAGE_NAME"'|' "$props"
	grep -q "^TERMUX_REPO_APP__PACKAGE_NAME=\"$JC_APP_PACKAGE_NAME\"" "$props" || { echo "[!] TERMUX_REPO_* 를 바꾸지 못했습니다" >&2; exit 1; }
	echo "[*] TERMUX_REPO_* 를 $JC_APP_PACKAGE_NAME 로 바꿨습니다"
fi

# 6. 의존성 저장소의 서명을 우리 키로 확인한다 — build-package.sh 는 Termux 키만 가져온다
bp="$tp/build-package.sh"
if ! grep -q "JC Terminal: 우리 저장소 키" "$bp"; then
	perl -0pi -e 's|(\t# Setup PGP keys for verifying integrity of dependencies\.\n)|$1\t# JC Terminal: 우리 저장소 키 (packaging/patch-termux-packages.sh)\n\tgpg --list-keys 5F52ACE481978987DE01FDA25123A9A806CBC3F5 > /dev/null 2>&1 \|\| {\n\t\tgpg --import "\$TERMUX_SCRIPTDIR/packages/termux-keyring/jc-terminal-packages.gpg"\n\t\tgpg --no-tty --command-file <(echo -e "trust\\n5\\ny") --edit-key 5F52ACE481978987DE01FDA25123A9A806CBC3F5\n\t}\n|' "$bp"
	grep -q "JC Terminal: 우리 저장소 키" "$bp" || { echo "[!] build-package.sh 에 키 가져오기를 넣지 못했습니다 — 스크립트가 바뀐 것 같습니다" >&2; exit 1; }
	echo "[*] 의존성 확인에 우리 키를 더했습니다"
fi

# 7. termux-tools 가 termux-am-socket 을 요구하지 않게 (DEC-016) — 그 소켓 서버는 Termux 앱에만 있다.
#    판(REVISION)을 하나 올려 이미 설치된 기기도 `pkg upgrade` 로 바뀐 의존을 받는다.
tt="$tp/packages/termux-tools/build.sh"
if [ -f "$tt" ] && ! grep -q "JC Terminal: termux-am-socket 뺌" "$tt"; then
	grep -q 'termux-am-socket' "$tt" || { echo "[!] termux-tools 의 의존에 termux-am-socket 이 없습니다 — 레시피가 바뀌었으면 이 단계를 맞춰야 합니다" >&2; exit 1; }
	perl -pi -e 's/,\s*termux-am-socket(\s*\([^)]*\))?//' "$tt"
	rev="$(sed -n 's/^TERMUX_PKG_REVISION=//p' "$tt")"
	if [ -n "$rev" ]; then
		perl -pi -e "s/^TERMUX_PKG_REVISION=.*/TERMUX_PKG_REVISION=$((rev + JC_TERMUX_TOOLS_REVISION_BUMP))/" "$tt"
	else
		perl -pi -e 's/^(TERMUX_PKG_VERSION=.*)$/$1\nTERMUX_PKG_REVISION='"$JC_TERMUX_TOOLS_REVISION_BUMP"'/' "$tt"
	fi
	# 미러는 우리 저장소 하나만 — 공식 미러 목록을 빼고 mirror-default 를 conffile 로 싣는다
	cp "$here/mirror-default" "$(dirname "$tt")/jc-mirror-default"
	cat >> "$tt" <<'EOF'
# JC Terminal: termux-am-socket 뺌 (packaging/patch-termux-packages.sh, DEC-016)
# JC Terminal: 미러는 우리 저장소 하나만 — 위의 termux_step_post_make_install 을 대신한다
termux_step_post_make_install() {
	local m="$TERMUX_PREFIX/etc/termux/mirrors" conf
	rm -rf "$m"
	install -Dm644 "$TERMUX_PKG_BUILDER_DIR/jc-mirror-default" "$m/default"
	conf="$(cat "$TERMUX_PKG_BUILDDIR/conffiles")"
	TERMUX_PKG_CONFFILES="$(printf '%s\n' "$conf" | grep -v 'termux/mirrors/'; printf '%s\n' "$conf" | grep 'termux/mirrors/default$')"
}
EOF
	grep -q 'termux-am-socket' <(grep '^TERMUX_PKG_DEPENDS' "$tt") && { echo "[!] termux-tools 의존에서 termux-am-socket 을 빼지 못했습니다" >&2; exit 1; }
	echo "[*] termux-tools 의존에서 termux-am-socket 을 뺐습니다 (REVISION $(sed -n 's/^TERMUX_PKG_REVISION=//p' "$tt"))"
fi

# 패치가 실제로 경로에 반영되는지 확인한다 (bash 4 이상 — properties.sh 가 연관 배열을 쓴다)
bash_major="$(bash -c 'echo ${BASH_VERSINFO[0]}')"
if [ "${bash_major:-0}" -lt 4 ]; then
	echo "[*] bash $bash_major — prefix 확인은 건너뜁니다"
	exit 0
fi
prefix="$(cd "$tp" && bash -c '. scripts/properties.sh >/dev/null 2>&1; echo "$TERMUX__PREFIX"')"
if [ "$prefix" != "$JC_PREFIX" ]; then
	echo "[!] prefix 가 기대와 다릅니다: '$prefix' (기대: '$JC_PREFIX')" >&2
	exit 1
fi
echo "[*] prefix 확인: $prefix"

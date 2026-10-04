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

# 5. 도구 모음을 fuse-overlayfs 로 겹치지 않고 처음 한 번 복사한다 — 러너 컨테이너에 /dev/fuse·SYS_ADMIN 을
#    주지 않기 위해서 (공개 저장소의 러너, runner/README.md). 디스크를 몇 GB 더 쓴다.
tc="$tp/scripts/build/toolchain/termux_setup_toolchain_30.sh"
if [ -f "$tc" ] && grep -q 'fuse-overlayfs' "$tc" && ! grep -q 'JC Terminal: overlay 대신 복사' "$tc"; then
	perl -0pi -e 's|\tif ! mountpoint -q "\$\{TERMUX_STANDALONE_TOOLCHAIN\}"; then\n\t\tfuse-overlayfs \\\n.*?\n\tfi\n|\t# JC Terminal: overlay 대신 복사 (packaging/patch-termux-packages.sh)\n\tif [ ! -f "\${TERMUX_STANDALONE_TOOLCHAIN}/.jc-copied" ]; then\n\t\tcp -a "\${NDK}/toolchains/llvm/prebuilt/linux-x86_64/." "\${TERMUX_STANDALONE_TOOLCHAIN}/"\n\t\ttouch "\${TERMUX_STANDALONE_TOOLCHAIN}/.jc-copied"\n\tfi\n|s' "$tc"
	grep -q 'JC Terminal: overlay 대신 복사' "$tc" || { echo "[!] 도구 모음 overlay 를 바꾸지 못했습니다 — 스크립트가 바뀐 것 같습니다" >&2; exit 1; }
	echo "[*] 도구 모음을 overlay 대신 복사하게 바꿨습니다"
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

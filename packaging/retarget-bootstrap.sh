#!/usr/bin/env bash
#
# 부트스트랩 zip 의 apt 저장소를 우리 저장소로 돌린다 (jc-terminal-v2 docs/03 §6.1).
# JC Terminal 1판 packaging/retarget-bootstrap.sh 를 바탕으로 했다 (우리가 쓴 스크립트).
#
#   사용법: packaging/retarget-bootstrap.sh <bootstrap-*.zip>
#
# 저장소 주소는 termux-tools 패키지가 들고 있어(미러 목록·sources.list) 그대로 두면 공식 Termux 저장소를
# 가리킨다 — 그 패키지는 /data/data/com.termux 경로로 구워져 우리 앱에서 쓸 수 없다.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=packaging/jc-packages.conf
. "$here/jc-packages.conf"

zip_path="$(cd "$(dirname "${1:?부트스트랩 zip 경로를 주세요}")" && pwd)/$(basename "$1")"
[ -f "$zip_path" ] || { echo "[!] $zip_path 가 없습니다" >&2; exit 1; }

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
unzip -q "$zip_path" -d "$work"

# 1) 미러 목록: 공식 미러를 지우고 우리 것 하나만
mirrors="$work/etc/termux/mirrors"
if [ -d "$mirrors" ]; then
	find "$mirrors" -mindepth 1 -maxdepth 1 ! -name default -exec rm -rf {} +
else
	mkdir -p "$mirrors"
fi
cat > "$mirrors/default" <<EOF
# This file is sourced by pkg
# JC Terminal 패키지 저장소 (jc-open-projects/jc-terminal-packages). 공식 Termux 저장소는 경로가 달라 쓸 수 없다.
WEIGHT=10
MAIN="$JC_REPO_URL"
EOF

# 2) apt 가 바로 보는 주소 — 서명된 저장소 (InRelease). 우리 키는 termux-keyring 이 trusted.gpg.d 에 둔다
mkdir -p "$work/etc/apt"
echo "deb $JC_REPO_URL stable main" > "$work/etc/apt/sources.list"
rm -rf "$work/etc/apt/sources.list.d"
rm -rf "$work/etc/termux/chosen_mirrors"
# pkg 가 "미러 하나 고름" 으로 보게 — 없으면 지운 지역 폴더(asia·europe…)를 find 하다 오류를 낸다
# (부트스트랩 zip 은 심볼릭 링크를 SYMLINKS.txt 에 "대상←경로" 로 적는다)
grep -v '←\./etc/termux/chosen_mirrors$' "$work/SYMLINKS.txt" > "$work/SYMLINKS.new" || true
printf '%s\n' 'mirrors/default←./etc/termux/chosen_mirrors' >> "$work/SYMLINKS.new"
mv "$work/SYMLINKS.new" "$work/SYMLINKS.txt"

# 3) 명령 기록을 명령마다 바로 저장한다 — 앱이 세션을 되살리는 일이 잦아 셸이 정상 종료하지 못할 때가 많다
mkdir -p "$work/etc/profile.d"
cat > "$work/etc/profile.d/jc-history.sh" <<'EOF'
# JC Terminal: 명령 기록을 바로 저장하고 세션끼리 합친다 (packaging/retarget-bootstrap.sh)
if [ -n "$BASH_VERSION" ]; then
	shopt -s histappend
	HISTSIZE=${HISTSIZE:-5000}
	HISTFILESIZE=${HISTFILESIZE:-20000}
	case ";$PROMPT_COMMAND;" in
		*";history -a;"*) ;;
		*) PROMPT_COMMAND="history -a${PROMPT_COMMAND:+;$PROMPT_COMMAND}" ;;
	esac
fi
EOF

# 4) 우리 키가 실제로 들어 있는지 확인한다 (termux-keyring 패치가 빠지면 apt 가 저장소를 거부한다)
[ -f "$work/share/termux-keyring/jc-terminal-packages.gpg" ] || {
	echo "[!] 부트스트랩에 우리 저장소 키가 없습니다 (termux-keyring 패치 확인)" >&2; exit 1; }

# 5) 다시 묶는다
rm -f "$zip_path"
(cd "$work" && zip -qr9 -X "$zip_path" ./*)
echo "[*] 저장소를 $JC_REPO_URL 로 돌렸습니다: $(basename "$zip_path")"
unzip -p "$zip_path" etc/apt/sources.list

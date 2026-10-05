#!/usr/bin/env bash
#
# 서명 키(Actions 시크릿 KEY·PASS)를 잡 전용 GNUPGHOME 에 들인다 (DEC-012). 잡 끝에 "$RUNNER_TEMP/gnupg" 를 지운다.
set -euo pipefail
: "${KEY:?KEY 시크릿}" "${PASS:?PASS 시크릿}" "${RUNNER_TEMP:?}"
export GNUPGHOME="$RUNNER_TEMP/gnupg"
mkdir -m 700 -p "$GNUPGHOME"
echo "GNUPGHOME=$GNUPGHOME" >> "$GITHUB_ENV"
printf '%s\n' "$KEY" | gpg --batch --quiet --import
printf '%s' "$PASS" > "$GNUPGHOME/pass"
chmod 600 "$GNUPGHOME/pass"
gpg --batch --list-secret-keys --keyid-format long | grep -m1 sec

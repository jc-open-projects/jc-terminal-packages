#!/usr/bin/env bash
#
# 빌드 컨테이너 안에서 돈다 — termux-am 은 안드로이드 앱이라 platform-33·build-tools 30.0.3 이 필요하다
# (JC Terminal 1판 2026-09-20). 이미지의 SDK 를 링크하고 빠진 두 가지만 받는다. ANDROID_HOME 으로 쓴다.
#
#   사용법 (컨테이너 안): packaging/prep-android-sdk.sh <만들 폴더>
set -euo pipefail
dst="${1:?만들 폴더}"
src="$(ls -d "$HOME"/lib/android-sdk-* | head -1)"
mkdir -p "$dst/platforms" "$dst/build-tools"
for d in "$src"/*; do b="$(basename "$d")"; case "$b" in platforms|build-tools) ;; *) ln -sfn "$d" "$dst/$b" ;; esac; done
for d in "$src"/platforms/*; do ln -sfn "$d" "$dst/platforms/$(basename "$d")"; done
for d in "$src"/build-tools/*; do ln -sfn "$d" "$dst/build-tools/$(basename "$d")"; done
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
if [ ! -d "$dst/platforms/android-33" ]; then
	curl -fsSL -o "$tmp/p33.zip" https://dl.google.com/android/repository/platform-33_r02.zip
	mkdir -p "$tmp/p33" && unzip -q "$tmp/p33.zip" -d "$tmp/p33"
	mv "$(ls -d "$tmp"/p33/*/ | head -1)" "$dst/platforms/android-33"
fi
if [ ! -d "$dst/build-tools/30.0.3" ]; then
	curl -fsSL -o "$tmp/bt.zip" https://dl.google.com/android/repository/build-tools_r30.0.3-linux.zip
	mkdir -p "$tmp/bt" && unzip -q "$tmp/bt.zip" -d "$tmp/bt"
	mv "$(ls -d "$tmp"/bt/*/ | head -1)" "$dst/build-tools/30.0.3"
fi
echo "[*] 안드로이드 SDK: $dst"

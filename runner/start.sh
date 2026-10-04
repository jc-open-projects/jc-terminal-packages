#!/usr/bin/env bash
# 패키지 빌드 러너를 (다시) 띄운다 — runner/README.md. 맥에서 돌린다 (gh 로그인·colima 필요).
set -euo pipefail
cd "$(dirname "$0")"
docker build --platform linux/amd64 -q -t jc-pkg-runner . >/dev/null
docker rm -f jc-pkg-runner >/dev/null 2>&1 || true
# 등록 토큰(한 시간짜리)은 화면에 찍지 않는다. 이미 등록된 볼륨이면 쓰이지 않는다
TOKEN="$(gh api -X POST orgs/jc-open-projects/actions/runners/registration-token --jq .token)"
docker run -d --name jc-pkg-runner --restart always --platform linux/amd64 \
	-e RUNNER_URL=https://github.com/jc-open-projects -e RUNNER_TOKEN="$TOKEN" \
	-e RUNNER_NAME=macbook-linux -e RUNNER_LABELS=jc-pkg-builder \
	-v jc-pkg-runner:/opt/actions-runner \
	-v jc-pkg-work:/home/builder/_work \
	-v jc-pkg-build:/home/builder/.termux-build \
	-v jc-pkg-data:/data \
	-v jc-pkg-tp:/home/builder/termux-packages \
	jc-pkg-runner >/dev/null
echo "jc-pkg-runner 를 띄웠습니다"

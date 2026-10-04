#!/usr/bin/env bash
# 러너 시작 — 처음이면 등록하고, 아니면 저장된 설정으로 바로 돈다.
# 등록 설정(.runner·.credentials)은 /opt/actions-runner 볼륨에 남는다.
set -euo pipefail
cd /opt/actions-runner
if [ ! -f .runner ]; then
	: "${RUNNER_URL:?RUNNER_URL 이 필요합니다}" "${RUNNER_TOKEN:?RUNNER_TOKEN(등록 토큰)이 필요합니다}"
	./config.sh --unattended --replace \
		--url "$RUNNER_URL" --token "$RUNNER_TOKEN" \
		--name "${RUNNER_NAME:-macbook-linux}" \
		--labels "${RUNNER_LABELS:-jc-pkg-builder}" \
		--work /home/builder/_work
fi
# 빌드는 /data/data/<앱>/files/usr 에 설치하며 굽는다 — 볼륨이라 소유자를 맞춘다
sudo chown builder:builder /data /home/builder/.termux-build 2>/dev/null || true
exec ./run.sh

# 패키지 빌드 러너 (jc-terminal-v2 DEC-011) — termux 공식 빌드 이미지(x86_64)에 GitHub Actions 러너를 얹는다.
# 빌드가 이 컨테이너 안에서 바로 돈다 — 도커 소켓을 러너에 넘기지 않는다 (공개 저장소의 러너).
# ARM 맥의 colima(Rosetta)에서 x86_64 로 돈다. 띄우는 법: runner/README.md
# Rosetta 우회: Ubuntu 26.04 의 GNU tar 는 파일을 열 때 Rosetta 가 모르는 시스템 호출을 써서 풀기가
# "Function not implemented" 로 실패한다 (2026-10-05 확인). 같은 1.35 판인 Ubuntu 24.04 의 tar 는 된다 — 그것으로 바꾼다.
FROM --platform=linux/amd64 ubuntu:24.04 AS tar2404

FROM --platform=linux/amd64 ghcr.io/termux/package-builder:latest

ARG RUNNER_VERSION=2.337.0
ARG GH_VERSION=2.102.0

USER root
COPY --from=tar2404 /usr/bin/tar /usr/bin/tar
RUN set -eux; \
    mkdir -p /opt/actions-runner; cd /opt/actions-runner; \
    curl -fsSL -o runner.tgz "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"; \
    tar xzf runner.tgz; rm runner.tgz; \
    ./bin/installdependencies.sh; \
    curl -fsSL -o /tmp/gh.tgz "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_amd64.tar.gz"; \
    tar xzf /tmp/gh.tgz -C /tmp; mv /tmp/gh_${GH_VERSION}_linux_amd64/bin/gh /usr/local/bin/gh; rm -rf /tmp/gh*; \
    chown -R builder:builder /opt/actions-runner; \
    mkdir -p /data /home/builder/_work; chown builder:builder /data /home/builder/_work

COPY entrypoint.sh /usr/local/bin/jc-runner-entrypoint
RUN chmod 755 /usr/local/bin/jc-runner-entrypoint

USER builder
WORKDIR /home/builder
ENTRYPOINT ["/usr/local/bin/jc-runner-entrypoint"]

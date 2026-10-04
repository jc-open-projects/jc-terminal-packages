# 패키지 빌드 러너 (jc-terminal-v2 DEC-011) — termux 공식 빌드 이미지(x86_64)에 GitHub Actions 러너를 얹는다.
# 빌드가 이 컨테이너 안에서 바로 돈다 — 도커 소켓을 러너에 넘기지 않는다 (공개 저장소의 러너).
# ARM 맥의 colima(Rosetta)에서 x86_64 로 돈다. 띄우는 법: runner/README.md
FROM --platform=linux/amd64 ghcr.io/termux/package-builder:latest

ARG RUNNER_VERSION=2.337.0
ARG GH_VERSION=2.102.0

USER root
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

# 패키지 빌드 러너

`jc-open-projects` 조직의 self-hosted 러너 `macbook-linux` (라벨 `jc-pkg-builder`) — jc-terminal-v2 DEC-011.
termux 공식 빌드 이미지(x86_64)에 GitHub Actions 러너를 얹은 컨테이너로, ARM 맥의 colima(Rosetta)에서 돈다.

## 띄우기 (맥에서, 한 번)

```sh
colima start --vm-type vz --vz-rosetta          # Rosetta 가 켜져 있어야 x86_64 가 빠르다
docker build --platform linux/amd64 -t jc-pkg-runner runner/
TOKEN=$(gh api -X POST orgs/jc-open-projects/actions/runners/registration-token --jq .token)
docker run -d --name jc-pkg-runner --restart always --platform linux/amd64 \
  -e RUNNER_URL=https://github.com/jc-open-projects -e RUNNER_TOKEN="$TOKEN" \
  -e RUNNER_NAME=macbook-linux -e RUNNER_LABELS=jc-pkg-builder \
  -v jc-pkg-runner:/opt/actions-runner \
  -v jc-pkg-work:/home/builder/_work \
  -v jc-pkg-build:/home/builder/.termux-build \
  -v jc-pkg-data:/data \
  jc-pkg-runner
```

- 등록 토큰은 한 시간 동안만 쓸 수 있다. 등록 설정은 `jc-pkg-runner` 볼륨에 남아, 컨테이너를 다시 띄워도 다시 등록하지 않는다.
- 빌드 캐시(`~/.termux-build`, `/data`, termux-packages 체크아웃)는 볼륨에 남아 다음 빌드가 이어서 굽는다.
- 조직의 기본 러너 그룹이 **공개 저장소**를 허용해야 한다 (조직 설정 → Actions → Runner groups).

## 안전

공개 저장소의 self-hosted 러너다. 워크플로는 **수동 실행(`workflow_dispatch`)에서만** 돈다 — 포크 PR 이 이 러너에서 코드를 돌리지 못한다. 도커 소켓을 넘기지 않는다.

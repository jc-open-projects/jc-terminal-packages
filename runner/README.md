# 패키지 빌드 러너

`jc-open-projects` 조직의 self-hosted 러너 `macbook-linux` (라벨 `jc-pkg-builder`) — jc-terminal-v2 DEC-011.
termux 공식 빌드 이미지(x86_64)에 GitHub Actions 러너를 얹은 컨테이너로, ARM 맥의 colima(Rosetta)에서 돈다.

## 띄우기 (맥에서, 한 번)

```sh
colima start --vm-type vz --vz-rosetta   # Rosetta 가 켜져 있어야 x86_64 가 빠르다
runner/start.sh                          # 이미지를 만들고, 등록 토큰을 받아 컨테이너를 띄운다
```

- 등록 토큰은 한 시간 동안만 쓸 수 있다. 등록 설정은 `jc-pkg-runner` 볼륨에 남아, 컨테이너를 다시 띄워도 다시 등록하지 않는다.
- 빌드 캐시(`~/.termux-build`, `/data`, termux-packages 체크아웃 `jc-pkg-tp`)는 볼륨에 남아 다음 빌드가 이어서 굽는다.
- 조직의 기본 러너 그룹이 **공개 저장소**를 허용해야 한다 (조직 설정 → Actions → Runner groups).

## Rosetta 에서 알려진 문제

- Ubuntu 26.04 의 GNU tar 는 Rosetta 에서 파일 풀기가 실패한다(`Cannot open: Function not implemented`). 이미지는 Ubuntu 24.04 의 tar 바이너리로 바꿔 쓴다 (`Dockerfile`).
- Rosetta 는 ptrace 를 지원하지 않아 컨테이너 안에서 `strace` 가 돌지 않는다.

## 안전

공개 저장소의 self-hosted 러너다. 워크플로는 **수동 실행(`workflow_dispatch`)에서만** 돈다 — 포크 PR 이 이 러너에서 코드를 돌리지 못한다. 도커 소켓을 넘기지 않는다.

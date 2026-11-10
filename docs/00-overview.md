# 개요 — JC Terminal 패키지 저장소 (jc-terminal-packages)

## 목표

JC Terminal V2 안드로이드 앱이 쓰는 패키지(bash·coreutils·apt·git·openssh …)를 앱 경로 `/data/data/com.jc.terminal2/files/usr` 로 다시 구워,
GPG 로 서명한 apt 저장소(GitHub Pages)와 부트스트랩 zip(Releases)으로 공개 배포한다 — jc-terminal-v2 의 M3b 패키지 단계. 첫 판은 배포를 마쳤고, 지금은 레시피 고정 판을 올리거나 패키지를 더할 때 다시 굽는 유지 단계다.

## 지향

- 레시피는 termux/termux-packages 를 커밋 하나로 고정해 쓰고(`packaging/jc-packages.conf` 의 `JC_TERMUX_PACKAGES_REF`), 우리가 더하는 것은 `packaging/patch-termux-packages.sh` 의 경로·키 패치뿐이다 (jc-terminal-v2 DEC-013).
- 의존성까지 모두 우리 경로로 직접 굽는다 — `com.termux` 경로의 공식 deb 와 섞지 않는다. 부트스트랩은 릴리스 전에 `com.termux` 경로가 남았는지 검사한다 (`packaging/verify-bootstrap.sh`).
- 바뀐 것만 굽는다 — 워크플로가 게시된 apt 저장소의 `Packages` 와 레시피 판을 비교해 구울 레시피를 정하고(`packaging/plan-builds.sh`), 하위 패키지(curl·clang)는 상위 레시피(libcurl·libllvm)로 찾는다. 우리 패치를 바꾸면 `JC_TERMUX_TOOLS_REVISION_BUMP` 처럼 판을 올려 다시 굽게 한다.
- 저장소와 부트스트랩은 앱 서명 키와 별개인 RSA 4096 GPG 키로 서명한다. 공개 키는 `keys/`, 개인 키는 Actions 시크릿에만 둔다 (DEC-012).
- GPL 등 소스 제공 — 배포한 판마다 원본 소스와 레시피·패치를 릴리스 `sources` 의 `src-<레시피>-<판>.tar` 로 올리고, 그 판을 배포하는 동안 지우지 않는다.
- 빌드는 GitHub 호스팅 러너(`ubuntu-latest`)에서 공식 빌드 이미지로, 워크플로는 수동 실행(`workflow_dispatch`)만 (jc-terminal-v2 DEC-015 — 맥북 self-hosted 러너는 걷어냄). 러너에 도커 소켓·`/dev/fuse`·SYS_ADMIN 같은 넓은 권한을 주지 않는다 (DEC-011).
- 앱은 이 패키지를 별도 프로세스로 실행만 하고 링크하지 않는다. 앱 소스는 여기 두지 않는다.
- 묶음: 부트스트랩은 1판 최소 세트(− termux-am-socket, DEC-016) + gnupg·curl·git·openssh·tmux, 저장소 첫 판은 vim·htop·python·rsync·ripgrep·jq·make·clang 까지 (DEC-014). 아키텍처는 우선 `aarch64`.
- `termux-tools` 는 우리 미러 하나만 conffile 로 둔다 — `pkg upgrade` 때 dpkg 가 미러 설정을 묻지 않게.

## 한 것

- 2026-10-05 부트스트랩 릴리스 `bootstrap-20261005-17` (aarch64, Latest) — zip·`.sha256`·`.sig`·`jc-packages.conf`, 릴리스 설명의 `jcBootstrapUrl`·`jcBootstrapSha256` 이 jc-terminal-v2 `gradle.properties` 에 들어감 (앱 0.3.0~, PR #11).
- 2026-10-05 apt 저장소 게시 — `gh-pages` 브랜치, <https://jc-open-projects.github.io/jc-terminal-packages> 의 `dists/stable` (InRelease·Release.gpg 서명), aarch64 deb 279개 (부트스트랩 묶음 + 저장소 추가분 vim·htop·python·rsync·ripgrep·jq·make·clang 과 의존성). 원본 소스는 릴리스 `sources`.
- 2026-10-05 기기 확인 (jc-terminal-v2 쪽) — 에뮬레이터에서 앱이 첫 실행에 부트스트랩을 받아 설치 → `bash`, `pkg install git vim htop python jq` 확인 (M3b 인수 기준).
- 2026-10-05 GitHub 호스팅 러너로 옮김, termux-am-socket 뺌 (`431ba50`·`088501d`, PR #2) — 그 뒤 고친 것:
  - termux-tools 가 우리 미러 하나만 conffile 로, 같은 판 deb 는 덮지 않음 (`fb76cc0`).
  - `arch=all` 을 `binary-aarch64` 에 합침 — `-i` 가 `binary-all` 만 받고 의존성을 다 굽던 문제 (`126b58b`, `packaging/merge-arch-all.py`).
  - deb 를 tar 로 묶어 artifact 로(epoch 의 `:`), 빌드 로그 전체를 artifact 로 (`aff05cc`).
  - `TERMUX_REPO_*` 를 우리 앱으로 — 아니면 `-i` 가 무시되고 의존성을 다 굽던 것, SDK 는 늘 준비 (`fa4b630`).
  - `run-docker.sh` 를 termux-packages 폴더 안에서, 레시피 판 계산을 상대 경로에서도 (`297f792`·`82b87d3`).
- 2026-10-05 부트스트랩 고침 — `chosen_mirrors` → `mirrors/default` 링크(pkg 의 지역 미러 오류), gnupg 를 `--add` 로, 하위 패키지는 상위 레시피로 굽기 (`7cc647f`·`6aa39e0`·`c157a79`).
- 2026-10-05 첫 판 — 빌드 설정(`packaging/`)·경로 패치·부트스트랩 경로 바꾸기 스크립트, 워크플로 `Packages and bootstrap`, 공개 키, GPG 서명 키 시크릿 `JC_PACKAGES_GPG_KEY`·`JC_PACKAGES_GPG_PASSPHRASE` (`7e98ec2`; 맥북 러너 컨테이너 `8872011`·`133c9fc` 는 호스팅 러너로 옮기며 걷어냄).

## 남은 일

- 서명 키 백업 · DEC-012 는 암호 잠근 키 백업을 사용자에게 두기로 함 — 이 저장소에서는 보관 여부를 확인할 수 없음 · 사용자 · 확인만.
- 옛 부트스트랩 릴리스 정리 · `bootstrap-20261004-3`·`-4`·`-8`, `bootstrap-20261005-14`·`-15` 가 남아 있음 — 앱이 쓰는 것은 `-17` 뿐. 지울지는 정하지 않음(소스 제공 원칙상 배포했던 판의 `sources` 는 남긴다) · 사용자 결정 · 없음.
- 레시피 고정 판 올리기 · `JC_TERMUX_PACKAGES_REF` 는 첫 판 그대로(`3d362cd`) — 보안 갱신이 필요할 때 값을 바꾸고 다시 굽는다 · AI · 필요할 때.
- 다른 아키텍처 · 지금은 `aarch64` 만 (`JC_ARCHITECTURES`) — 에뮬레이터·기기가 x86_64·arm 을 요구하면 더한다 · AI · 요구가 생길 때.

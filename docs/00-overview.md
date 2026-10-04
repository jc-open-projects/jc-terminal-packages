# 개요 — JC Terminal 패키지 저장소 (jc-terminal-packages)

## 목표

JC Terminal V2 안드로이드 앱이 쓰는 패키지(bash·coreutils·apt·git·openssh …)를 앱 경로 `/data/data/com.jc.terminal2/files/usr` 로 다시 구워,
GPG 로 서명한 apt 저장소(GitHub Pages)와 부트스트랩 zip(Releases)으로 공개 배포한다 — jc-terminal-v2 의 M3b 패키지 단계.

## 지향

- 레시피는 termux/termux-packages 를 커밋 하나로 고정해 쓰고(`packaging/jc-packages.conf` 의 `JC_TERMUX_PACKAGES_REF`), 우리가 더하는 것은 `packaging/patch-termux-packages.sh` 의 경로·키 패치뿐이다 (jc-terminal-v2 DEC-013).
- 의존성까지 모두 우리 경로로 직접 굽는다 — `com.termux` 경로의 공식 deb 와 섞지 않는다. 부트스트랩은 릴리스 전에 `com.termux` 경로가 남았는지 검사한다.
- 저장소와 부트스트랩은 앱 서명 키와 별개인 RSA 4096 GPG 키로 서명한다. 공개 키는 `keys/`, 개인 키는 Actions 시크릿에만 둔다 (DEC-012).
- GPL 등 소스 제공 — 배포한 판마다 원본 소스와 레시피·패치를 `sources-<태그>.tar` 로 같은 릴리스에 올리고, 그 판을 배포하는 동안 지우지 않는다.
- 공개 저장소의 self-hosted 러너이므로 워크플로는 수동 실행(`workflow_dispatch`)만, 도커 소켓·`/dev/fuse`·SYS_ADMIN 같은 넓은 권한은 러너에 주지 않는다 (DEC-011).
- 앱은 이 패키지를 별도 프로세스로 실행만 하고 링크하지 않는다. 앱 소스는 여기 두지 않는다.
- 묶음: 부트스트랩은 1판 최소 세트(− termux-am-socket) + curl·git·openssh·tmux, 저장소 첫 판은 vim·htop·python·rsync·ripgrep·jq·make·clang 까지 (DEC-014). 아키텍처는 우선 `aarch64`.

## 한 것

- 2026-10-05 패치: termux 빌드 도구 모음을 fuse-overlayfs 대신 복사 — 첫 실행이 러너에 `/dev/fuse` 가 없어 실패한 것을 고침 (`133c9fc`).
- 2026-10-05 러너: Rosetta(colima)에서 GNU tar 가 실패하는 문제를 Ubuntu 24.04 tar 로 우회, `runner/start.sh` 추가 (`8872011`).
- 2026-10-05 첫 판: 빌드 설정(`packaging/`)·경로 패치·부트스트랩 경로 바꾸기 스크립트, 러너 컨테이너(`runner/`), 워크플로 `Packages and bootstrap`, 공개 키 (`7e98ec2`).
- GPG 서명 키 시크릿 `JC_PACKAGES_GPG_KEY`·`JC_PACKAGES_GPG_PASSPHRASE` 등록.

## 남은 일

- 부트스트랩 묶음 첫 굽기 · 워크플로 첫 실행이 `패키지 굽기` 단계에서 진행 중(아직 deb 산출·apt 업로드 없음) · AI(워크플로) · 실행이 끝나는 것.
- apt 저장소 첫 게시 · `gh-pages` 브랜치가 아직 없고 GitHub Pages 사이트도 설정되지 않음 · AI(워크플로)·사용자(조직 설정에서 Pages 켜기) · 첫 굽기 성공.
- 부트스트랩 zip 첫 릴리스 · Releases 가 비어 있음 — `make_bootstrap` 실행으로 zip·`.sig`·`sources-<태그>.tar` 를 올려야 함 · AI · apt 저장소 게시.
- 앱에 부트스트랩 주소 넣기 · 릴리스 설명의 `jcBootstrapUrl`·`jcBootstrapSha256` 을 앱 저장소 `gradle.properties` 에, 저장소 주소·공개 키를 앱에 넣어야 함 · AI(jc-terminal-v2 쪽) · 첫 부트스트랩 릴리스, jc-terminal-v2 의 M3b 브랜치·결정 PR 병합.
- 저장소 추가분(`repo-extra`) 굽기 · vim·htop·python 등은 아직 굽지 않음, clang 은 오래 걸림 · AI · 부트스트랩 묶음 게시.
- 기기 확인 · 에뮬레이터에서 `pkg install git`, `vim`·`htop` 이 도는 것(M3b 인수 기준)을 아직 보지 않음 · AI · 위 단계 모두.
- 서명 키 백업 · DEC-012 는 암호 잠근 키 백업을 사용자에게 두기로 함 — 이 저장소에서는 보관 여부를 확인할 수 없음 · 사용자 · 확인만.

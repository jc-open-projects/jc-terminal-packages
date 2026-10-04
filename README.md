# JC Terminal 패키지 저장소 (jc-terminal-packages)

[JC Terminal V2](https://github.com/jc-projects-20260921) 안드로이드 터미널 앱이 쓰는 패키지 — bash·coreutils·apt·git·openssh … — 를
앱의 경로 `/data/data/com.jc.terminal2/files/usr` 로 다시 구워 내는 공개 저장소다.

- **apt 저장소**: `https://jc-open-projects.github.io/jc-terminal-packages` (`deb … stable main`, GPG 서명)
- **부트스트랩**(첫 실행에 받는 최소 묶음): [Releases](https://github.com/jc-open-projects/jc-terminal-packages/releases) 의 `bootstrap-aarch64.zip` + `.sig`
- **서명 키**: [`keys/jc-terminal-packages.asc`](keys/jc-terminal-packages.asc) — RSA 4096, 지문 `5F52 ACE4 8197 8987 DE01  FDA2 5123 A9A8 06CB C3F5`

앱 자체의 소스는 여기 없다. 앱은 이 패키지들을 **별도 프로세스로 실행만** 하고 링크하지 않는다.

## 출처와 라이선스

| 무엇 | 출처 | 라이선스 |
| --- | --- | --- |
| 패키지 빌드 레시피·패치 (`packages/…`) | [termux/termux-packages](https://github.com/termux/termux-packages) — 고정 판 `packaging/jc-packages.conf` 의 `JC_TERMUX_PACKAGES_REF` | **각 패키지의 라이선스** (bash 레시피는 bash 와 같은 GPL 등) |
| 빌드 도구 (`scripts/`·`build-package.sh` 등) | termux/termux-packages | Apache License 2.0 |
| 각 패키지의 원본 프로그램 | 각 프로젝트 (GNU·OpenSSH·Git …) | 각자의 라이선스 (GPL·BSD·MIT …) |
| `packaging/`·`runner/`·워크플로 | JC (JC Terminal 1판의 우리 스크립트를 바탕으로) | — |

우리가 termux-packages 에 더하는 것은 `packaging/patch-termux-packages.sh` 의 패치뿐이다: 앱 ID(→ 설치 경로)를 바꾸고, 경로 변수를 내보내고,
`termux-keyring` 에 이 저장소의 공개 키를 더한다. "Termux" 는 Termux 프로젝트의 이름이며 이 저장소는 Termux 와 관계가 없다.

### 소스 받기 (GPL 등)

배포한 판마다 **구운 패키지의 원본 소스와 레시피·패치**를 그 릴리스의 `sources-<태그>.tar` 로 함께 올린다. 그 판의 바이너리를 배포하는 동안 지우지 않는다.
apt 저장소의 패키지는 가장 가까운 부트스트랩 릴리스의 소스 묶음과 같은 판의 레시피로 구운 것이다. 찾는 판이 없으면 이 저장소의 이슈로 요청하면 된다.

## 굽기

`Actions → Packages and bootstrap → Run workflow` (수동 실행만). 러너는 조직의 self-hosted `macbook-linux` ([runner/](runner/README.md)).

1. `packages` 를 비우고 실행 → 부트스트랩 묶음을 굽고 apt 저장소에 올린다.
2. `make_bootstrap` 을 켜고 실행 → 부트스트랩 zip 을 만들고(경로 확인) 서명해 릴리스. 릴리스 설명의 `jcBootstrapUrl`·`jcBootstrapSha256` 을 앱 저장소의 `gradle.properties` 에 넣는다.
3. `packages` 에 `repo-extra` → vim·htop·python·rsync·ripgrep·jq·make·clang (오래 걸린다).

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
| `packaging/`·워크플로 | JC (JC Terminal 1판의 우리 스크립트를 바탕으로) | — |

우리가 termux-packages 에 더하는 것은 `packaging/patch-termux-packages.sh` 의 패치뿐이다: 앱 ID(→ 설치 경로)를 바꾸고, 경로 변수를 내보내고,
`termux-keyring` 에 이 저장소의 공개 키를 더하고, 의존성을 이 저장소에서 받게 하고(`repo.json`), `termux-tools` 가 `termux-am-socket` 을
요구하지 않게 한다(그 소켓 서버는 Termux 앱에만 있다). "Termux" 는 Termux 프로젝트의 이름이며 이 저장소는 Termux 와 관계가 없다.

### 소스 받기 (GPL 등)

릴리스 [`sources`](https://github.com/jc-open-projects/jc-terminal-packages/releases/tag/sources) 에 레시피·판마다 `src-<레시피>-<판>.tar`
(원본 소스 + 레시피·패치)를 쌓는다. 패키지를 굽거나 부트스트랩을 낼 때 그 판의 묶음이 없으면 올리고, 옛 판도 지우지 않는다.
2026-10-05 이전에 구운 패키지 가운데 묶음이 없는 것은 이슈로 요청하면 올린다.

## 굽기

`Actions → Packages and bootstrap → Run workflow` (수동 실행만). GitHub 호스팅 러너(`ubuntu-latest`)에서 공식 빌드 이미지로 굽는다.

- **plan** — `packages`(기본 `all` = 부트스트랩 묶음 + 저장소 추가분)의 레시피 가운데 **apt 저장소에 같은 판이 없는 것만** 고른다.
- **build** — 레시피마다 잡 하나(6시간 한도). 의존성은 이 저장소의 deb 를 서명 확인 후 받아 쓰고(`-i`), 없으면 그 자리에서 굽는다.
- **publish** — 새 deb 를 apt 저장소(gh-pages)에 더해 서명·푸시하고, 소스 묶음을 `sources` 에 올린다.
- **bootstrap** (`make_bootstrap`) — 부트스트랩 zip 을 만들고 경로·빠진 패키지를 확인해 서명·릴리스. 릴리스 설명의 `jcBootstrapUrl`·`jcBootstrapSha256` 을 앱 저장소의 `gradle.properties` 에 넣는다.

termux-packages 고정 판을 올리거나 레시피를 바꾸면 판이 달라진 레시피만 다시 굽는다. 다 다시 구우려면 `force_rebuild` — 다만 저장소에 이미 있는 **같은 판은 바꾸지 않는다**(기기가 같은 판을 다시 설치하지 않게). 우리 패치로 내용이 바뀌면 판을 올린다 (예: `JC_TERMUX_TOOLS_REVISION_BUMP`).

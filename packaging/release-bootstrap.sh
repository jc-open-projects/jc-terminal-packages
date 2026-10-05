#!/usr/bin/env bash
#
# 부트스트랩 zip 을 서명하고 릴리스로 올린다 — 앱에 넣을 두 값(주소·SHA-256)을 릴리스 본문에 적는다 (DEC-009·010·012).
#
#   사용법: packaging/release-bootstrap.sh <bootstrap zip> <태그>   (GNUPGHOME 에 서명 키, GH_TOKEN)
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/jc-packages.conf"
zip="${1:?부트스트랩 zip}"; tag="${2:?태그}"
: "${GNUPGHOME:?서명 키 — import-key.sh}"
arch="${ARCH:-aarch64}"
rel="$(mktemp -d)"; trap 'rm -rf "$rel"' EXIT
cp "$zip" "$rel/bootstrap-$arch.zip"
gpg --batch --yes --pinentry-mode loopback --passphrase-file "$GNUPGHOME/pass" --digest-algo SHA256 \
	--detach-sign -o "$rel/bootstrap-$arch.zip.sig" "$rel/bootstrap-$arch.zip"
(cd "$rel" && sha256sum "bootstrap-$arch.zip" > "bootstrap-$arch.zip.sha256")
cp "$here/jc-packages.conf" "$rel/"
sha="$(cut -d' ' -f1 "$rel/bootstrap-$arch.zip.sha256")"
gh release create "$tag" "$rel"/* --title "Bootstrap $tag ($arch)" --notes "JC Terminal V2 부트스트랩 — prefix \`$JC_PREFIX\`, 저장소 $JC_REPO_URL

\`\`\`
jcBootstrapUrl=$JC_RELEASE_URL/$tag/bootstrap-$arch.zip
jcBootstrapSha256=$sha
\`\`\`

termux-packages $JC_TERMUX_PACKAGES_REF + 이 저장소 \`packaging/\` 의 패치. 들어 있는 패키지의 원본 소스·레시피·패치는 릴리스 [sources](https://github.com/$JC_GITHUB_REPO/releases/tag/sources) 의 \`src-<레시피>-<판>.tar\`."
{
	echo "### 부트스트랩 $tag"
	echo "jcBootstrapUrl=$JC_RELEASE_URL/$tag/bootstrap-$arch.zip"
	echo "jcBootstrapSha256=$sha"
} >> "${GITHUB_STEP_SUMMARY:-/dev/null}"
echo "[*] $tag — $sha"

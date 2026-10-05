#!/usr/bin/env bash
#
# apt 저장소(gh-pages 브랜치의 뿌리)에 새 deb 를 더해 다시 만들고 서명해 푸시한다 (DEC-010·012).
# 이미 올린 deb 는 그대로 두고, 같은 이름이면 새 것으로 바꾼다. 같은 패키지의 옛 판 deb 는 지운다.
#
#   사용법: packaging/publish-repo.sh <새 deb 폴더> <실행 번호>   (GNUPGHOME 에 서명 키)
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"; root="$(cd "$here/.." && pwd)"
. "$here/jc-packages.conf"
new="$(cd "${1:?새 deb 폴더}" && pwd)"; run="${2:?실행 번호}"
: "${GNUPGHOME:?서명 키 — import-key.sh}"
br="$JC_PAGES_BRANCH"
cd "$root"
git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
rm -rf /tmp/tar && git clone -q --depth 1 https://github.com/termux/termux-apt-repo.git /tmp/tar
sign() {
	gpg --batch --yes --pinentry-mode loopback --passphrase-file "$GNUPGHOME/pass" --digest-algo SHA256 "$@"
}
for attempt in 1 2 3; do
	rm -rf pages all-debs && mkdir -p all-debs
	git worktree prune
	if git ls-remote --exit-code --heads origin "$br" >/dev/null 2>&1; then
		git fetch -q origin "$br"
		git worktree add -q pages "origin/$br"
	else
		git worktree add -q --detach pages HEAD
		(cd pages && git checkout -q --orphan "$br" && git rm -rfq --cached . && find . -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +)
	fi
	find pages -name '*.deb' -exec cp {} all-debs/ \; 2>/dev/null || true
	# 새로 구운 패키지의 옛 판은 뺀다 (이름_판_아키.deb)
	for f in "$new"/*.deb; do
		p="$(basename "$f")"; p="${p%%_*}"
		find all-debs -name "${p}_*.deb" -delete
	done
	cp -f "$new"/*.deb all-debs/
	echo "[*] deb 합계: $(ls all-debs | wc -l)"
	find pages -mindepth 1 -maxdepth 1 ! -name .git ! -name README.md -exec rm -rf {} +
	python3 /tmp/tar/termux-apt-repo all-debs pages stable main
	# arch=all 을 binary-aarch64 에 합친다 — build-package.sh -i 가 의존성을 받으려면 (merge-arch-all.py)
	python3 "$here/merge-arch-all.py" pages/dists/stable
	r=pages/dists/stable/Release
	sign --clearsign -o pages/dists/stable/InRelease "$r"
	sign --armor --detach-sign -o "$r.gpg" "$r"
	cp "$root/$JC_KEY_FILE" pages/jc-terminal-packages.asc
	touch pages/.nojekyll
	(
		cd pages
		git add -A
		if git diff --cached --quiet; then echo "[*] 바뀐 것이 없습니다"; exit 0; fi
		git commit -q -m "apt: 패키지 갱신 (run $run)"
		git push -q origin "HEAD:$br"
	) && { echo "[*] 푸시 완료"; break; }
	sleep $((attempt * 10))
done
ls pages/dists/stable/main

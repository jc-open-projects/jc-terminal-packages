#!/usr/bin/env python3
"""arch=all 패키지를 아키텍처별 Packages 에 합친다 — Debian·Termux 저장소의 관례.

termux-apt-repo 는 binary-all 을 따로 만든다. termux-packages 의 `build-package.sh -i` 는 Release 에서 binary-all 을
먼저 찾으면 그것만 받고 binary-aarch64 를 받지 않아, 의존성을 받지 못하고 모두 다시 굽는다. 그래서 binary-all 의
항목을 binary-<아키>/Packages 에 더하고 binary-all/Packages* 를 지운 뒤 Release 의 해시를 다시 쓴다.
deb 파일은 그대로(binary-all/ 아래) 둔다 — 항목의 Filename 이 그 경로를 가리킨다.

    사용법: packaging/merge-arch-all.py <dists/stable 폴더>
"""
import hashlib, lzma, os, re, sys, email.utils

dist = sys.argv[1]
comp = os.path.join(dist, 'main')
all_dir = os.path.join(comp, 'binary-all')
all_pkgs = os.path.join(all_dir, 'Packages')
arch_dirs = [d for d in os.listdir(comp) if d.startswith('binary-') and d != 'binary-all']
if not os.path.isfile(all_pkgs):
    print('[*] binary-all/Packages 없음 — 합칠 것 없음')
    sys.exit(0)
extra = open(all_pkgs, encoding='utf-8').read().strip()
for d in arch_dirs:
    p = os.path.join(comp, d, 'Packages')
    body = open(p, encoding='utf-8').read().strip() if os.path.exists(p) else ''
    merged = (body + '\n\n' + extra).strip() + '\n' if body else extra + '\n'
    open(p, 'w', encoding='utf-8').write(merged)
    with lzma.open(p + '.xz', 'wb') as f:
        f.write(merged.encode('utf-8'))
    print(f'[*] {d}/Packages 에 arch=all 항목을 합쳤습니다')
for f in os.listdir(all_dir):
    if f.startswith('Packages'):
        os.remove(os.path.join(all_dir, f))

# Release 다시 쓰기 — 머리글은 그대로(Architectures·Date 만 바꿈), 해시 목록은 지금 파일로
rel = os.path.join(dist, 'Release')
head, files = [], []
for line in open(rel, encoding='utf-8'):
    line = line.rstrip('\n')
    if line.startswith(' '):
        name = line.split()[-1]
        if name not in files:
            files.append(name)
        continue
    if re.match(r'^(MD5Sum|SHA1|SHA256|SHA512):', line):
        continue
    if line.startswith('Architectures:'):
        line = 'Architectures: ' + ' '.join(sorted(d[len('binary-'):] for d in arch_dirs))
    elif line.startswith('Date:'):
        line = 'Date: ' + email.utils.formatdate(usegmt=True)
    head.append(line)
files = [f for f in files if os.path.isfile(os.path.join(dist, f))]
out = head[:]
for title, algo in (('MD5Sum', 'md5'), ('SHA1', 'sha1'), ('SHA256', 'sha256'), ('SHA512', 'sha512')):
    out.append(title + ':')
    for f in files:
        data = open(os.path.join(dist, f), 'rb').read()
        out.append(f' {hashlib.new(algo, data).hexdigest()} {len(data)} {f}')
open(rel, 'w', encoding='utf-8').write('\n'.join(out) + '\n')
print(f'[*] Release 를 다시 썼습니다 — 파일 {len(files)}개')

#!/usr/bin/env python3
"""
把 external/ 內第三方 skill 對「曾遭入侵、或可被改指向」的引用釘死。

背景：2026-03 Trivy 發行鏈遭入侵（GHSA-69fq-xp46-6x23），trivy-action 77 個 tag 中
76 個、setup-trivy 全部 tag 被改指向竊取 CI secrets 的 commit，Docker Hub 也被推了
惡意映像。external/ 的 skill 會教 agent 寫 `trivy-action@master`、`aquasec/trivy:latest`
這類可變引用，照抄進專案 CI 就等於把 secrets 交給下一次事件。
external/ 每天從上游覆蓋同步，直接改檔會被洗掉，所以在每次同步後、symlink 載入前自動改寫。

規則（冪等，已釘在目前 SHA 的不會再動）：
- aquasecurity/trivy-action@<非 SHA>  → @<SHA>，在 `uses:` 行尾補版本註解
- aquasecurity/setup-trivy@<非 SHA>   → 同上
- 兩者若停在本腳本以前釘過的舊 SHA（SUPERSEDED_PINS）→ 換成目前的 SHA，行尾版本註解一併更新
- aquasec/trivy 或 ghcr.io/aquasecurity/trivy 的 :latest 與遭入侵的 0.69.4–0.69.6
  → :<版本>@sha256:<digest>
- 非官方 namespace 的 aquasecurity/trivy:<tag>（Docker Hub）→ 官方 aquasec/trivy 並釘 digest
- 從 main/master 拉 trivy 的 contrib/install.sh → 改拉 release tag，並指定安裝版本

更新釘選值：
  git ls-remote https://github.com/aquasecurity/trivy-action.git refs/tags/<tag>
  並確認該 SHA 在上游預設分支上（git merge-base --is-ancestor <sha> origin/master），
  冒牌 commit 來自 fork，不會在預設分支歷史裡。
  trivy-action 另外要看該 commit 的 action.yaml：`version` 預設值要 ≥ 0.72.0，
  內部 setup-trivy 要 ≥ v0.3.1，否則照釘也會裝到有漏洞的 trivy。
  映像 digest：https://hub.docker.com/v2/repositories/aquasec/trivy/tags/<版本>
"""
import os
import re
import sys

# 2026-09-26 查證：兩個 SHA 皆在上游預設分支，commit 日期晚於 2026-03-19 事件。
# trivy-action 釘 master 而不是最新 tag：v0.35.0 / v0.36.0 預設裝 trivy v0.69.3 / v0.70.0，
# 都早於 CVE-2026-54448（0.71.0）、CVE-2026-55092（0.71.1）、CVE-2026-63328（0.72.0）的修補，
# 內部也還用 setup-trivy v0.2.6。master 這個 commit 預設 trivy v0.74.0、內部用 setup-trivy v0.3.1。
# 上游出新 tag 且預設版本 ≥ 0.72.0 時改回釘 tag。
TRIVY_ACTION = ("d2a0b60797ff03db6132bd4e2b293f9b37081297", "master 2026-08-14, trivy v0.74.0")
# v0.3.0 起 ${{ }} 改經環境變數傳入 run 區塊，修掉 script injection（上游未發 GHSA）；
# v0.3.0 本身載入會壞，要用 v0.3.1。v0.3.0 起 `path` 只接受字面路徑，不再展開變數與 ~。
SETUP_TRIVY = ("81e514348e19b6112ce2a7e3ecbafe19c1e1f567", "v0.3.1")   # 2026-06-03
# 本腳本以前釘過、現已汰換的 SHA 與當時寫進行尾的註解。external/ 已提交的內容帶著這些舊值，
# 而 pin_action 只改非 SHA 的 ref，所以要另外換掉，換 pin 時把舊值加進來。
SUPERSEDED_PINS = {
    "aquasecurity/trivy-action": [("57a97c7e7821a5776cebc9bb87c984fa69cba8f1", "v0.35.0")],
    "aquasecurity/setup-trivy": [("3fb12ec12f41e471780db15c232d5dd185dcb514", "v0.2.6")],
}
TRIVY_VERSION = "0.74.0"
TRIVY_IMAGE_DIGEST = "sha256:62b1e65e8869bc4b4c6aa4fa2b21595256c7c2f6018a9d9ad61caf87187c1969"

EXTS = {".md", ".mdc", ".txt", ".yml", ".yaml", ".sh", ".toml", ".json"}

SHA40 = r"[0-9a-f]{40}"


def pin_action(text, name, sha, tag):
    # @ 後面不是 40 碼 SHA 的 ref 才改
    pat = re.compile(rf"({re.escape(name)})@(?!{SHA40}\b)([A-Za-z0-9._/\-]+)")

    def repl_line(line):
        if not pat.search(line):
            return line
        new = pat.sub(rf"\1@{sha}", line)
        if re.match(r"^\s*-?\s*uses:", new) and "#" not in new.split("uses:", 1)[1]:
            new = new.rstrip("\n") + f"  # {tag}" + ("\n" if line.endswith("\n") else "")
        return new

    return "".join(repl_line(l) for l in text.splitlines(keepends=True))


def repin_superseded(text, name, sha, tag):
    for old_sha, old_tag in SUPERSEDED_PINS.get(name, []):
        ref = re.escape(f"{name}@{old_sha}")
        # 連同本腳本當初補的行尾註解一起換，避免留下 `# v0.35.0` 這種對不上的版本
        text = re.sub(rf"{ref}([ \t]+# {re.escape(old_tag)})(?=[ \t]*$)", f"{name}@{sha}  # {tag}", text, flags=re.M)
        text = re.sub(rf"{ref}\b", f"{name}@{sha}", text)
    return text


def pin_image(text):
    # Docker Hub 上官方映像是 aquasec/trivy；aquasecurity/trivy（沒有 ghcr.io 前綴）不是官方
    # namespace，照抄可能拉到冒名映像，一併改成官方映像並釘 digest
    text = re.sub(
        r"(?<![\w./-])aquasecurity/trivy:(latest|[0-9][0-9.]*)(?!@sha256)\b",
        f"aquasec/trivy:{TRIVY_VERSION}@{TRIVY_IMAGE_DIGEST}",
        text,
    )
    pat = re.compile(
        r"((?:ghcr\.io/aquasecurity/trivy|aquasec/trivy)):(latest|0\.69\.[4-6])(?!@sha256)\b"
    )
    return pat.sub(rf"\1:{TRIVY_VERSION}@{TRIVY_IMAGE_DIGEST}", text)


def pin_install_script(text):
    pat = re.compile(r"(raw\.githubusercontent\.com/aquasecurity/trivy/)(?:main|master)(/contrib/install\.sh)")

    def repl_line(line):
        if not pat.search(line):
            return line
        new = pat.sub(rf"\1v{TRIVY_VERSION}\2", line)
        # `sh -s -- -b <dir>` 沒帶版本時補上，否則會裝 latest
        new = re.sub(r"(sh -s -- -b \S+)(?!\s+v\d)", rf"\1 v{TRIVY_VERSION}", new)
        return new

    return "".join(repl_line(l) for l in text.splitlines(keepends=True))


def main(root):
    changed = []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d != ".git"]
        for fn in filenames:
            if os.path.splitext(fn)[1].lower() not in EXTS:
                continue
            path = os.path.join(dirpath, fn)
            try:
                with open(path, encoding="utf-8") as f:
                    old = f.read()
            except (UnicodeDecodeError, OSError):
                continue
            new = old
            for name, pin in (("aquasecurity/trivy-action", TRIVY_ACTION), ("aquasecurity/setup-trivy", SETUP_TRIVY)):
                new = repin_superseded(new, name, *pin)
                new = pin_action(new, name, *pin)
            new = pin_image(new)
            new = pin_install_script(new)
            if new != old:
                with open(path, "w", encoding="utf-8") as f:
                    f.write(new)
                changed.append(path)
    for p in changed:
        print(f"pin: {p}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else "external"))

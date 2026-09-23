#!/usr/bin/env python3
"""
把 external/ 內第三方 skill 對「曾遭入侵、或可被改指向」的引用釘死。

背景：2026-03 Trivy 發行鏈遭入侵（GHSA-69fq-xp46-6x23），trivy-action 77 個 tag 中
76 個、setup-trivy 全部 tag 被改指向竊取 CI secrets 的 commit，Docker Hub 也被推了
惡意映像。external/ 的 skill 會教 agent 寫 `trivy-action@master`、`aquasec/trivy:latest`
這類可變引用，照抄進專案 CI 就等於把 secrets 交給下一次事件。
external/ 每天從上游覆蓋同步，直接改檔會被洗掉，所以在每次同步後、symlink 載入前自動改寫。

規則（冪等，已釘死的不會再動）：
- aquasecurity/trivy-action@<非 SHA>  → @<SHA>，在 `uses:` 行尾補版本註解
- aquasecurity/setup-trivy@<非 SHA>   → 同上
- aquasec/trivy 或 ghcr.io/aquasecurity/trivy 的 :latest 與遭入侵的 0.69.4–0.69.6
  → :<版本>@sha256:<digest>
- 非官方 namespace 的 aquasecurity/trivy:<tag>（Docker Hub）→ 官方 aquasec/trivy 並釘 digest
- 從 main/master 拉 trivy 的 contrib/install.sh → 改拉 release tag，並指定安裝版本

更新釘選值：
  git ls-remote https://github.com/aquasecurity/trivy-action.git refs/tags/<tag>
  並確認該 SHA 在上游預設分支上（git merge-base --is-ancestor <sha> origin/master），
  冒牌 commit 來自 fork，不會在預設分支歷史裡。
  映像 digest：https://hub.docker.com/v2/repositories/aquasec/trivy/tags/<版本>
"""
import os
import re
import sys

# 2026-09-23 查證：兩個 SHA 皆在上游預設分支，commit 日期早於 2026-03-19 事件
TRIVY_ACTION = ("57a97c7e7821a5776cebc9bb87c984fa69cba8f1", "v0.35.0")  # 2026-03-04，預設 trivy v0.69.3
SETUP_TRIVY = ("3fb12ec12f41e471780db15c232d5dd185dcb514", "v0.2.6")    # 2026-01-15
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
            new = pin_action(old, "aquasecurity/trivy-action", *TRIVY_ACTION)
            new = pin_action(new, "aquasecurity/setup-trivy", *SETUP_TRIVY)
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

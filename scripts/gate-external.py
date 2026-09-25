#!/usr/bin/env python3
"""
外部 skills 裝載前閘門：同步後、link.sh 之前執行，不合格的更新退回上一個已提交版本。

為什麼需要（v1 scan-skills.sh 只告警的缺口）：
- external/ 每天從 50 多個第三方 repo 的分支 HEAD 覆蓋同步，上游一被入侵，
  隔天就經 link.sh 載進 Claude Code 的 context。v1 告警後照樣連結。
- SkillSpector baseline 是 (rule_id, 路徑) 制，同檔同規則的新發現會被蓋掉：
  攻擊者只要把惡意內容加進已列 baseline 的檔案就能避開。所以這裡另對「新增的行」
  做差異檢查，不受 baseline 影響。

核心設計：git 已提交的 external/ 就是「已核准版本」。
某個目錄的更新沒過閘門 → 複製一份到 security-reports/quarantine/ 供人工檢查，
再用 git 把該目錄還原成 HEAD（新目錄則直接移除）。skill 不會消失，只是停在上一版，
也不會被 auto-update.sh commit 進 public repo。

判定（任一成立即隔離，fail-closed）：
  1. 差異規則 BLOCK 級命中（見 RULES），且不在 allowlist
  2. SkillSpector 告警（baseline 外的新 HIGH/CRITICAL）
  3. SkillSpector 掃描失敗、逾時，或未安裝（DASH_SKILLS_ALLOW_UNSCANNED=1 可放行未安裝的情況）

人工判讀為誤報後的放行方式：
  - SkillSpector 告警 → 照舊產 baseline（scripts/merge-baseline.py）
  - 差異規則 → 在 security-reports/gate-allow.tsv 加一行（閘門會印出可直接貼的內容）：
      <skill>\t<rule>\t<檔案路徑 glob>[\t<sha256>]
    有 sha256 時只放行該檔這一版內容；省略則放行該路徑往後所有內容（僅用於資安教材這類
    必然含攻擊範例的文件）。
  放行後重跑同步即可（auto-update.sh 以 .last-update 控制一天一次，刪掉該檔即可重跑）。

用法：
  gate-external.py            檢查 git 視角下有變更的 external/<name>，不合格者隔離
  gate-external.py --dry-run  只報告不還原
"""
import fnmatch
import hashlib
import os
import re
import shutil
import subprocess
import sys
import tempfile
from datetime import date

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REPORT_DIR = os.path.join(REPO, "security-reports")
QUARANTINE_DIR = os.path.join(REPORT_DIR, "quarantine")
QUARANTINE_LOG = os.path.join(REPORT_DIR, "quarantine.log")
ALLOW_FILE = os.path.join(REPORT_DIR, "gate-allow.tsv")
TODAY = date.today().isoformat()

SCRIPT_EXTS = {".sh", ".bash", ".zsh", ".py", ".js", ".mjs", ".cjs", ".ts", ".ps1", ".rb", ".pl"}
TEXT_EXTS = SCRIPT_EXTS | {".md", ".mdc", ".txt", ".yml", ".yaml", ".json", ".toml", ".html", ".xml", ".cfg", ".ini"}

# (rule_id, 適用範圍 all/script/doc, 等級 BLOCK/WARN, 說明, regex)
# 只套用在「這次同步新增的行」，既有內容已在先前核准，不會每天重報。
RULES = [
    ("hidden-unicode", "all", "BLOCK",
     "隱形字元（零寬、雙向控制、Unicode tag），常用於藏人看不到、模型讀得到的指令",
     re.compile("[\\u200B\\u200C\\u200E\\u200F\\u202A-\\u202E\\u2060-\\u2064\\u2066-\\u2069\\uFEFF\\U000E0000-\\U000E007F]")),
    ("encoded-exec", "all", "BLOCK",
     "解碼後直接執行（base64 / eval / exec 解碼內容）",
     re.compile(r"base64\s+(-d|--decode|-D)\b[^\n]*\|\s*(sudo\s+)?(ba|z)?sh\b"
                r"|\beval\s*\(\s*(atob|Buffer\.from|base64)"
                r"|\bexec\s*\(\s*(base64\.b64decode|codecs\.decode|zlib\.decompress|bytes\.fromhex)", re.I)),
    ("agent-hijack", "all", "BLOCK",
     "要求 agent 忽略既有指示、瞞著使用者或繞過權限",
     re.compile(r"\b(ignore|disregard|forget)\s+(all\s+|any\s+|the\s+)?(previous|prior|above|earlier|system)\s+(instructions|prompts?|rules)"
                r"|\b(do\s+not|don'?t|never)\s+(tell|inform|notify|alert|mention\s+(this|it)\s+to)\s+the\s+user"
                r"|\bwithout\s+(telling|informing|notifying|asking)\s+the\s+user"
                r"|--dangerously-skip-permissions"
                r"|\bbypassPermissions\b"
                r"|\bskip(ping)?\s+(all\s+)?permission\s+(checks|prompts)", re.I)),
    ("pipe-to-shell", "script", "BLOCK",
     "腳本從網路下載後直接交給 shell 執行",
     re.compile(r"\b(curl|wget)\b[^\n|]*\|\s*(sudo\s+)?(ba|z)?sh\b|Invoke-Expression[^\n]*DownloadString|\biex\s*\(", re.I)),
    ("credential-path", "script", "BLOCK",
     "腳本讀取本機憑證位置",
     re.compile(r"~/\.ssh\b|\$HOME/\.ssh\b|\.aws/credentials|\.config/gh/hosts|\.claude/\.credentials"
                r"|\.netrc\b|\bid_(rsa|ed25519|ecdsa)\b|\.docker/config\.json|security\s+find-(generic|internet)-password", re.I)),
    ("pipe-to-shell-doc", "doc", "WARN",
     "文件教 agent 用 curl | sh 安裝",
     re.compile(r"\b(curl|wget)\b[^\n|]*\|\s*(sudo\s+)?(ba|z)?sh\b", re.I)),
    ("credential-path-doc", "doc", "WARN",
     "文件提到本機憑證位置",
     re.compile(r"~/\.ssh\b|\.aws/credentials|\.config/gh/hosts|\.claude/\.credentials|\.netrc\b", re.I)),
]
URL_RE = re.compile(r"https?://([A-Za-z0-9.-]+\.[A-Za-z]{2,})")


def git(*args, check=True):
    return subprocess.run(["git", "-C", REPO, *args], capture_output=True, text=True, check=check).stdout


def changed_dirs():
    names = set()
    out = git("diff", "--name-only", "HEAD", "--", "external/")
    out += git("ls-files", "--others", "--exclude-standard", "--", "external/")
    for path in out.splitlines():
        parts = path.split("/")
        if len(parts) >= 2 and parts[1]:
            names.add(parts[1])
    return sorted(names)


def added_lines(name):
    """回傳 {相對路徑: [新增的行]}；新檔整份視為新增，刪除的檔案不列。

    同步是 rm -rf 再 cp，搬檔改名後的新路徑在 git 眼中是未追蹤檔。為了讓 -M 認得出
    「只是改名」，用一份暫存 index（HEAD 加上這個目錄的現況）來算 diff，不動真正的 index。
    -M 避免資安教材類集合一重整目錄就把整份攻擊範例當成新增而誤報。
    """
    fd, tmp_index = tempfile.mkstemp(prefix="gate-index-")
    os.close(fd)
    os.unlink(tmp_index)
    env = dict(os.environ, GIT_INDEX_FILE=tmp_index)
    try:
        subprocess.run(["git", "-C", REPO, "read-tree", "HEAD"], env=env, check=True, capture_output=True)
        subprocess.run(["git", "-C", REPO, "add", "-A", "--", f"external/{name}"], env=env, check=True, capture_output=True)
        diff = subprocess.run(["git", "-C", REPO, "diff", "--cached", "-M", "-U0", "--no-color", "HEAD",
                               "--", f"external/{name}"], env=env, check=True, capture_output=True,
                              text=True, errors="replace").stdout
    finally:
        if os.path.exists(tmp_index):
            os.unlink(tmp_index)
    result, cur = {}, None
    for line in diff.splitlines():
        if line.startswith("+++ "):
            cur = None if line[4:] == "/dev/null" else line[6:]  # 去掉 "+++ b/"
            if cur:
                result.setdefault(cur, [])
        elif cur and line.startswith("+") and not line.startswith("+++"):
            result[cur].append(line[1:])
    return result


def file_sha256(path):
    try:
        with open(os.path.join(REPO, path), "rb") as f:
            return hashlib.sha256(f.read()).hexdigest()
    except OSError:
        return ""


def load_allow():
    rules = []
    if not os.path.exists(ALLOW_FILE):
        return rules
    with open(ALLOW_FILE, encoding="utf-8") as f:
        for raw in f:
            raw = raw.rstrip("\n")
            if not raw.strip() or raw.lstrip().startswith("#"):
                continue
            cols = raw.split("\t")
            if len(cols) >= 3:
                rules.append((cols[0], cols[1], cols[2], cols[3] if len(cols) > 3 else ""))
    return rules


def allowed(allow, name, rule, path):
    for a_name, a_rule, a_glob, a_sha in allow:
        if a_name == name and a_rule in (rule, "*") and fnmatch.fnmatch(path, a_glob):
            if not a_sha or a_sha == file_sha256(path):
                return True
    return False


def check_rules(name, allow):
    blocks, warns, domains = [], [], set()
    for path, lines in added_lines(name).items():
        ext = os.path.splitext(path)[1].lower()
        is_script = ext in SCRIPT_EXTS or os.access(os.path.join(REPO, path), os.X_OK)
        kind = "script" if is_script else "doc"
        for rule, scope, level, desc, rx in RULES:
            if scope not in ("all", kind):
                continue
            for ln in lines:
                if rx.search(ln):
                    if level == "BLOCK" and allowed(allow, name, rule, path):
                        break
                    hit = (rule, path, desc, ln.strip()[:160])
                    (blocks if level == "BLOCK" else warns).append(hit)
                    break  # 同檔同規則只報一次
        for ln in lines:
            domains.update(m.lower() for m in URL_RE.findall(ln))
    return blocks, warns, domains


def run_scanner(names):
    """呼叫 scan-skills.sh，回傳 {name: status}；'*' 代表掃描器整體不可用。

    輸出直接串流到終端機，不先收集：掃描一個目錄可能要幾分鐘，
    收集起來最後才印，畫面會整段沒動靜，看起來像當掉（2026-09-25 實際發生，
    使用者因此中斷同步，更新停在工作目錄沒有 commit）。
    """
    fd, status_file = tempfile.mkstemp(prefix="scan-status-")
    os.close(fd)
    env = dict(os.environ, SCAN_STATUS_FILE=status_file)
    subprocess.run([os.path.join(REPO, "scripts", "scan-skills.sh"), *names], cwd=REPO, env=env)
    status = {}
    with open(status_file, encoding="utf-8") as f:
        for raw in f:
            cols = raw.rstrip("\n").split("\t")
            if len(cols) == 2:
                status[cols[0]] = cols[1]
    os.unlink(status_file)
    return status


def quarantine(name, reasons, dry_run):
    src = os.path.join(REPO, "external", name)
    dst = os.path.join(QUARANTINE_DIR, f"{name}-{TODAY}")
    os.makedirs(QUARANTINE_DIR, exist_ok=True)
    if os.path.isdir(src):
        shutil.rmtree(dst, ignore_errors=True)
        shutil.copytree(src, dst, symlinks=True)
        diff = git("diff", "HEAD", "--no-color", "--", f"external/{name}", check=False)
        with open(dst + ".diff", "w", encoding="utf-8") as f:
            f.write(diff)
    with open(QUARANTINE_LOG, "a", encoding="utf-8") as f:
        for r in reasons:
            f.write(f"{TODAY}\t{name}\t{r}\n")
    if dry_run:
        return
    tracked = git("ls-files", "--", f"external/{name}").strip()
    if tracked:
        git("checkout", "HEAD", "--", f"external/{name}", check=False)
    git("clean", "-fdq", "--", f"external/{name}", check=False)


def main():
    # 被管線接到 sed 時 Python 預設整塊緩衝，要等結束才吐出；改成逐行輸出
    sys.stdout.reconfigure(line_buffering=True)
    dry_run = "--dry-run" in sys.argv
    names = changed_dirs()
    if not names:
        print("[gate] external/ 無變更，跳過")
        return 0

    allow = load_allow()
    timeout = os.environ.get("SCAN_SKILLS_TIMEOUT", "240")
    print(f"[gate] 檢查 {len(names)} 個有變更的目錄：{', '.join(names)}")
    print(f"[gate] SkillSpector 逐一掃描，每個最多 {timeout} 秒，期間請勿中斷")
    status = run_scanner(names)
    scanner_down = status.get("*") == "not-installed"
    allow_unscanned = os.environ.get("DASH_SKILLS_ALLOW_UNSCANNED") == "1"

    passed, blocked = [], []
    for name in names:
        reasons = []
        blocks, warns, domains = check_rules(name, allow)
        for rule, path, desc, sample in blocks:
            reasons.append(f"{rule}\t{path}\t{desc}\t{sample}")
        st = status.get(name)
        if scanner_down:
            if not allow_unscanned:
                reasons.append("scanner\t-\tSkillSpector 未安裝，無法掃描（fail-closed）")
        elif st in ("alert", "failed", "timeout"):
            reasons.append(f"scanner\t-\tSkillSpector {st}（明細見 security-reports/findings.log 與當日報告）")
        elif st is None and os.path.isdir(os.path.join(REPO, "external", name)):
            reasons.append("scanner\t-\tSkillSpector 沒有回報此目錄的結果（fail-closed）")

        for rule, path, desc, sample in warns:
            print(f"[gate]   注意 {name}: {rule} {path}（{desc}）")
        if domains:
            committed = git("grep", "-h", "-o", "-I", "-E", r"https?://[A-Za-z0-9.-]+\.[A-Za-z]{2,}",
                            "HEAD", "--", f"external/{name}", check=False)
            known = {m.lower() for m in URL_RE.findall(committed)}
            new = sorted(d for d in domains if d not in known)
            if new:
                print(f"[gate]   注意 {name}: 新增的網域 {', '.join(new[:10])}")

        if reasons:
            blocked.append(name)
            # 雜湊要在還原前算，還原後檔案就變回舊版或不存在了
            hints = [(r.split("\t")[:3], file_sha256(r.split("\t")[1])) for r in reasons]
            quarantine(name, reasons, dry_run)
            print(f"[gate] 隔離 {name}：退回上一個已提交版本" + ("（dry-run，未還原）" if dry_run else ""))
            for (rule, path, desc), sha in hints:
                print(f"[gate]   - {rule} {path}：{desc}")
                if rule != "scanner":
                    print(f"[gate]     誤報放行：printf '%s\\t%s\\t%s\\t%s\\n' '{name}' '{rule}' '{path}' '{sha}' >> security-reports/gate-allow.tsv")
        else:
            passed.append(name)

    print(f"[gate] 完成：通過 {len(passed)}、隔離 {len(blocked)}")
    if blocked:
        print(f"[gate] 被隔離的更新複本與 diff：security-reports/quarantine/（人工判讀後再決定放行）")
    return 0


if __name__ == "__main__":
    sys.exit(main())

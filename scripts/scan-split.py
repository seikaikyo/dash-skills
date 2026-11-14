#!/usr/bin/env python3
"""大型集合的拆分掃描：整包掃描不完整時，改成逐一掃描第一層子目錄再合併報告。

用法: scan-split.py <集合目錄> <輸出報告.json> [baseline.yaml]
      scan-split.py --complete-check <報告.json> <skill 名稱>

為什麼需要：SkillSpector 的時間上限寫死在程式裡，沒有選項可調。檔案很多的集合整包掃描時，
多數分析器跑不完，報告照樣產出、分數照樣是 0。拆成子目錄後每次掃描都在上限內。

- 每個第一層子目錄各掃一次；頂層散檔複製到暫存目錄當成一組。
- baseline 規則的路徑是相對集合根目錄，這裡依子目錄前綴拆出該組適用的規則。
- 合併報告的 location.file 補回子目錄前綴，格式與整包掃描相同，merge-baseline.py 可直接用。
- 任一組掃描失敗或逾時，合併報告標成不完整，由呼叫端 fail-closed。

--complete-check：報告涵蓋全部檔案回傳 0，否則回傳 1 並列出沒被完整檢查的檔案。
有些檔案拆開掃也過不了掃描器的輸出上限（例如很長的鎖檔）。人工看過後在
security-reports/scan-incomplete-allow.tsv 加一行即可接受：
    <skill>\t<相對 skill 根目錄的路徑>\t<reason_code>[\t<sha256>]
有 sha256 時只接受該檔這一版內容。
"""
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

ORDER = ["NONE", "INFO", "LOW", "MEDIUM", "HIGH", "CRITICAL"]
TIMEOUT = int(os.environ.get("SCAN_SKILLS_TIMEOUT", "240"))
ROOT_UNIT = "."
REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INCOMPLETE_ALLOW = os.path.join(REPO, "security-reports", "scan-incomplete-allow.tsv")
# 這個原因碼只代表文件裡有一個本機路徑參照對不到檔案，檔案本身仍算完整檢查
NOT_A_GAP = {"reference_unresolved"}


def rank(sev):
    sev = str(sev or "NONE").upper()
    return ORDER.index(sev) if sev in ORDER else 0


def baseline_rules(path):
    if not path or not os.path.exists(path):
        return []
    text = open(path, encoding="utf-8").read()
    rules = []
    for m in re.finditer(r"- id: (\S+)\n  path: (.+)", text):
        p = m.group(2).strip()
        if len(p) >= 2 and p[0] == "'" and p[-1] == "'":
            p = p[1:-1].replace("''", "'")
        rules.append((m.group(1), p))
    return rules


def write_unit_baseline(rules, unit, dest):
    """回傳該組的 baseline 檔路徑；沒有適用規則回傳 None。"""
    picked = []
    for rule_id, p in rules:
        if unit == ROOT_UNIT:
            if "/" not in p:
                picked.append((rule_id, p))
        elif p.startswith(unit + "/"):
            picked.append((rule_id, p[len(unit) + 1:]))
    if not picked:
        return None
    lines = ["version: 2\n", "scanner_version: 2.10.0\n", "fingerprints: []\n", "rules:\n"]
    for rule_id, p in sorted(set(picked)):
        quoted = p if re.fullmatch(r"[A-Za-z0-9._/\-]+", p) else "'" + p.replace("'", "''") + "'"
        lines.append(f"- id: {rule_id}\n  path: {quoted}\n  reason: Accepted finding (split from collection baseline)\n")
    with open(dest, "w", encoding="utf-8") as f:
        f.write("".join(lines))
    return dest


def scan(target, out, baseline):
    cmd = ["skillspector", "scan", target, "--no-llm", "--format", "json", "--output", out]
    if baseline:
        cmd += ["--baseline", baseline]
    try:
        subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=TIMEOUT)
    except subprocess.TimeoutExpired:
        return None
    try:
        report = json.load(open(out, encoding="utf-8"))
    except (OSError, ValueError):
        return None
    return report if isinstance(report.get("risk_assessment"), dict) else None


def sha256(path):
    try:
        with open(path, "rb") as f:
            return hashlib.sha256(f.read()).hexdigest()
    except OSError:
        return ""


def complete_check(report_path, name):
    try:
        with open(report_path, encoding="utf-8") as f:
            comp = json.load(f).get("analysis_completeness")
    except (OSError, ValueError):
        comp = None
    if not isinstance(comp, dict):
        print("[scan-split]   報告沒有完整度欄位")
        return 1
    if comp.get("failed_units"):
        print(f"[scan-split]   掃描失敗的子目錄：{', '.join(comp['failed_units'])}")
        return 1
    gaps = int(comp.get("partially_inspected_files") or 0) + int(comp.get("entirely_uninspected_files") or 0)
    if gaps == 0:
        return 0
    named = sorted({(e.get("path") or "", e.get("reason_code") or "")
                    for e in comp.get("ledger_exceptions") or []
                    if e.get("reason_code") not in NOT_A_GAP and e.get("path")})
    # 報告指名的檔案數對不上缺口數，代表有檔案沒被完整檢查卻沒列出原因，不能逐檔接受
    if len({p for p, _ in named}) != gaps:
        print(f"[scan-split]   {gaps} 個檔案沒被完整檢查")
        return 1
    accepted = set()
    if os.path.exists(INCOMPLETE_ALLOW):
        with open(INCOMPLETE_ALLOW, encoding="utf-8") as f:
            for raw in f:
                cols = raw.rstrip("\n").split("\t")
                if len(cols) >= 3 and cols[0] == name and not raw.lstrip().startswith("#"):
                    full = os.path.join(REPO, "external", name, cols[1])
                    if len(cols) < 4 or not cols[3] or cols[3] == sha256(full):
                        accepted.add((cols[1], cols[2]))
    missing = [item for item in named if item not in accepted]
    for path, reason in missing:
        digest = sha256(os.path.join(REPO, "external", name, path))
        print(f"[scan-split]   沒被完整檢查：{path}（{reason}）")
        print(f"[scan-split]     看過後接受：printf '%s\\t%s\\t%s\\t%s\\n' '{name}' '{path}' '{reason}' '{digest}'"
              f" >> security-reports/scan-incomplete-allow.tsv")
    return 1 if missing else 0


def main():
    if len(sys.argv) == 4 and sys.argv[1] == "--complete-check":
        return complete_check(sys.argv[2], sys.argv[3])
    if len(sys.argv) not in (3, 4):
        print(__doc__)
        return 2
    root = os.path.realpath(sys.argv[1])
    out_path = sys.argv[2]
    rules = baseline_rules(sys.argv[3] if len(sys.argv) == 4 else None)

    entries = sorted(os.listdir(root))
    units = [e for e in entries if os.path.isdir(os.path.join(root, e)) and not os.path.islink(os.path.join(root, e))]
    loose = [e for e in entries if e not in units]

    work = tempfile.mkdtemp(prefix="scan-split-")
    issues, failed_units, exceptions = [], [], []
    totals = {"total_components": 0, "fully_inspected_files": 0,
              "partially_inspected_files": 0, "entirely_uninspected_files": 0}
    score, sev, max_sev, suppressed = 0, "NONE", "NONE", 0
    try:
        jobs = [(u, os.path.join(root, u)) for u in units]
        if loose:
            loose_dir = os.path.join(work, "root-files")
            os.makedirs(loose_dir)
            for name in loose:
                src = os.path.join(root, name)
                if os.path.isfile(src) and not os.path.islink(src):
                    shutil.copy2(src, os.path.join(loose_dir, name))
            jobs.append((ROOT_UNIT, loose_dir))
        for i, (unit, target) in enumerate(jobs):
            base = write_unit_baseline(rules, unit, os.path.join(work, f"baseline-{i}.yaml"))
            report = scan(target, os.path.join(work, f"report-{i}.json"), base)
            if report is None:
                failed_units.append(unit)
                continue
            comp = report.get("analysis_completeness") or {}
            for key in totals:
                totals[key] += int(comp.get(key) or 0)
            for exc in comp.get("ledger_exceptions") or []:
                if unit != ROOT_UNIT and exc.get("path"):
                    exc["path"] = f"{unit}/{exc['path']}"
                exceptions.append(exc)
            risk = report["risk_assessment"]
            score = max(score, int(risk.get("score") or 0))
            if rank(risk.get("severity")) > rank(sev):
                sev = str(risk.get("severity")).upper()
            if rank(risk.get("max_issue_severity")) > rank(max_sev):
                max_sev = str(risk.get("max_issue_severity")).upper()
            suppressed += int(report.get("suppressed_count") or 0)
            for issue in report.get("issues") or []:
                loc = issue.get("location") or {}
                if unit != ROOT_UNIT and loc.get("file"):
                    loc["file"] = f"{unit}/{loc['file']}"
                issues.append(issue)
    finally:
        shutil.rmtree(work, ignore_errors=True)

    complete = not failed_units and totals["partially_inspected_files"] == 0 \
        and totals["entirely_uninspected_files"] == 0
    merged = {
        "skill": {"name": os.path.basename(root), "split_scan": True, "units": len(units) + (1 if loose else 0)},
        "risk_assessment": {"score": score, "severity": sev, "max_issue_severity": max_sev},
        "issues": issues,
        "suppressed_count": suppressed,
        "analysis_completeness": dict(totals, is_complete=complete,
                                      status="complete" if complete else "partial",
                                      failed_units=failed_units,
                                      ledger_exceptions=exceptions),
    }
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(merged, f, ensure_ascii=False, indent=1)
    print(f"[scan-split] {os.path.basename(root)}: {len(units) + (1 if loose else 0)} 組，"
          f"完整檢查 {totals['fully_inspected_files']}/{totals['total_components']} 檔，"
          f"失敗 {len(failed_units)} 組")
    return 0


if __name__ == "__main__":
    sys.exit(main())

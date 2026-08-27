#!/usr/bin/env python3
"""把 SkillSpector 掃描報告的 findings 聯集進 baseline 檔（rules 制）。

用法: merge-baseline.py <report.json> <baseline.yaml>

設計依據（2026-08-27 實測加 suppression.py 源碼）：
- 官方 fingerprints 制綁定檔案完整內容雜湊：上游任何改檔即全數失效重報，
  對每日同步的外部 skills corpus 噪音不可運營；且 report 的 match_fingerprint
  與 baseline 指紋是不同雜湊，無法離線合成。
- 故走 rules 制：每筆 finding 收斂成 (rule_id, 確切檔案路徑) 一條 glob 規則。
  代價：同檔同規則的「新」發現會被一併蓋掉；新檔案或新規則型照常告警。
- fingerprints 一律清空（version 2 格式要求欄位存在，給空列表）。
輸出為平鋪 YAML 手寫，不依賴 pyyaml。冪等：重跑不重複。
"""
import json
import re
import sys
from pathlib import Path

HEADER = """# SkillSpector baseline (rules 制) — 由 scripts/merge-baseline.py 從已判讀報告聯集產生。
# 條目語意：該 rule_id 在該檔案的 findings 已人工判讀接受，之後不再告警。
# 新檔案或新規則型的 findings 不受影響，照常浮出。
version: 2
scanner_version: 2.10.0
fingerprints: []
"""


def yaml_quote(value: str) -> str:
    if re.fullmatch(r"[A-Za-z0-9._/\-]+", value or ""):
        return value
    return "'" + (value or "").replace("'", "''") + "'"


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__)
        return 1
    report_path, baseline_path = Path(sys.argv[1]), Path(sys.argv[2])

    issues = json.loads(report_path.read_text()).get("issues", [])

    rules: dict[tuple[str, str], None] = {}
    if baseline_path.exists():
        for m in re.finditer(
            r"- id: (\S+)\n  path: (.+)", baseline_path.read_text()
        ):
            rules[(m.group(1), m.group(2).strip())] = None

    added = 0
    for issue in issues:
        rule_id = str(issue.get("id") or "UNKNOWN")
        file_ = yaml_quote((issue.get("location") or {}).get("file") or "unknown")
        if (rule_id, file_) not in rules:
            rules[(rule_id, file_)] = None
            added += 1

    lines = [HEADER, "rules:\n" if rules else "rules: []\n"]
    for (rule_id, path) in sorted(rules):
        lines.append(f"- id: {rule_id}\n")
        lines.append(f"  path: {path}\n")
        lines.append("  reason: Accepted finding (triaged 2026-08-27 baseline)\n")
    baseline_path.write_text("".join(lines))
    print(f"{baseline_path.name}: rules {len(rules)} (+{added})")
    return 0


if __name__ == "__main__":
    sys.exit(main())

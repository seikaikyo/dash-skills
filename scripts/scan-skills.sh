#!/bin/bash
#
# 外部 skills 安檢：NVIDIA SkillSpector 靜態掃描
#
# 用法：
#   scan-skills.sh              掃 git 視角下有變更/新增的 external/<name> 頂層目錄
#   scan-skills.sh --all        掃 external/ 全部頂層目錄
#   scan-skills.sh <name>...    指名掃 external/<name>
#
# 判定：max_issue_severity 或 risk_assessment.severity 為 HIGH/CRITICAL 即告警。
# 行為：警報不阻斷（exit 0），告警印終端機加寫 security-reports/findings.log。
# 掃描器未安裝、逾時、個別失敗：明講跳過，不靜默。
# 報告目錄 security-reports/ 已 gitignore（public repo 不對外發布第三方 skill 的漏洞判定）。

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
EXTERNAL_DIR="$REPO_DIR/external"
REPORT_DIR="$REPO_DIR/security-reports"
FINDINGS_LOG="$REPORT_DIR/findings.log"
SCAN_TIMEOUT="${SCAN_SKILLS_TIMEOUT:-240}"   # 每目錄逾時秒數，補掃大目錄時可環境變數拉長
TODAY=$(date +%Y-%m-%d)

if ! command -v skillspector > /dev/null 2>&1; then
    echo "[scan-skills] skillspector 未安裝，跳過安檢（安裝: uv tool install git+https://github.com/NVIDIA/skillspector.git）"
    exit 0
fi

# 決定掃描目標
targets=()
if [ "$1" = "--all" ]; then
    while IFS= read -r d; do
        targets+=("$(basename "$d")")
    done < <(find "$EXTERNAL_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)
elif [ $# -gt 0 ]; then
    targets=("$@")
else
    # git 視角下有變更/新增的 external 頂層目錄（同步後、commit 前呼叫的預設情境）
    while IFS= read -r name; do
        [ -n "$name" ] && targets+=("$name")
    done < <(cd "$REPO_DIR" && { git diff --name-only HEAD -- external/ 2>/dev/null; git status --porcelain external/ 2>/dev/null | awk '{print $2}'; } \
        | sed -n 's|^external/\([^/]*\)/.*|\1|p; s|^external/\([^/]*\)$|\1|p' | sort -u)
fi

if [ ${#targets[@]} -eq 0 ]; then
    echo "[scan-skills] 無變更目錄，跳過安檢"
    exit 0
fi

mkdir -p "$REPORT_DIR"
alerts=0
scanned=0
failed=0

for name in "${targets[@]}"; do
    dir="$EXTERNAL_DIR/$name"
    if [ ! -d "$dir" ]; then
        echo "[scan-skills] 目錄不存在，跳過: $name"
        continue
    fi
    report="$REPORT_DIR/${name}-${TODAY}.json"
    # 人工判讀後接受的誤報指紋（skillspector baseline 產出），有就帶上只報新發現
    baseline_args=()
    if [ -f "$REPORT_DIR/baselines/${name}.yaml" ]; then
        baseline_args=(--baseline "$REPORT_DIR/baselines/${name}.yaml")
    fi
    # skillspector 對高風險判定會 exit 1，報告照樣產出：完成與否看報告有效性，不看 exit code
    rm -f "$report"
    rc=0
    perl -e 'alarm shift; exec @ARGV' "$SCAN_TIMEOUT" \
        skillspector scan "$dir" --no-llm --format json --output "$report" "${baseline_args[@]}" > /dev/null 2>&1 || rc=$?
    if ! jq -e '.risk_assessment' "$report" > /dev/null 2>&1; then
        if [ "$rc" -ge 128 ]; then
            echo "[scan-skills] 掃描逾時（${SCAN_TIMEOUT}s）: $name"
        else
            echo "[scan-skills] 掃描失敗（rc=${rc}）: $name"
        fi
        failed=$((failed + 1))
        continue
    fi
    scanned=$((scanned + 1))

    score=$(jq -r '.risk_assessment.score // "?"' "$report" 2>/dev/null)
    sev=$(jq -r '.risk_assessment.severity // "?"' "$report" 2>/dev/null | tr '[:lower:]' '[:upper:]')
    max_sev=$(jq -r '.risk_assessment.max_issue_severity // "?"' "$report" 2>/dev/null | tr '[:lower:]' '[:upper:]')
    issues=$(jq -r '.issues | length' "$report" 2>/dev/null)

    case "$sev|$max_sev" in
        *HIGH*|*CRITICAL*)
            alerts=$((alerts + 1))
            line="$TODAY $name score=$score severity=$sev max_issue=$max_sev issues=$issues report=$(basename "$report")"
            echo "[scan-skills] 安檢警告: $line"
            echo "$line" >> "$FINDINGS_LOG"
            ;;
        *)
            echo "[scan-skills] 通過: $name score=$score max_issue=$max_sev issues=$issues"
            ;;
    esac
done

echo "[scan-skills] 完成: 掃描 ${scanned}、告警 ${alerts}、失敗 ${failed}"
if [ "$alerts" -gt 0 ]; then
    echo "[scan-skills] 告警明細: ${FINDINGS_LOG}（v1 警報不阻斷，該 skill 仍會被連結，處置由人工判斷）"
fi
exit 0

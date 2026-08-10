#!/bin/bash
#
# Dash Skills Symlink 腳本
# 建立符號連結到 ~/.claude/skills/（開發用）
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
SKILLS_SRC="$REPO_DIR/skills"
EXTERNAL_SRC="$REPO_DIR/external"
SKILLS_DST="$HOME/.claude/skills"

# 深層 skill 覆寫（2026-08-10）：Claude Code 只認 ~/.claude/skills/<name>/SKILL.md 這一層，
# 集合型目錄裡的技能不會被載入。指名連出來，格式 <連結名稱>:<external/ 下相對路徑>。
NESTED_OVERRIDES="ui-ux-pro-max:ui-ux-pro-max/ui-ux-pro-max"

resolve_external_path() {
    local entry
    for entry in $NESTED_OVERRIDES; do
        [ "${entry%%:*}" = "$1" ] || continue
        if [ -f "$EXTERNAL_SRC/${entry#*:}/SKILL.md" ]; then
            echo "$EXTERNAL_SRC/${entry#*:}"
            return
        fi
        echo "  警告: 覆寫目標缺 SKILL.md，改用原路徑: ${entry#*:}" >&2
    done
    echo "$EXTERNAL_SRC/$1"
}

echo "=== Dash Skills Symlink 設定 ==="
echo ""

# 建立目標目錄
mkdir -p "$SKILLS_DST"

# 連結自建 Skills
echo "自建 Skills:"
if [ -d "$SKILLS_SRC" ]; then
    for skill in $(ls -1 "$SKILLS_SRC" 2>/dev/null); do
        src_path="$SKILLS_SRC/$skill"
        dst_path="$SKILLS_DST/$skill"

        # 移除既有的目錄或連結
        if [ -L "$dst_path" ]; then
            echo "  更新連結: $skill"
            rm "$dst_path"
        elif [ -d "$dst_path" ]; then
            echo "  備份並連結: $skill"
            mv "$dst_path" "$dst_path.backup.$(date +%Y%m%d%H%M%S)"
        else
            echo "  建立連結: $skill"
        fi

        ln -s "$src_path" "$dst_path"
    done
else
    echo "  (無)"
fi
echo ""

# 連結外部 Skills
echo "外部 Skills:"
if [ -d "$EXTERNAL_SRC" ]; then
    for skill in $(ls -1 "$EXTERNAL_SRC" 2>/dev/null); do
        src_path="$(resolve_external_path "$skill")"
        dst_path="$SKILLS_DST/$skill"

        if [ -L "$dst_path" ]; then
            echo "  更新連結: $skill"
            rm "$dst_path"
        elif [ -d "$dst_path" ]; then
            echo "  備份並連結: $skill"
            mv "$dst_path" "$dst_path.backup.$(date +%Y%m%d%H%M%S)"
        else
            echo "  建立連結: $skill"
        fi

        ln -s "$src_path" "$dst_path"
    done
else
    echo "  (無)"
fi
echo ""

echo "Symlink 設定完成!"
echo ""
echo "現在你可以直接編輯 repo 中的 skills，變更會即時生效。"

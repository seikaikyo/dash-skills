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
# 集合型目錄裡的技能不會被載入。指名連出來，格式 <連結名稱>:<來源根目錄下相對路徑>。
# ui-ux-pro-max 2026-10-25 內化到 skills/，覆寫對自建與外部兩個來源都適用。
NESTED_OVERRIDES="ui-ux-pro-max:ui-ux-pro-max/ui-ux-pro-max"

resolve_nested_path() {
    local name="$1" base="$2" entry
    for entry in $NESTED_OVERRIDES; do
        [ "${entry%%:*}" = "$name" ] || continue
        if [ -f "$base/${entry#*:}/SKILL.md" ]; then
            echo "$base/${entry#*:}"
            return
        fi
    done
    echo "$base/$name"
}

echo "=== Dash Skills Symlink 設定 ==="
echo ""

# 建立目標目錄
mkdir -p "$SKILLS_DST"

# 連結自建 Skills
echo "自建 Skills:"
if [ -d "$SKILLS_SRC" ]; then
    for skill in $(ls -1 "$SKILLS_SRC" 2>/dev/null); do
        src_path="$(resolve_nested_path "$skill" "$SKILLS_SRC")"
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
        src_path="$(resolve_nested_path "$skill" "$EXTERNAL_SRC")"
        dst_path="$SKILLS_DST/$skill"

        # 跳過空殼：移除一個收錄 skill 後，git rm 清不掉未追蹤的 .cc-writes 暫存目錄，
        # 會留下一個沒有任何檔案的空目錄。連結它會讓已移除的 skill 名稱又出現在 ~/.claude/skills。
        if [ -z "$(find "$src_path" -type f -print -quit 2>/dev/null)" ]; then
            echo "  跳過空目錄: $skill"
            continue
        fi

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

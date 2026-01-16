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
        src_path="$EXTERNAL_SRC/$skill"
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

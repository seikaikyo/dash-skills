#!/bin/bash
#
# Dash Skills 安裝腳本
# 將 skills/ 和 external/ 複製到 ~/.claude/skills/
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
SKILLS_SRC="$REPO_DIR/skills"
EXTERNAL_SRC="$REPO_DIR/external"
SKILLS_DST="$HOME/.claude/skills"

echo "=== Dash Skills 安裝程式 ==="
echo ""

# 建立目標目錄
mkdir -p "$SKILLS_DST"

# 安裝自建 Skills
echo "自建 Skills:"
if [ -d "$SKILLS_SRC" ]; then
    for skill in $(ls -1 "$SKILLS_SRC" 2>/dev/null); do
        src_path="$SKILLS_SRC/$skill"
        dst_path="$SKILLS_DST/$skill"

        if [ -d "$dst_path" ] || [ -L "$dst_path" ]; then
            echo "  更新: $skill"
            rm -rf "$dst_path"
        else
            echo "  安裝: $skill"
        fi

        cp -r "$src_path" "$dst_path"
    done
else
    echo "  (無)"
fi
echo ""

# 安裝外部 Skills
echo "外部 Skills:"
if [ -d "$EXTERNAL_SRC" ]; then
    for skill in $(ls -1 "$EXTERNAL_SRC" 2>/dev/null); do
        src_path="$EXTERNAL_SRC/$skill"
        dst_path="$SKILLS_DST/$skill"

        if [ -d "$dst_path" ] || [ -L "$dst_path" ]; then
            echo "  更新: $skill"
            rm -rf "$dst_path"
        else
            echo "  安裝: $skill"
        fi

        cp -r "$src_path" "$dst_path"
    done
else
    echo "  (無)"
fi
echo ""

echo "安裝完成!"
echo ""
echo "已安裝的 Skills:"
echo "  [自建]"
ls -1 "$SKILLS_SRC" 2>/dev/null | while read skill; do
    echo "    - $skill"
done
echo "  [外部]"
ls -1 "$EXTERNAL_SRC" 2>/dev/null | while read skill; do
    echo "    - $skill"
done
echo ""
echo "使用方式: 在 Claude Code 中輸入 /skill-name"

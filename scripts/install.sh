#!/bin/bash
#
# Dash Skills 安裝腳本
# 將 skills 複製到 ~/.claude/skills/
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
SKILLS_SRC="$REPO_DIR/skills"
SKILLS_DST="$HOME/.claude/skills"

echo "=== Dash Skills 安裝程式 ==="
echo ""

# 檢查來源目錄
if [ ! -d "$SKILLS_SRC" ]; then
    echo "錯誤: 找不到 skills 目錄: $SKILLS_SRC"
    exit 1
fi

# 建立目標目錄
mkdir -p "$SKILLS_DST"

# 取得要安裝的 skills 列表
SKILLS=$(ls -1 "$SKILLS_SRC")

echo "將安裝以下 Skills:"
for skill in $SKILLS; do
    echo "  - $skill"
done
echo ""

# 複製 skills
for skill in $SKILLS; do
    src_path="$SKILLS_SRC/$skill"
    dst_path="$SKILLS_DST/$skill"

    if [ -d "$dst_path" ]; then
        echo "更新: $skill"
        rm -rf "$dst_path"
    else
        echo "安裝: $skill"
    fi

    cp -r "$src_path" "$dst_path"
done

echo ""
echo "安裝完成!"
echo ""
echo "已安裝的 Skills:"
ls -1 "$SKILLS_DST" | grep -E "^(angular-primeng|vue-daisyui|fastapi-patterns)$" | while read skill; do
    echo "  - $skill"
done
echo ""
echo "使用方式: 在 Claude Code 中輸入 /skill-name"

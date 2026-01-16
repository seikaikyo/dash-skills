#!/bin/bash
#
# Dash Skills Symlink 腳本
# 建立符號連結到 ~/.claude/skills/（開發用）
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
SKILLS_SRC="$REPO_DIR/skills"
SKILLS_DST="$HOME/.claude/skills"

echo "=== Dash Skills Symlink 設定 ==="
echo ""

# 檢查來源目錄
if [ ! -d "$SKILLS_SRC" ]; then
    echo "錯誤: 找不到 skills 目錄: $SKILLS_SRC"
    exit 1
fi

# 建立目標目錄
mkdir -p "$SKILLS_DST"

# 取得要連結的 skills 列表
SKILLS=$(ls -1 "$SKILLS_SRC")

echo "將建立以下 Symlinks:"
for skill in $SKILLS; do
    echo "  $SKILLS_DST/$skill -> $SKILLS_SRC/$skill"
done
echo ""

# 建立 symlinks
for skill in $SKILLS; do
    src_path="$SKILLS_SRC/$skill"
    dst_path="$SKILLS_DST/$skill"

    # 移除既有的目錄或連結
    if [ -L "$dst_path" ]; then
        echo "更新連結: $skill"
        rm "$dst_path"
    elif [ -d "$dst_path" ]; then
        echo "警告: $dst_path 是目錄，將備份後建立連結"
        mv "$dst_path" "$dst_path.backup.$(date +%Y%m%d%H%M%S)"
    else
        echo "建立連結: $skill"
    fi

    ln -s "$src_path" "$dst_path"
done

echo ""
echo "Symlink 設定完成!"
echo ""
echo "現在你可以直接編輯 repo 中的 skills，變更會即時生效。"

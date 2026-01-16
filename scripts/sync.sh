#!/bin/bash
#
# Dash Skills 同步腳本
# 將 repo 中的 skills 同步到 ~/.claude/skills/
# 支援增量更新（只更新有變動的檔案）
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
SKILLS_SRC="$REPO_DIR/skills"
SKILLS_DST="$HOME/.claude/skills"

echo "=== Dash Skills 同步 ==="
echo ""

# 檢查來源目錄
if [ ! -d "$SKILLS_SRC" ]; then
    echo "錯誤: 找不到 skills 目錄: $SKILLS_SRC"
    exit 1
fi

# 建立目標目錄
mkdir -p "$SKILLS_DST"

# 取得 skills 列表
SKILLS=$(ls -1 "$SKILLS_SRC")

updated=0
skipped=0

for skill in $SKILLS; do
    src_path="$SKILLS_SRC/$skill"
    dst_path="$SKILLS_DST/$skill"

    # 如果目標是 symlink，跳過
    if [ -L "$dst_path" ]; then
        echo "跳過 (symlink): $skill"
        ((skipped++))
        continue
    fi

    # 檢查是否需要更新
    if [ -d "$dst_path" ]; then
        # 比較 SKILL.md 的修改時間
        src_md="$src_path/SKILL.md"
        dst_md="$dst_path/SKILL.md"

        if [ -f "$src_md" ] && [ -f "$dst_md" ]; then
            if [ "$src_md" -nt "$dst_md" ]; then
                echo "更新: $skill"
                rm -rf "$dst_path"
                cp -r "$src_path" "$dst_path"
                ((updated++))
            else
                echo "略過 (已是最新): $skill"
                ((skipped++))
            fi
        else
            echo "更新: $skill"
            rm -rf "$dst_path"
            cp -r "$src_path" "$dst_path"
            ((updated++))
        fi
    else
        echo "新增: $skill"
        cp -r "$src_path" "$dst_path"
        ((updated++))
    fi
done

echo ""
echo "同步完成!"
echo "  更新: $updated"
echo "  略過: $skipped"

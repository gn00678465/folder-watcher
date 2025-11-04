#!/bin/bash
# setup-user.sh
# 處理 PUID/PGID 使用者和群組的建立

setup_user_and_group() {
    local PUID="${1:-99}"
    local PGID="${2:-100}"
    
    echo "========================================"
    echo "設定使用者和群組"
    echo "========================================"
    echo "目標 UID: $PUID"
    echo "目標 GID: $PGID"
    echo ""
    
    # 設定群組
    if getent group "$PGID" > /dev/null 2>&1; then
        # 群組已存在
        existing_group=$(getent group "$PGID" | cut -d: -f1)
        echo "✓ 群組已存在: $existing_group (GID: $PGID)"
        GROUP_NAME="$existing_group"
    else
        # 建立新群組
        echo "建立群組 abc (GID: $PGID)"
        if addgroup -g "$PGID" abc 2>/dev/null; then
            echo "✓ 群組建立成功: abc (GID: $PGID)"
            GROUP_NAME="abc"
        else
            echo "✗ 群組建立失敗"
            return 1
        fi
    fi
    
    # 設定使用者
    if getent passwd "$PUID" > /dev/null 2>&1; then
        # 使用者已存在
        existing_user=$(getent passwd "$PUID" | cut -d: -f1)
        echo "✓ 使用者已存在: $existing_user (UID: $PUID)"
        USER_NAME="$existing_user"
    else
        # 建立新使用者
        echo "建立使用者 abc (UID: $PUID, GID: $PGID)"
        if adduser -D -u "$PUID" -G "$GROUP_NAME" -s /bin/bash abc 2>/dev/null; then
            echo "✓ 使用者建立成功: abc (UID: $PUID)"
            USER_NAME="abc"
        else
            echo "✗ 使用者建立失敗"
            return 1
        fi
    fi
    
    echo ""
    echo "最終使用者資訊:"
    echo "  使用者: $USER_NAME (UID: $PUID)"
    echo "  群組: $GROUP_NAME (GID: $PGID)"
    echo "========================================"
    echo ""
    
    return 0
}

# 如果直接執行此腳本(非 source)
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    setup_user_and_group "${1:-99}" "${2:-100}"
fi
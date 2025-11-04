#!/bin/bash
# entrypoint.sh

# LinuxServer.io 風格的 PUID/PGID 處理
PUID="${PUID:-99}"
PGID="${PGID:-100}"

WATCH_DIR="${WATCH_DIR:-/watch}"
PERMISSIONS="${PERMISSIONS:-777}"
SETTLE_TIME="${SETTLE_TIME:-3}"
CHECK_INTERVAL="${CHECK_INTERVAL:-1}"

# 使用臨時檔案來儲存待處理項目
PENDING_FILE="/tmp/pending_items.txt"
LOCK_FILE="/tmp/pending_items.lock"

echo "========================================"
echo "資料夾權限監控服務啟動"
echo "========================================"
echo "使用者 ID (PUID): $PUID"
echo "群組 ID (PGID): $PGID"
echo "監聽路徑: $WATCH_DIR"
echo "目標權限: $PERMISSIONS"
echo "穩定等待: ${SETTLE_TIME}秒"
echo "========================================"
echo ""

# 載入並執行使用者設定腳本
source /setup-user.sh
if ! setup_user_and_group "$PUID" "$PGID"; then
    echo "錯誤: 使用者和群組設定失敗"
    exit 1
fi

# 初始化檔案
> "$PENDING_FILE"

# 加鎖函數
lock() {
    while ! mkdir "$LOCK_FILE" 2>/dev/null; do
        sleep 0.01
    done
}

# 解鎖函數
unlock() {
    rmdir "$LOCK_FILE" 2>/dev/null
}

# 背景處理程序 - 處理穩定的項目
process_settled_items() {
    while true; do
        sleep "$CHECK_INTERVAL"
        current_time=$(date +%s)
        
        lock
        
        # 讀取待處理項目
        if [ -s "$PENDING_FILE" ]; then
            # 建立臨時檔案存放仍需等待的項目
            temp_file="${PENDING_FILE}.processing"
            > "$temp_file"
            
            while IFS='|' read -r item last_time; do
                time_diff=$((current_time - last_time))
                
                # 如果項目已經穩定
                if [ $time_diff -ge $SETTLE_TIME ]; then
                    if [ -e "$item" ]; then
                        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 處理穩定項目: $item"
                        
                        # 判斷是檔案還是資料夾
                        if [ -d "$item" ]; then
                            # 資料夾:遞迴設定
                            if chown -R "$PUID:$PGID" "$item" 2>/dev/null; then
                                echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✓ 已設定資料夾擁有者: $PUID:$PGID"
                            else
                                echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✗ 設定資料夾擁有者失敗"
                            fi
                            
                            if chmod -R "$PERMISSIONS" "$item" 2>/dev/null; then
                                echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✓ 已設定資料夾權限: $PERMISSIONS"
                            else
                                echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✗ 設定資料夾權限失敗"
                            fi
                        else
                            # 檔案
                            if chown "$PUID:$PGID" "$item" 2>/dev/null; then
                                echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✓ 已設定檔案擁有者: $PUID:$PGID"
                            else
                                echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✗ 設定檔案擁有者失敗"
                            fi
                            
                            if chmod "$PERMISSIONS" "$item" 2>/dev/null; then
                                echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✓ 已設定檔案權限: $PERMISSIONS"
                            else
                                echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✗ 設定檔案權限失敗"
                            fi
                        fi
                        
                        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 完成處理: $item"
                        echo ""
                    else
                        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⚠ 項目已不存在,跳過: $item"
                    fi
                else
                    # 仍需等待,保留此項目
                    echo "$item|$last_time" >> "$temp_file"
                fi
            done < "$PENDING_FILE"
            
            # 更新待處理列表
            mv "$temp_file" "$PENDING_FILE"
        fi
        
        unlock
    done
}

# 啟動背景處理程序
process_settled_items &
PROCESSOR_PID=$!

# 清理函數
cleanup() {
    echo ""
    echo "========================================"
    echo "正在停止服務..."
    echo "========================================"
    kill $PROCESSOR_PID 2>/dev/null
    wait $PROCESSOR_PID 2>/dev/null
    rm -f "$PENDING_FILE" "$LOCK_FILE" "${PENDING_FILE}.processing"
    echo "服務已停止"
    exit 0
}

trap cleanup SIGTERM SIGINT EXIT

# 監聽事件並更新待處理項目的時間戳記
echo "開始監聽事件..."
echo ""

inotifywait -m -r \
    -e create \
    -e moved_to \
    --format '%e %w%f' \
    "$WATCH_DIR" 2>/dev/null | while read event item
do
    # 過濾掉臨時檔案和隱藏檔案
    basename_item=$(basename "$item")
    if [[ "$basename_item" =~ ^\. ]] || [[ "$basename_item" =~ ~$ ]] || [[ "$basename_item" =~ \.tmp$ ]]; then
        continue
    fi
    
    current_time=$(date +%s)
    
    lock
    
    # 檢查項目是否已在列表中
    item_exists=false
    if [ -s "$PENDING_FILE" ]; then
        temp_file="${PENDING_FILE}.update"
        > "$temp_file"
        
        while IFS='|' read -r existing_item existing_time; do
            if [ "$existing_item" = "$item" ]; then
                # 更新時間
                echo "$item|$current_time" >> "$temp_file"
                item_exists=true
            else
                # 保留其他項目
                echo "$existing_item|$existing_time" >> "$temp_file"
            fi
        done < "$PENDING_FILE"
        
        mv "$temp_file" "$PENDING_FILE"
    fi
    
    # 如果是新項目,加入列表
    if [ "$item_exists" = false ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 偵測到變更 ($event): $item"
        echo "$item|$current_time" >> "$PENDING_FILE"
    fi
    
    unlock
done
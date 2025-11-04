# Folder Permission Watcher

監控資料夾並自動設定檔案權限和擁有者。

## 使用方式

### Docker Compose (推薦)

```yaml
version: '3.8'

services:
  folder-watcher:
    image: folder-watcher:latest
    container_name: folder-watcher
    environment:
      - PUID=99        # 使用者 ID
      - PGID=100       # 群組 ID
      - WATCH_DIR=/watch
      - PERMISSIONS=777
      - SETTLE_TIME=3
    volumes:
      - /mnt/user/your-folder:/watch
    restart: unless-stopped
```

## 環境變數

| 變數 | 預設值 | 說明 |
|------|--------|------|
| `PUID` | `99` | 使用者 ID (Unraid 預設為 99=nobody) |
| `PGID` | `100` | 群組 ID (Unraid 預設為 100=users) |
| `WATCH_DIR` | `/watch` | 要監聽的資料夾路徑 |
| `PERMISSIONS` | `777` | 要設定的權限 (八進位格式) |
| `SETTLE_TIME` | `3` | 等待檔案穩定的秒數 |
| `CHECK_INTERVAL` | `1` | 檢查待處理項目的間隔秒數 |

## 在 Unraid 上使用

1. 找出你要使用的使用者 ID:
```bash
id nobody
# 輸出: uid=99(nobody) gid=100(users)
```

2. 在 docker-compose.yml 設定:
```yaml
environment:
  - PUID=99
  - PGID=100
```

## 權限設定範例

| 權限值 | 八進位 | 說明 |
|--------|--------|------|
| `rwxrwxrwx` | `777` | 所有人可讀寫執行 |
| `rwxr-xr-x` | `755` | 擁有者全權限,其他人唯讀執行 |
| `rw-rw-rw-` | `666` | 所有人可讀寫 |
| `rw-r--r--` | `644` | 擁有者可讀寫,其他人唯讀 |
```

## 建置和部署

```bash
# 建置映像檔
docker-compose build

# 啟動服務
docker-compose up -d

# 查看日誌
docker-compose logs -f

# 停止服務
docker-compose down
```

## 預期輸出

```
========================================
資料夾權限監控服務啟動
========================================
使用者 ID (PUID): 99
群組 ID (PGID): 100
監聽路徑: /watch
目標權限: 777
穩定等待: 3秒
========================================
設定使用者和群組...
建立群組 abc (GID: 100)
建立使用者 abc (UID: 99, GID: 100)
========================================

開始監聽事件...

[2025-11-04 10:00:00] 偵測到變更 (CREATE,ISDIR): /watch/test1
[2025-11-04 10:00:01] 偵測到變更 (CREATE): /watch/test1/file1.txt
[2025-11-04 10:00:04] 處理穩定項目: /watch/test1
[2025-11-04 10:00:04] ✓ 已設定資料夾擁有者: 99:100
[2025-11-04 10:00:04] ✓ 已設定資料夾權限: 777
[2025-11-04 10:00:04] 完成處理: /watch/test1
```

現在你的設定就跟 LinuxServer.io 的容器一樣使用 `PUID` 和 `PGID` 了!
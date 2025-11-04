# Folder Watcher

監控資料夾，檔案穩定後自動 chown/chmod。

快速啟動：

```
docker compose up -d --build
docker logs -f folder-watcher
```

主要 env：`WATCH_DIR`、`PERMISSIONS`、`OWNER`、`SETTLE_TIME`

## 環境變數說明

- `WATCH_DIR`: 監聽的資料夾路徑，預設為 `/watch`。
- `PERMISSIONS`: 要設定的檔案權限，預設為 `777` (rwxrwxrwx)。
- `OWNER`: 要設定的檔案擁有者，格式為 `user:group` 或 `uid:gid`，預設為 `nobody:users`。如果不設定則不變更擁有者。
- `SETTLE_TIME`: 等待檔案穩定的時間（秒），預設為 `3` 秒。
- `CHECK_INTERVAL`: 檢查間隔（秒），預設為 `1` 秒。
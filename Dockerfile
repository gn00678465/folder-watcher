FROM alpine:latest

# 安裝必要工具
RUN apk add --no-cache \
    inotify-tools \
    bash \
    coreutils \
    shadow

# 複製腳本
COPY setup-user.sh /setup-user.sh
COPY entrypoint.sh /entrypoint.sh

# 設定執行權限
RUN chmod +x /setup-user.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
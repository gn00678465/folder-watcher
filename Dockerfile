FROM alpine:latest

# 安裝必要工具
RUN apk add --no-cache \
    inotify-tools \
    bash \
    coreutils

# 複製腳本
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 設定工作目錄
WORKDIR /

ENTRYPOINT ["/entrypoint.sh"]
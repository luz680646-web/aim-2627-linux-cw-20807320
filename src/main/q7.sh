#!/bin/bash
# Q7：读取 input/remote.env，生成 ssh_config，用 SSH 和 SCP 获取远程数据。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

source "$input/remote.env"

# 配置只保存在本题输出目录，使用本次测试提供的身份和主机记录。
config="$output/ssh_config"
umask 077
cat > "$config" <<EOF
Host aim-sentry
    HostName "$HOST"
    Port $PORT
    User "$REMOTE_USER"
    IdentityFile "$KEY_PATH"
    UserKnownHostsFile "$KNOWN_HOSTS"
    IdentitiesOnly yes
    IdentityAgent none
    StrictHostKeyChecking yes
    BatchMode yes
    ConnectTimeout 3
EOF
chmod 600 "$config"

# 真实连接远端执行命令，并通过 SCP 获取日志。
ssh -F "$config" aim-sentry whoami > "$output/remote-user.txt"
mkdir -p "$output/received"
scp -F "$config" "aim-sentry:$REMOTE_LOG" "$output/received/errors.log"

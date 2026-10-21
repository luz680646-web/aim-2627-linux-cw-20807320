#!/bin/bash
# Q8：repair 时识别并停止采集器、修复 HTTP 服务；cleanup 时停止修复后的服务。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

action=${3:-repair}

source "$input/process.env"

# 仅向指定 PID 发送 TERM，并等待退出；僵尸进程已停止运行。
stop_process() {
    local pid=$1 state attempt
    case "$pid" in ''|*[!0-9]*) return 1 ;; esac
    [ "$pid" -gt 1 ] || return 1
    if kill -0 "$pid" 2>/dev/null; then
        kill -TERM "$pid" || return 1
    fi
    for ((attempt=0; attempt<50; attempt++)); do
        state=$(ps -p "$pid" -o stat= 2>/dev/null) || return 0
        case "$state" in ''|*Z*) return 0 ;; esac
        sleep 0.05
    done
    printf 'Process %s did not stop in time\n' "$pid" >&2
    return 1
}

case "$action" in
    cleanup)
        if [ -f "$output/service/pid" ]; then
            stop_process "$(cat "$output/service/pid")"
        fi
        exit 0
        ;;
    repair) ;;
    *) printf 'Unknown action: %s\n' "$action" >&2; exit 1 ;;
esac

# 从 ps 获取真实进程信息，最后一个变量保留完整命令行。
read -r pid owner state command < <(ps -ww -p "$TARGET_PID" -o pid=,user=,stat=,args=)
[ "$pid" = "$TARGET_PID" ]
case "$command" in
    *"$TARGET_TOKEN"*) ;;
    *) printf '%s\n' 'Collector identity does not match' >&2; exit 1 ;;
esac
printf 'pid=%s\nuser=%s\nstate=%s\ncommand=%s\n' \
    "$pid" "$owner" "$state" "$command" > "$output/process.txt"

# 保留目标采集器的 TICK 记录，再正常停止它及旧 HTTP 服务。
grep -F "TICK $TARGET_TOKEN " "$WORKER_LOG" > "$output/collector-sample.log"
stop_process "$TARGET_PID"
stop_process "$SERVICE_PID"

printf 'bind=127.0.0.1\nport=%s\nroute=/status\n' \
    "$TARGET_PORT" > "$output/server.conf"
bash "$START_TOOL" "$output/server.conf" "$output/service"

# 等待服务就绪，保存真实 HTTP 状态码与响应体；最多等待约 5 秒。
deadline=$((SECONDS + 5))
while [ "$SECONDS" -lt "$deadline" ]; do
    if curl --noproxy '*' --silent --show-error --max-time 1 \
        --output "$output/http-body.txt" --write-out '%{http_code}\n' \
        "http://127.0.0.1:$TARGET_PORT/status" > "$output/http-status.txt"; then
        if [ "$(cat "$output/http-status.txt")" = 200 ] && \
            [ "$(cat "$output/http-body.txt")" = 'SENTRY READY' ]; then
            # repair 返回时保持服务运行，交给后续 cleanup 停止。
            exit 0
        fi
    fi
    sleep 0.1
done
printf '%s\n' 'HTTP service did not become ready in time' >&2
stop_process "$(cat "$output/service/pid")"
exit 1

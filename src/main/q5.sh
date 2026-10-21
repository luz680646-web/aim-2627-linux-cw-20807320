#!/bin/bash
# Q5：运行 launch.env 给定的启动前检查，保存 stdout/stderr、真实退出码和诊断报告。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

# 使用测试器提供的路径，运行真实的启动检查。
source "$input/launch.env"
if bash "$LAUNCH_TOOL" "$MODEL_PATH" "$CAMERA_PATH" \
    > "$output/stdout.log" 2> "$output/stderr.log"; then
    code=0
else
    # 必须立即保存失败命令的状态，避免被后续命令覆盖。
    code=$?
fi
printf '%s\n' "$code" > "$output/exit-code.txt"

case "$code" in
    0) result=SUCCESS; reason=NONE ;;
    10) result=FAILED; reason=MODEL_MISSING ;;
    20) result=FAILED; reason=CAMERA_DENIED ;;
    *) printf 'Unexpected preflight exit code: %s\n' "$code" >&2; exit 1 ;;
esac

# 检查失败也是需要记录的正常场景；完成报告后脚本正常退出。
printf 'result=%s\nexit_code=%s\nreason=%s\n' \
    "$result" "$code" "$reason" > "$output/report.txt"

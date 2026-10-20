#!/bin/bash
# Q4：合并日志，按级别提取，保存首尾片段并统计错误行数。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

# 按启动日志、运行日志的顺序合并，保留原始顺序及重复记录。
cat -- "$input/boot.log" "$input/run.log" > "$output/all.log"

# 只匹配行首级别；grep 返回 1 表示没有匹配，是正常情况。
# 其他错误仍会使脚本退出，避免掩盖文件读取等问题。
grep '^ERROR ' "$output/all.log" > "$output/errors.log" || [ "$?" -eq 1 ]
grep -E '^(WARN|ERROR) ' "$output/all.log" > "$output/attention.log" || [ "$?" -eq 1 ]

tail -n 5 "$output/all.log" > "$output/recent.log"
head -n 3 "$output/errors.log" > "$output/first-errors.log"

# printf 去掉 wc 可能添加的对齐空格，输出一个整数和换行。
count=$(wc -l < "$output/errors.log")
printf '%d\n' "$count" > "$output/error-count.txt"

#!/bin/bash
# Q6：将本地 Debian 包安装到 output/sysroot，运行安装后的工具。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

# 将文件和 dpkg 数据库都放在本题输出目录内。
sysroot="$output/sysroot"
mkdir -p "$sysroot"

# 普通用户安装本地包；日志不写入系统的 /var/log/dpkg.log。
dpkg --root="$sysroot" --force-not-root --log=/dev/null \
    --install "$input/aim-sentry-tools.deb"

# 运行实际安装的工具，由包本身决定输出及版本号。
"$sysroot/usr/bin/aim-sentry-info" > "$output/tool-output.txt"

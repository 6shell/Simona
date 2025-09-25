#!/bin/bash
#
# GNU Screen 自动会话部署脚本
# - 兼容多种 Linux 发行版，自动安装 screen。
# - 修改 /etc/profile 实现所有用户登录时自动进入/创建 screen 会话。
# - 具备幂等性，防止重复配置。
# - 修复了在 /etc/profile 中使用 'local' 关键字的问题。

# --- 脚本设置与变量 ---

# 立即退出脚本，如果任何命令执行失败
set -e

# 定义配置的边界标记
MARKER_START="# >>> START: GNU Screen Auto-Session Config <<<"
MARKER_END="# <<< END: GNU Screen Auto-Session Config <<<"
PROFILE_FILE="/etc/profile"

echo "🔧 开始部署 GNU Screen 自动会话管理..."

# --- 核心函数：安装 screen ---

install_screen() {
    # 检查 screen 是否已安装
    if command -v screen >/dev/null 2>&1; then
        echo "✅ screen 已安装，跳过安装步骤。"
        return 0
    fi

    # 查找可用的包管理器并安装
    local pkg_manager
    if command -v apt >/dev/null 2>&1; then
        pkg_manager="apt"
    elif command -v yum >/dev/null 2>&1; then
        pkg_manager="yum"
    elif command -v dnf >/dev/null 2>&1; then
        pkg_manager="dnf"
    elif command -v zypper >/dev/null 2>&1; then
        pkg_manager="zypper"
    elif command -v pacman >/dev/null 2>&1; then
        pkg_manager="pacman"
    elif command -v apk >/dev/null 2>&1; then
        pkg_manager="apk"
    fi

    if [[ -n "$pkg_manager" ]]; then
        echo "📦 使用 $pkg_manager 安装 screen..."
        case "$pkg_manager" in
            apt)
                DEBIAN_FRONTEND=noninteractive apt update -y
                DEBIAN_FRONTEND=noninteractive apt install screen -y
                ;;
            yum|dnf)
                "$pkg_manager" install screen -y
                ;;
            zypper)
                zypper install -y screen
                ;;
            pacman)
                pacman -Sy --noconfirm screen
                ;;
            apk)
                # --no-cache 避免缓存膨胀
                apk add --no-cache screen
                ;;
        esac
    else
        echo "❌ 未识别的包管理器，请手动安装 screen 后再运行脚本。"
        exit 1
    fi
}

# --- 核心函数：配置 /etc/profile ---

configure_profile() {
    # 检查是否已存在配置 (使用开始标记作为检查点)
    if grep -qF "$MARKER_START" "$PROFILE_FILE"; then
        echo "✅ 检测到 GNU Screen 自动会话配置已存在于 $PROFILE_FILE，跳过添加。"
        return 0
    fi

    echo "📝 添加自动 screen 会话逻辑到 $PROFILE_FILE..."

    # 使用单引号 'EOF_CONFIG' 防止 $ 符号在写入前被 Bash 错误解释。
    # **关键修正：移除了 'local' 关键字**
    cat <<'EOF_CONFIG' >> "$PROFILE_FILE"

$MARKER_START
# 仅在交互式 shell 中且不在 screen 会话中执行
# \$-: Current options set for the shell. *i* indicates interactive shell.
if [[ \$- == *i* ]]; then
    # 检查是否已在 screen 会话中 (\$STY 变量存在时表示在会话内)
    if [ -z "\$STY" ]; then
        # 获取当前用户名作为会话名 (使用普通的 Shell 变量)
        SESSION_NAME="\$(id -un)"

        # 清理可能残留的死会话 (错误输出重定向到 /dev/null 防止干扰)
        screen -wipe > /dev/null 2>&1

        # -R: 尽可能恢复已有的会话。如果不存在，则创建一个新的同名会话。
        screen -R "\$SESSION_NAME"
    fi
fi
$MARKER_END
EOF_CONFIG

    # 检查追加是否成功
    if grep -qF "$MARKER_END" "$PROFILE_FILE"; then
        echo "✅ 配置已成功添加到 $PROFILE_FILE。"
        echo "🔔 提示：请运行 'source $PROFILE_FILE' 或重新登录验证效果。"
    else
        echo "❌ 配置追加失败，请检查文件系统或磁盘空间。"
        exit 1
    fi
}

# --- 部署执行 ---

install_screen
configure_profile

echo "🎉 部署完成。"

#!/bin/bash
#
# GNU Screen 自动会话部署脚本
# - 兼容多种 Linux 发行版，自动安装 screen。
# - 修改 /etc/profile 实现所有用户登录时自动进入/创建 screen 会话。
# - 具备幂等性 (Idempotency)，防止重复配置。

# --- 脚本设置与变量 ---

# 立即退出脚本，如果任何命令执行失败
set -e

# 设置一个更具描述性的标记，用于检测和边界
MARKER_START="# >>> START: GNU Screen Auto-Session Config <<<"
MARKER_END="# <<< END: GNU Screen Auto-Session Config <<<"
PROFILE_FILE="/etc/profile"

echo "🔧 开始部署 GNU Screen 自动会话管理..."

# --- 核心函数：安装 screen ---

install_screen() {
    # 查找可用的包管理器
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

    if command -v screen >/dev/null 2>&1; then
        echo "✅ screen 已安装，跳过安装步骤。"
        return 0
    fi

    if [[ -n "$pkg_manager" ]]; then
        echo "📦 使用 $pkg_manager 安装 screen..."
        case "$pkg_manager" in
            apt)
                # 使用非交互模式避免可能的提示
                DEBIAN_FRONTEND=noninteractive apt update -y
                DEBIAN_FRONTEND=noninteractive apt install screen -y
                ;;
            yum|dnf)
                # yum/dnf 确保使用 -y
                "$pkg_manager" install screen -y
                ;;
            zypper)
                zypper install -y screen
                ;;
            pacman)
                # pacman 需要先同步数据库
                pacman -Sy --noconfirm screen
                ;;
            apk)
                apk add --no-cache screen
                ;;
        esac
    else
        echo "❌ 未识别的包管理器，请手动安装 screen 后再运行脚本。"
        exit 1
    fi
}

# --- 执行安装 ---
install_screen

# --- 核心函数：配置 /etc/profile ---

configure_profile() {
    # 检查是否已存在配置 (使用开始标记作为检查点)
    if grep -qF "$MARKER_START" "$PROFILE_FILE"; then
        echo "✅ 检测到 GNU Screen 自动会话配置已存在于 $PROFILE_FILE，跳过添加。"
        return 0
    fi

    echo "📝 添加自动 screen 会话逻辑到 $PROFILE_FILE..."

    # 使用 'cat <<'EOF'' 追加配置，提高可读性和避免引号转义问题
    cat <<'EOF_CONFIG' >> "$PROFILE_FILE"

$MARKER_START
# 仅在交互式、非 SSH 连接内且非 STY 环境变量已设置 (即不在 screen 内) 时执行。
# 排除 SSH 连接 (如 \$\$SSH_TTY) 可以避免某些环境下的双重启动或兼容性问题，但原脚本没有排除，这里保留原逻辑，只优化结构。
# 使用 \$* 替代 \$- 来检查交互式 shell (更可靠，感谢原作者使用 \$-)
# \$-: Current options set for the shell. *i* indicates interactive shell.
if [[ \$- == *i* ]]; then
    # 检查是否已在 screen 会话中
    if [ -z "\$STY" ]; then
        # 获取当前用户名作为会话名
        local SESSION_NAME
        SESSION_NAME="\$(id -un)"

        # 清理可能残留的死会话 (可选，但推荐)
        # 错误输出重定向到 /dev/null 防止干扰，但保留成功输出
        screen -wipe > /dev/null 2>&1

        # -R: 尽可能恢复已有的会话。如果不存在，则创建一个新的同名会话。
        screen -R "\$SESSION_NAME"
    fi
fi
$MARKER_END
EOF_CONFIG

    # 检查追加是否成功 (简单检查，不精确但能捕捉基本错误)
    if grep -qF "$MARKER_END" "$PROFILE_FILE"; then
        echo "✅ 配置已成功添加到 $PROFILE_FILE。"
        echo "🔔 提示：请运行 'source $PROFILE_FILE' 或重新登录验证效果。"
    else
        echo "❌ 配置追加失败，请检查脚本权限和文件系统。"
        exit 1
    fi
}

# --- 执行配置 ---
configure_profile

echo "🎉 部署完成。"

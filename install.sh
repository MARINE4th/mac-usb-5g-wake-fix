#!/bin/bash
# Mac 端一键安装：./install.sh [SwiftBar 插件目录]
set -e
cd "$(dirname "$0")"

command -v brew >/dev/null || { echo "未找到 Homebrew，请先安装：https://brew.sh"; exit 1; }
brew list sleepwatcher >/dev/null 2>&1 || brew install sleepwatcher
command -v adb >/dev/null || brew install --cask android-platform-tools

mkdir -p "$HOME/.usbnet"
if [ ! -f "$HOME/.usbnet/config" ]; then
  cp mac/config.example "$HOME/.usbnet/config"
  echo "已创建 ~/.usbnet/config，请填入 SERIAL 和 IF 后再测试"
fi

install -m 755 mac/reconnect.sh "$HOME/.usbnet/reconnect.sh"
if [ -f "$HOME/.wakeup" ] && ! cmp -s mac/wakeup.sh "$HOME/.wakeup"; then
  cp "$HOME/.wakeup" "$HOME/.wakeup.bak"
  echo "原有的 ~/.wakeup 已备份为 ~/.wakeup.bak"
fi
install -m 755 mac/wakeup.sh "$HOME/.wakeup"
[ -f "$HOME/.sleep" ] || { printf '#!/bin/bash\n' > "$HOME/.sleep"; chmod +x "$HOME/.sleep"; }

if [ -n "$1" ]; then
  rm -f "$1"/usbnet.*.sh
  install -m 755 swiftbar/usbnet.sh "$1/usbnet.sh"
  echo "已安装 SwiftBar 插件到 $1"
fi

brew services restart sleepwatcher
echo "安装完成。"

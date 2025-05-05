#!/data/data/com.termux/files/usr/bin/bash

set -e

echo "======== Termux SOCKS5 + cpolar 快速部署 ========="

# 替换为清华 Termux 软件源
echo "[*] 设置清华源..."
cat > $PREFIX/etc/apt/sources.list <<EOF
deb https://mirrors.tuna.tsinghua.edu.cn/termux stable main
EOF

# 更新系统并安装必要工具
echo "[*] 更新系统并安装依赖..."
pkg update -y && pkg upgrade -y
pkg install -y git clang make unzip curl dnsutils

# 克隆并构建 microsocks
if [ ! -d "microsocks" ]; then
  echo "[*] 克隆 microsocks 仓库..."
  git clone https://github.com/rofl0r/microsocks
fi

cd microsocks
echo "[*] 编译 microsocks..."
make
cd ..

# 下载并解压 cpolar（仅当不存在时）
if [ ! -f "./cpolar" ]; then
  echo "[*] 下载并解压 cpolar..."
  curl -O -L https://cpolar.com/static/downloads/cpolar-stable-linux-arm.zip
  unzip cpolar-stable-linux-arm.zip
  chmod +x cpolar
  rm -f cpolar-stable-linux-arm.zip
fi

# 配置 cpolar token
echo "[*] 请访问 https://dashboard.cpolar.com 获取你的 authtoken"
read -p "[*] 输入你的 cpolar authtoken: " cptoken
./cpolar authtoken "$cptoken"

# 生成后台启动脚本
echo "[*] 生成 start_proxy.sh 启动脚本..."

cat > start_proxy.sh <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash

# 杀掉旧进程
pkill -f microsocks || true
pkill -f cpolar || true
sleep 1

echo "[*] 启动 microsocks（监听 127.0.0.1:1080，后台运行）..."
cd microsocks
nohup ../microsocks -i 127.0.0.1 -p 1080 > ../microsocks.log 2>&1 &
cd ..

sleep 1

echo "[*] 启动 cpolar，穿透端口 1080（后台运行）..."
nohup ./cpolar tcp 1080 > cpolar.log 2>&1 &
EOF

chmod +x start_proxy.sh

echo ""
echo "✅ 安装完成！运行以下命令启动 SOCKS5 + cpolar 服务："
echo ""
echo "   ./start_proxy.sh"
echo ""
echo "🌐 启动成功后，你将看到 cpolar 分配的公网地址，如："
echo "   tcp://x.x.x.x:xxxx"
echo ""
echo "然后在其他设备上配置 SOCKS5 代理：地址为该公网地址，端口为显示的端口。"

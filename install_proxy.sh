#!/data/data/com.termux/files/usr/bin/bash

set -e

echo "======================================"
echo "  Termux 一键部署 SOCKS5 + cpolar"
echo "  Power By Write or ...  QQ:647689059"
echo "  粉丝QQ群：779484281"
echo "======================================"

# 1. 替换为清华源
echo "[*] 替换 Termux 源为清华源..."
cat > $PREFIX/etc/apt/sources.list <<EOF
deb https://mirrors.tuna.tsinghua.edu.cn/termux stable main
EOF

# 2. 更新软件包
echo "[*] 更新软件包..."
pkg update -y && pkg upgrade -y

# 3. 安装必要工具
echo "[*] 安装 wget unzip curl git clang make dnsutils..."
pkg install -y wget unzip curl git clang make dnsutils

# 4. 克隆并编译 microsocks
if [ ! -d "./microsocks" ]; then
    echo "[*] 克隆 microsocks..."
    git clone https://github.com/rofl0r/microsocks
else
    echo "[√] microsocks 目录已存在，跳过克隆"
fi

cd microsocks
if [ ! -f "./microsocks" ]; then
    echo "[*] 编译 microsocks..."
    make
else
    echo "[√] microsocks 已编译，跳过 make"
fi
cd ..

# 5. 下载并解压 cpolar
if [ ! -f "./cpolar" ]; then
    echo "[*] 下载 cpolar..."
    curl -L -o cpolar.zip https://cpolar.com/static/downloads/cpolar-stable-linux-arm.zip
    unzip cpolar.zip -d cpolar_tmp
    mv cpolar_tmp/cpolar ./cpolar
    chmod +x cpolar
    rm -rf cpolar_tmp cpolar.zip
else
    echo "[√] cpolar 已存在，跳过下载"
fi

# 6. 配置 cpolar authtoken
if ! ./cpolar authtoken list | grep -q "Your authtoken"; then
    echo "[*] 请访问 https://dashboard.cpolar.com 获取你的 cpolar authtoken"
    read -p "[*] 输入你的 cpolar authtoken: " cpolar_token
    ./cpolar authtoken "$cpolar_token"
else
    echo "[√] cpolar 已授权过 authtoken"
fi

# 7. 创建启动脚本
echo "[*] 创建启动脚本 start_proxy.sh..."

cat > start_proxy.sh <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash

pkill -f microsocks || true
pkill -f cpolar || true
sleep 1

echo "[*] 启动 microsocks（本地 SOCKS5）..."
cd microsocks
./microsocks -i 127.0.0.1 -p 1080 &
cd ..

sleep 1

echo "[*] 启动 cpolar 穿透端口 1080..."
./cpolar tcp 1080
EOF

chmod +x start_proxy.sh

echo ""
echo "✅ 安装完成！使用以下命令启动服务："
echo ""
echo "   ./start_proxy.sh"
echo ""
echo "然后查看 cpolar 输出的公网 TCP 地址，在其他设备中配置 SOCKS5 即可。"

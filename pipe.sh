#!/bin/bash

# 设置版本号
current_version=20250110005

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
# Program name
PROGRAMNAME="pipe"

update_script() {
    # 指定URL
    update_url="https://raw.githubusercontent.com/breaddog100/$PROGRAMNAME/main/$PROGRAMNAME.sh"
    file_name=$(basename "$update_url")

    # 下载脚本文件
    tmp=$(date +%s)
    timeout 10s curl -s -o "$HOME/$tmp" -H "Cache-Control: no-cache" "$update_url?$tmp"
    exit_code=$?
    if [[ $exit_code -eq 124 ]]; then
        echo "命令超时"
        return 1
    elif [[ $exit_code -ne 0 ]]; then
        echo "下载失败"
        return 1
    fi

    # 检查是否有新版本可用
    latest_version=$(grep -oP 'current_version=([0-9]+)' $HOME/$tmp | sed -n 's/.*=//p')

    if [[ "$latest_version" -gt "$current_version" ]]; then
        clear
        echo ""
        # 提示需要更新脚本
        printf "\033[31m脚本有新版本可用！当前版本：%s，最新版本：%s\033[0m\n" "$current_version" "$latest_version"
        echo "正在更新..."
        sleep 3
        mv $HOME/$tmp $HOME/$file_name
        chmod +x $HOME/$file_name
        exec "$HOME/$file_name"
    else
        # 脚本是最新的
        rm -f $tmp
    fi

}

# 节点安装
function install_node() {

    mkdir -p "$HOME/pop/download_cache"

    TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')
    TOTAL_RAM_GB=$((TOTAL_RAM / 1024))
    read -p "设置内存大小 (默认: ${TOTAL_RAM_GB}GB): " RAM_GB
    RAM_GB=${RAM_GB:-$TOTAL_RAM_GB}
    echo "设置的内存大小为: ${RAM_GB}GB"

    DISK_SIZE_DEF=100
    read -p "设置磁盘大小 (默认: ${DISK_SIZE_DEF}GB): " DISK_SIZE
    DISK_SIZE=${DISK_SIZE:-$DISK_SIZE_DEF}
    echo "设置的磁盘大小为: ${DISK_SIZE}GB"

    DISK_DIR_DEF="$HOME/pop/data"
    read -p "设置磁盘目录 (默认: $DISK_DIR_DEF): " DISK_DIR
    DISK_DIR=${DISK_DIR:-$DISK_DIR_DEF}
    echo "设置的磁盘目录为: $DISK_DIR"
    mkdir -p $DISK_DIR

    read -p "设置Solana钱包地址: " KEY
    # Breaddog's recommendation code
    REFERRAL="49ab19ce39b0e4c7"

    curl -L -o "$HOME/pop/pop" https://dl.pipecdn.app/v0.2.4/pop
    chmod +x "$HOME/pop/pop"
    echo 'export PATH="$HOME/pop:$PATH"' >> ~/.bashrc  # Bash
    source ~/.bashrc
    "$HOME/pop/pop" --version

    cd $HOME/pop/
    "$HOME/pop/pop" --signup-by-referral-route $REFERRAL

    sudo tee /etc/systemd/system/pop.service << EOF
[Unit]
Description=Pipe POP Node Service
After=network.target
Wants=network-online.target

[Service]
User=$USER
ExecStart=$HOME/pop/pop \
    --ram=$RAM_GB \
    --pubKey $KEY \
    --max-disk $DISK_SIZE \
    --cache-dir $DISK_DIR \
    --no-prompt
Restart=always
RestartSec=5
LimitNOFILE=65536
LimitNPROC=4096
StandardOutput=journal
StandardError=journal
SyslogIdentifier=pop-node
WorkingDirectory=$HOME/pop/

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable pop
    sudo systemctl start pop
	echo "部署完成..."
}

# 查看日志
function view_logs(){
	sudo journalctl -u pop.service -f --no-hostname -o short-iso
}

# 查看状态
function view_status(){
	#sudo systemctl status pop
    "$HOME/pop/pop" --status
}

# 启动节点
function start_node(){
	sudo systemctl start pop
	echo "pop 节点已启动"
}

# 停止节点
function stop_node(){
	sudo systemctl stop pop
	echo "pop 节点已停止"
}

# 卸载节点
function uninstall_node(){
	echo "你确定要卸载节点程序吗？这将会删除所有相关的数据。[Y/N]"
	read -r -p "请确认: " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            echo "开始卸载节点程序..."
            stop_node
			rm -rf $HOME/pop
            sudo rm -f /etc/systemd/system/pop.service
            sudo systemctl daemon-reload
			echo "卸载完成。"
            ;;
        *)
            echo "取消卸载操作。"
            ;;
    esac
}

# 主菜单
function main_menu() {
	while true; do
	    clear
	    echo "================== $PROGRAMNAME 一键部署脚本=================="
		echo "当前版本：$current_version"
		echo "沟通电报群：https://t.me/lumaogogogo"
		echo "推荐配置：4C8G500G"
	    echo "请选择要执行的操作:"
	    echo "1. 部署节点 install_node"
	    echo "2. 查看状态 view_status"
	    echo "3. 查看日志 view_logs"
	    echo "4. 停止节点 stop_node"
	    echo "5. 启动节点 start_node"
	    echo "1618. 卸载节点 uninstall_node"
	    echo "0. 退出脚本 exit"
	    read -p "请输入选项: " OPTION
	
	    case $OPTION in
	    1) install_node ;;
	    2) view_status ;;
	    3) view_logs ;;
	    4) stop_node ;;
	    5) start_node ;;
	    1618) uninstall_node ;;
	    0) echo "退出脚本。"; exit 0 ;;
	    *) echo "无效选项，请重新输入。"; sleep 3 ;;
	    esac
	    echo "按任意键返回主菜单..."
        read -n 1
    done
}

# 检查更新
update_script

# 显示主菜单
main_menu
#! /bin/bash
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"
gost_conf_path="/etc/gost/config.json"
raw_conf_path="/etc/gost/rawconf"
function checknew()
{
    checknew=$(gost -V 2>&1|awk '{print $2}')
    check_new_ver
    echo "你的gost版本为:"$checknew""
    echo -n 是否更新\(y/n\)\:
    read checknewnum
    if test $checknewnum = "y";then
        `cp -r /etc/gost /tmp/`
        Install_ct
        `rm -rf /etc/gost`
        `mv /tmp/gost /etc/`
        `systemctl restart gost`
    else
        exit 0
    fi
}
function check_sys()
{
    if [[ -f /etc/redhat-release ]]; then
        release="centos"
    elif cat /etc/issue | grep -q -E -i "debian"; then
        release="debian"
    elif cat /etc/issue | grep -q -E -i "ubuntu"; then
        release="ubuntu"
    elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
        release="centos"
    elif cat /proc/version | grep -q -E -i "debian"; then
        release="debian"
    elif cat /proc/version | grep -q -E -i "ubuntu"; then
        release="ubuntu"
    elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
        release="centos"
    fi
    bit=$(uname -m)
        if test "$bit" != "x86_64"; then
           echo "请输入你的芯片架构，/386/armv5/armv6/armv7/armv8"
           read bit
        else bit="amd64"
    fi
}
function Installation_dependency()
{
    gzip_ver=$(gzip -V)
    if [[ -z ${gzip_ver} ]]; then
        if [[ ${release} == "centos" ]]; then
            yum update
            yum install -y gzip
        else
            apt-get update
            apt-get install -y gzip
        fi
    fi
}
function check_root()
{
    [[ $EUID != 0 ]] && echo -e "${Error} 当前非ROOT账号(或没有ROOT权限)，无法继续操作，请更换ROOT账号或使用 ${Green_background_prefix}sudo su${Font_color_suffix} 命令获取临时ROOT权限（执行后可能会提示输入当前账号的密码）。" && exit 1
}
function check_new_ver()
{
    ct_new_ver=$(wget --no-check-certificate -qO- -t2 -T3 https://api.github.com/repos/ginuerzh/gost/releases/latest| grep "tag_name"| head -n 1| awk -F ":" '{print $2}'| sed 's/\"//g;s/,//g;s/ //g;s/v//g')
    if [[ -z ${ct_new_ver} ]]; then
        ct_new_ver="2.11.1"
        echo -e "${Error} gost 最新版本获取失败，正在下载v${ct_new_ver}版"
        # read -e -p "请输入版本号 [ 格式 x.x.xx , 如 0.8.21 ] :" ct_new_ver
        #[[ -z "${ct_new_ver}" ]] && echo "取消..." && exit 1
    else
        echo -e "${Info} gost 目前最新版本为 ${ct_new_ver}"
    fi
}
function check_file()
{
    if test ! -d "/usr/lib/systemd/system/";then
        `mkdir /usr/lib/systemd/system`
        `chmod -R 777 /usr/lib/systemd/system`
    fi
}
function check_nor_file()
{
    `rm -rf "$(pwd)"/gost`
    `rm -rf "$(pwd)"/gost.service`
    `rm -rf "$(pwd)"/config.json`
    `rm -rf /etc/gost`
    `rm -rf /usr/lib/systemd/system/gost.service`
    `rm -rf /usr/bin/gost`
}
function Install_ct()
{
    check_root
    check_nor_file
    Installation_dependency
    check_file
    check_sys
    check_new_ver
    `rm -rf gost-linux-"$bit"-"$ct_new_ver".gz`
    `wget --no-check-certificate https://github.com/ginuerzh/gost/releases/download/v"$ct_new_ver"/gost-linux-"$bit"-"$ct_new_ver".gz`
    `gunzip gost-linux-"$bit"-"$ct_new_ver".gz`
    `mv gost-linux-"$bit"-"$ct_new_ver" gost`
    `mv gost /usr/bin/gost`
    `chmod -R 777 /usr/bin/gost`
    `wget --no-check-certificate https://raw.githubusercontent.com/KANIKIG/Multi-EasyGost/master/gost.service && chmod -R 777 gost.service && mv gost.service /usr/lib/systemd/system`
    `mkdir /etc/gost && wget --no-check-certificate https://raw.githubusercontent.com/KANIKIG/Multi-EasyGost/master/config.json && mv config.json /etc/gost && chmod -R 777 /etc/gost`
    `systemctl enable gost && systemctl restart gost`
    echo "------------------------------"
    if test -a /usr/bin/gost -a /usr/lib/systemctl/gost.service -a /etc/gost/config.json;then
        echo "gost安装成功"
        `rm -rf "$(pwd)"/gost`
        `rm -rf "$(pwd)"/gost.service`
        `rm -rf "$(pwd)"/config.json`
    else
        echo "gost没有安装成功，可以在Github[EasyGost]中提交issue"
        `rm -rf   "$(pwd)"/gost`
        `rm -rf "$(pwd)"/gost.service`
        `rm -rf "$(pwd)"/config.json`
        `rm -rf "$(pwd)"/gost.sh`
    fi
}
function Uninstall_ct()
{
    `rm -rf /usr/bin/gost`
    `rm -rf /usr/lib/systemd/system/gost.service`
    `rm -rf /etc/gost`
    `rm -rf "$(pwd)"/gost.sh`
    echo "gost已经成功删除"
}
function Start_ct()
{
    `systemctl start gost`
    echo "已启动"
}
function Stop_ct()
{
    `systemctl stop gost`
    echo "已停止"  
}
function Restart_ct()
{
    `systemctl restart gost`
    echo "已重启"  
}
function read_protocol()
{
    echo -e "请问您要设置哪种转发: "
    echo -e "-----------------------------------"
    echo -e "[1] tcp+udp流量转发, 不加密"
    echo -e "说明: 一般设置在国内中转机上"
    echo -e "-----------------------------------"
    echo -e "[2] 加密隧道流量转发"
    echo -e "说明: (1)用于转发原本加密等级较低的流量, 一般设置在国内中转机上"
    echo -e "      (2)选择此协议意味着你还有一台机器用于接收此加密流量, 之后须在那台机器上配置协议[3]进行对接"
    echo -e "-----------------------------------"
    echo -e "[3] 解密由gost传输而来的流量并转发"
    echo -e "说明: 对于经由gost加密中转的流量, 通过此选项进行解密并转发给本机的代理服务端口或转发给其他远程机器, 一般设置在用于接收中转流量的国外机器上"
    echo -e "-----------------------------------"
    read -p "请选择转发方式: " numprotocol

    if [ "$numprotocol" = "1" ]; then
        flag_a="nonencrypt"
    elif [ "$numprotocol" = "2" ]; then
        encrypt
    elif [ "$numprotocol" = "3" ]; then
        decrypt
    else
        echo "type error, please try again"
        exit
    fi
}
function read_s_port()
{
    echo -e "------------------------------------------------------------------"
    echo -e "------------------------------------------------------------------"
    echo -e "请问你要将本机哪个端口接收到的流量进行转发?"
    read -p "请输入: " flag_b
}
function read_d_ip()
{
    echo -e "------------------------------------------------------------------"
    echo -e "------------------------------------------------------------------"
    echo -e "请问你要将本机从${flag_b}接收到的流量转发向哪个IP或域名?"
    echo -e "注: IP既可以是[远程机器/当前机器]的公网IP, 也可是以本机本地回环IP(即127.0.0.1)"
    echo -e "    具体IP地址的填写, 取决于接收该流量的服务正在监听的IP(详见: https://github.com/KANIKIG/Multi-EasyGost)"
    read -p "请输入: " flag_c
}
function read_d_port()
{
    echo -e "------------------------------------------------------------------"
    echo -e "------------------------------------------------------------------"
    echo -e "请问你要将本机从${flag_b}接收到的流量转发向${flag_c}的哪个端口?"
    read -p "请输入: " flag_d
}
function writerawconf()
{
    echo $flag_a"/"$flag_b"#"$flag_c"#"$flag_d >> $raw_conf_path
}
function rawconf()
{
    read_protocol
    read_s_port
    read_d_ip
    read_d_port
    writerawconf
}
function eachconf_retrieve()
{
    d_server=${trans_conf#*#}
    d_port=${d_server#*#}
    d_ip=${d_server%#*}
    flag_s_port=${trans_conf%%#*}
    s_port=${flag_s_port#*/}
    is_encrypt=${flag_s_port%/*}
}
function confstart()
{
    echo "{
    \"Debug\": true,
    \"Retries\": 0,
    \"ServeNodes\": [" >> $gost_conf_path
}
function multiconfstart()
{
    echo "        {
            \"Retries\": 0,
            \"ServeNodes\": [" >> $gost_conf_path
}
function conflast()
{
    echo "    ]
}" >> $gost_conf_path
}
function multiconflast()
{
    if [ $i -eq $count_line ]; then
        echo "            ]
        }" >> $gost_conf_path
    else
        echo "            ]
        }," >> $gost_conf_path
    fi
}
function encrypt()
{
    echo -e "请问您要设置的转发传输类型: "
    echo -e "-----------------------------------"
    echo -e "[1] tls"
    echo -e "[2] ws"
    echo -e "[3] wss"
    echo -e "注意: 同一则转发，中转与落地传输类型必须对应！本脚本默认开启tcp+udp"
    echo -e "-----------------------------------"
    read -p "请选择转发传输类型: " numencrypt

    if [ "$numencrypt" = "1" ]; then
        flag_a="encrypttls"
    elif [ "$numencrypt" = "2" ]; then
        flag_a="encryptws"
    elif [ "$numencrypt" = "3" ]; then
        flag_a="encryptwss"
    else
        echo "type error, please try again"
        exit
    fi
}
function decrypt()
{
    echo -e "请问您要设置的解密传输类型: "
    echo -e "-----------------------------------"
    echo -e "[1] tls"
    echo -e "[2] ws"
    echo -e "[3] wss"
    echo -e "注意: 同一则转发，中转与落地传输类型必须对应！本脚本默认开启tcp+udp"
    echo -e "-----------------------------------"
    read -p "请选择解密传输类型: " numdecrypt

    if [ "$numdecrypt" = "1" ]; then
        flag_a="decrypttls"
    elif [ "$numdecrypt" = "2" ]; then
        flag_a="decryptws"
    elif [ "$numdecrypt" = "3" ]; then
        flag_a="decryptwss"
    else
        echo "type error, please try again"
        exit
    fi
}
function method()
{
    if [ $i -eq 1 ]; then
        if [ "$is_encrypt" = "nonencrypt" ]; then
            echo "        \"tcp://:$s_port/$d_ip:$d_port\",
        \"udp://:$s_port/$d_ip:$d_port\"" >> $gost_conf_path
        elif [ "$is_encrypt" = "encrypttls" ]; then
            echo "        \"tcp://:$s_port\",
        \"udp://:$s_port\"
    ],
    \"ChainNodes\": [
        \"relay+tls://$d_ip:$d_port\"" >> $gost_conf_path
    	elif [ "$is_encrypt" = "encryptws" ]; then
        	echo "        \"tcp://:$s_port\",
    	\"udp://:$s_port\"
	],
	\"ChainNodes\": [
    	\"relay+ws://$d_ip:$d_port\"" >> $gost_conf_path
		elif [ "$is_encrypt" = "encryptwss" ]; then
    		echo "        \"tcp://:$s_port\",
		\"udp://:$s_port\"
	],
	\"ChainNodes\": [
		\"relay+wss://$d_ip:$d_port\"" >> $gost_conf_path
        elif [ "$is_encrypt" = "decrypttls" ]; then
            echo "        \"relay+tls://:$s_port/$d_ip:$d_port\"" >> $gost_conf_path
        elif [ "$is_encrypt" = "decryptws" ]; then
            echo "        \"relay+ws://:$s_port/$d_ip:$d_port\"" >> $gost_conf_path
        elif [ "$is_encrypt" = "decryptwss" ]; then
            echo "        \"relay+wss://:$s_port/$d_ip:$d_port\"" >> $gost_conf_path
        else
            echo "config error"
        fi
    elif [ $i -gt 1 ]; then
        if [ "$is_encrypt" = "nonencrypt" ]; then
            echo "                \"tcp://:$s_port/$d_ip:$d_port\",
                \"udp://:$s_port/$d_ip:$d_port\"" >> $gost_conf_path
        elif [ "$is_encrypt" = "encrypttls" ]; then
            echo "                \"tcp://:$s_port\",
                \"udp://:$s_port\"
            ],
            \"ChainNodes\": [
                \"relay+tls://$d_ip:$d_port\"" >> $gost_conf_path
	    elif [ "$is_encrypt" = "encryptws" ]; then
	        echo "                \"tcp://:$s_port\",
	            \"udp://:$s_port\"
	        ],
	        \"ChainNodes\": [
	            \"relay+ws://$d_ip:$d_port\"" >> $gost_conf_path
		elif [ "$is_encrypt" = "encryptwss" ]; then
		    echo "                \"tcp://:$s_port\",
		        \"udp://:$s_port\"
		    ],
		    \"ChainNodes\": [
		        \"relay+wss://$d_ip:$d_port\"" >> $gost_conf_path
        elif [ "$is_encrypt" = "decrypttls" ]; then
            echo "                \"relay+tls://:$s_port/$d_ip:$d_port\"" >> $gost_conf_path
        elif [ "$is_encrypt" = "decryptws" ]; then
            echo "        		  \"relay+ws://:$s_port/$d_ip:$d_port\"" >> $gost_conf_path
        elif [ "$is_encrypt" = "decryptwss" ]; then
            echo "        		  \"relay+wss://:$s_port/$d_ip:$d_port\"" >> $gost_conf_path
        else
            echo "config error"
        fi
    fi
}
function ssconf()
{	echo -e "-----------------------------------"
	read -p "请输入ss密码: " sspasswd
	echo -e "------------------------------------------------------------------"
    echo -e "请问您要设置的ss加密(仅提供常用的几种): "
    echo -e "-----------------------------------"
    echo -e "[1] aes-256-gcm"
    echo -e "[2] aes-256-cfb"
	echo -e "[3] chacha20-ietf-poly1305"
	echo -e "[4] chacha20"
	echo -e "[5] rc4-md5"
	echo -e "[6] AEAD_CHACHA20_POLY1305"
    echo -e "-----------------------------------"
    read -p "请选择ss加密方式: " ssencrypt
	
    if [ "$ssencrypt" = "1" ]; then
		echo ",
	             \"ss://aes-256-gcm:$sspasswd@:$d_port\"" >> $gost_conf_path
		echo -e "已选择 aes-256-gcm"
    elif [ "$ssencrypt" = "2" ]; then
		echo ",
	             \"ss://aes-256-cfb:$sspasswd@:$d_port\"" >> $gost_conf_path
		echo -e "已选择 aes-256-cfb"
	elif [ "$ssencrypt" = "3" ]; then
		echo ",
		 	     \"ss://chacha20-ietf-poly1305:$sspasswd@:$d_port\"" >> $gost_conf_path
		echo -e "已选择 chacha20-ietf-poly1305"
	elif [ "$ssencrypt" = "4" ]; then
		 echo ",
		 		 \"ss://chacha20:$sspasswd@:$d_port\"" >> $gost_conf_path
		 echo -e "已选择 chacha20"
	elif [ "$ssencrypt" = "5" ]; then
		 echo ",
		 		 \"ss://rc4-md5:$sspasswd@:$d_port\"" >> $gost_conf_path			 
		 echo -e "已选择 rc4-md5"
 	elif [ "$ssencrypt" = "4" ]; then
 		 echo ",
 		 		 \"ss://AEAD_CHACHA20_POLY1305:$sspasswd@:$d_port\"" >> $gost_conf_path
 		 echo -e "已选择 AEAD_CHACHA20_POLY1305"
	else
        echo "type error, please try again"
        exit
    fi
}
function s5conf()
{
	exit
}
function proxy()
{
    echo -e "------------------------------------------------------------------"
    read -p "是否需要为上述端口一键安装ss或sock5代理?(y/n 默认:N)" is_proxy
	case $is_proxy in
	        [yY][eE][sS] | [yY])
				echo -e "------------------------------------------------------------------"
			    echo -e "请问您要设置的代理类型: "
			    echo -e "-----------------------------------"
			    echo -e "[1] ss"
			    echo -e "[2] socks5(未完成)"
			    echo -e "-----------------------------------"
			    read -p "请选择代理类型: " numproxy
			    if [ "$numproxy" = "1" ]; then
			        ssconf
			    elif [ "$numproxy" = "2" ]; then
			        s5conf
			    else
			        echo "type error, please try again"
			        exit
			    fi
	            ;;
	        *)
	            sleep 2
	            ;;
	        esac
}
function writeconf()
{
    count_line=$(awk 'END{print NR}' $raw_conf_path)
    for((i=1;i<=$count_line;i++))
    do
        if [ $i -eq 1 ]; then
            trans_conf=$(sed -n "${i}p" $raw_conf_path)
            eachconf_retrieve
            method
        elif [ $i -gt 1 ]; then
            if [ $i -eq 2 ]; then
                echo "    ],
    \"Routes\": [" >> $gost_conf_path
                trans_conf=$(sed -n "${i}p" $raw_conf_path)
                eachconf_retrieve
                multiconfstart
                method
				proxy
                multiconflast
            else
                trans_conf=$(sed -n "${i}p" $raw_conf_path)
                eachconf_retrieve
                multiconfstart
                method
				proxy
                multiconflast
            fi
        fi
    done
}
function show_all_conf()
{
    echo -e "                      GOST 配置                        "
    echo -e "--------------------------------------------------------"
    echo -e "序号|方法\t    |本地端口\t|目的地地址:目的地端口"
    echo -e "--------------------------------------------------------"

    count_line=$(awk 'END{print NR}' $raw_conf_path)
    for((i=1;i<=$count_line;i++))
    do
        trans_conf=$(sed -n "${i}p" $raw_conf_path)
        eachconf_retrieve

        if [ "$is_encrypt" = "nonencrypt" ]; then
            str="tcp+udp不加密"
        elif [ "$is_encrypt" = "encrypttls" ]; then
            str="tls隧道"
        elif [ "$is_encrypt" = "encryptws" ]; then
            str="ws隧道"
        elif [ "$is_encrypt" = "encryptwss" ]; then
            str="wss隧道"
        elif [ "$is_encrypt" = "decrypttls" ]; then
            str="tls解密"
        elif [ "$is_encrypt" = "decryptws" ]; then
            str="ws解密"
        elif [ "$is_encrypt" = "decryptwss" ]; then
            str="wss解密"
        fi

        echo -e " $i  |$str  |$s_port\t|$d_ip:$d_port"
        echo -e "--------------------------------------------------------"
    done
}
echo && echo -e "                      gost 一键安装配置脚本
  ----------- KANIKIG -----------
  特性: (1)本脚本采用systemd及gost配置文件对gost进行管理
        (2)能够在不借助其他工具(如screen)的情况下实现多条转发规则同时生效
		(3)机器reboot后转发不失效
  功能: (1)tcp+udp不加密转发, (2)中转机加密转发, (3)落地机解密对接转发
  帮助文档：https://github.com/KANIKIG/Multi-EasyGost
  
 ${Green_font_prefix}1.${Font_color_suffix} 安装 gost
 ${Green_font_prefix}2.${Font_color_suffix} 更新 gost
 ${Green_font_prefix}3.${Font_color_suffix} 卸载 gost
————————————
 ${Green_font_prefix}4.${Font_color_suffix} 启动 gost
 ${Green_font_prefix}5.${Font_color_suffix} 停止 gost
 ${Green_font_prefix}6.${Font_color_suffix} 重启 gost
————————————
 ${Green_font_prefix}7.${Font_color_suffix} 新增gost转发配置
 ${Green_font_prefix}8.${Font_color_suffix} 查看现有gost配置
 ${Green_font_prefix}9.${Font_color_suffix} 删除一则gost配置
————————————" && echo
read -e -p " 请输入数字 [1-9]:" num
case "$num" in
    1)
        Install_ct
        ;;
    2)
        checknew
        ;;
    3)
        Uninstall_ct
        ;;
    4)
        Start_ct
        ;;
    5)
        Stop_ct
        ;;
    6)
        Restart_ct
        ;;
    7)
        rawconf
        rm -rf /etc/gost/config.json
        confstart
        writeconf
        conflast
        `systemctl restart gost`
        echo -e "配置已生效，当前配置如下"
        echo -e "--------------------------------------------------------"
        show_all_conf
        ;;
    8)
        show_all_conf
        ;;
    9)
        show_all_conf
        read -p "请输入你要删除的配置编号：" numdelete
        sed -i "${numdelete}d" $raw_conf_path
        rm -rf /etc/gost/config.json
        confstart
        writeconf
        conflast
        `systemctl restart gost`
        echo -e "配置已删除，服务已重启"
        ;;
    *)
       echo "请输入正确数字 [1-9]"
       ;;
esac
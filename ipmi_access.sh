#!/bin/bash

APP_NAME="IPMI ACCESS TOOL"
APP_VERSION="1.2.0"
APP_DATE="2023/10/11"
APP_AUTH="Mouchen"

IPMITOOL_MODE="ipmitool"
REDFISH_MODE="redfish"
mode=$IPMITOOL_MODE
command=""
extend_command=""

# --------------------------------- SERVER lib --------------------------------- #
server_ip=""
user_name=""
user_pwd=""

IPMI_NETFN_SENSOR=0x04
IPMI_CMD_GET_SENSOR_READING=0x2d
IPMI_NETFN_APP=0x06
IPMI_CMD_GET_DEVICE_ID=0x01
IPMI_NETFN_STORAGE=0x0A

SERVER_CFG_FILE="./server_cfg"
ipmi_cmd_prefix=""
ipmi_raw_cmd_prefix=""
ipmi_init_success=0
redfish_cmd_prefix=""
redfish_cmd_suffix="|python -m json.tool | GREP_COLOR='01;32' egrep -i --color=always '@odata|'"

KEYWORD_SERVER_IP="SERVER_IP"
KEYWORD_USER_NAME="USER_NAME"
KEYWORD_USER_PWD="USER_PWD"

LOAD_CFG(){
	if [[ ! -f "$SERVER_CFG_FILE" ]]; then
		echo "$SERVER_CFG_FILE not exists."
		return 1
	fi

	#~~~~~~~~~~~~ Format EX ~~~~~~~~~~~~~
	#SERVER_IP=10.10.11.78
	#USER_NAME=admin
	#USER_PWD=admin
	#~~~~~~~~~~~~ Format EX ~~~~~~~~~~~~~
	if [ -z "$server_ip" ]; then
		key_str=`cat $SERVER_CFG_FILE |grep $KEYWORD_SERVER_IP`
		IFS='=' read -r -a array <<< "$key_str"
		server_ip="${array[1]}"
	fi
	if [ -z "$user_name" ]; then
		key_str=`cat $SERVER_CFG_FILE |grep $KEYWORD_USER_NAME`
		IFS='=' read -r -a array <<< "$key_str"
		user_name="${array[1]}"
	fi
	if [ -z "$user_pwd" ]; then
		key_str=`cat $SERVER_CFG_FILE |grep $KEYWORD_USER_PWD`
		IFS='=' read -r -a array <<< "$key_str"
		user_pwd="${array[1]}"
	fi

	return 0
}

SERVER_INIT(){
	server_ip=$1
	user_name=$2
	user_pwd=$3

	if [ -z "$server_ip" ] || [ -z "$user_name" ] || [ -z "$user_pwd" ]; then
		LOAD_CFG
		if [ $? == 1 ]; then
			ipmi_init_success=0
			return
		fi
	fi

	echo "{Server info}"
	echo "* ip:       $server_ip"
	echo "* user:     $user_name"
	echo "* password: $user_pwd"
	echo ""

	ipmi_cmd_prefix="ipmitool -H $server_ip -U $user_name -P $user_pwd"
	ipmi_raw_cmd_prefix="$ipmi_cmd_prefix raw"

	redfish_cmd_prefix="curl -s -k -u $user_name:$user_pwd https://$server_ip/"

	#Pre-test
	ipmi_init_success=1
	IPMI_RAW_SEND $IPMI_NETFN_APP $IPMI_CMD_GET_DEVICE_ID
	if [ $? == 1 ]; then
		echo "[ERR] Failed to init server!"
		ipmi_init_success=0
		return
	fi

	#Update server config
	echo "$KEYWORD_SERVER_IP=$server_ip" > $SERVER_CFG_FILE
	echo "$KEYWORD_USER_NAME=$user_name" >> $SERVER_CFG_FILE
	echo "$KEYWORD_USER_PWD=$user_pwd" >> $SERVER_CFG_FILE
}

response_msg=""
IPMI_RAW_SEND(){
	if [ $ipmi_init_success == 0 ]; then
		echo "[ERR] ipmi init not ready!"
		response_msg=""
		return 1
	fi

	ret=0
	netfn=$1
	cmd=$2
	data=$3
	rsp=`$ipmi_raw_cmd_prefix $netfn $cmd $data`
	if [ $? == 1 ]; then
		ret=1
	fi
	#echo [output]"
	#echo $rsp
	response_msg=$rsp

	return $ret
}

IPMI_SEND(){
	if [ $ipmi_init_success == 0 ]; then
		echo "[ERR] ipmi init not ready!"
		response_msg=""
		return 1
	fi

	#command list if op=0
	#extend command list if op>0
	op=$1
	cmd_list=$2

	COLOR_PRINT "[input]" "BLUE"
	echo $ipmi_cmd_prefix $cmd_list

	if [ $op == 1 ]; then
		cmd_list="mc info $cmd_list"
	elif [ $op == 2 ]; then
		cmd_list="sdr list $cmd_list"
	elif [ $op == 3 ]; then
		cmd_list="sensor list $cmd_list"
	elif [ $op == 4 ]; then
		cmd_list="sel list $cmd_list"
	elif [ $op == 5 ]; then
		cmd_list="sel clear $cmd_list"
	fi

	COLOR_PRINT "[output]" "BLUE"
	eval "$ipmi_cmd_prefix $cmd_list"
}

REDFISH_SEND(){
	op=$1

	#command list if op=0
	#extend command list if op>0
	cmd_list=$2
	ext_cmd=$3

	COLOR_PRINT "[input]" "BLUE"
	echo $redfish_cmd_prefix$cmd_list $ext_cmd

	# add /HMC filter
	hmc_filter=`echo $cmd_list |sed "s/hmc//1"`

	# highlight command line
	hi_light="| GREP_COLOR='01;31' egrep -i --color=always '$hmc_filter|'"
	cmd_list="$redfish_cmd_prefix$cmd_list $redfish_cmd_suffix $hi_light $ext_cmd"
	#echo $cmd_list

	COLOR_PRINT "[output]" "BLUE"
	eval $cmd_list
}
# --------------------------------- SERVER lib --------------------------------- #

# --------------------------------- LOG lib --------------------------------- #
LOG_FILE="./log.txt"
rec_lock=0

# Reset
COLOR_OFF='\033[0m'       # Text Reset

# Regular Colors
COLOR_BLACK='\033[0;30m'        # Black
COLOR_RED='\033[0;31m'          # Red
COLOR_GREEN='\033[0;32m'        # Green
COLOR_YELLOW='\033[0;33m'       # Yellow
COLOR_BLUE='\033[0;34m'         # Blue
COLOR_PURPLE='\033[0;35m'       # Purple
COLOR_CYAN='\033[0;36m'         # Cyan
COLOR_WHITE='\033[0;37m'        # White

# Bold
BBlack='\033[1;30m'       # Black
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
BYellow='\033[1;33m'      # Yellow
BBlue='\033[1;34m'        # Blue
BPurple='\033[1;35m'      # Purple
BCyan='\033[1;36m'        # Cyan
BWhite='\033[1;37m'       # White

# Underline
UBlack='\033[4;30m'       # Black
URed='\033[4;31m'         # Red
UGreen='\033[4;32m'       # Green
UYellow='\033[4;33m'      # Yellow
UBlue='\033[4;34m'        # Blue
UPurple='\033[4;35m'      # Purple
UCyan='\033[4;36m'        # Cyan
UWhite='\033[4;37m'       # White

# Background
On_Black='\033[40m'       # Black
On_Red='\033[41m'         # Red
On_Green='\033[42m'       # Green
On_Yellow='\033[43m'      # Yellow
On_Blue='\033[44m'        # Blue
On_Purple='\033[45m'      # Purple
On_Cyan='\033[46m'        # Cyan
On_White='\033[47m'       # White

# High Intensity
IBlack='\033[0;90m'       # Black
IRed='\033[0;91m'         # Red
IGreen='\033[0;92m'       # Green
IYellow='\033[0;93m'      # Yellow
IBlue='\033[0;94m'        # Blue
IPurple='\033[0;95m'      # Purple
ICyan='\033[0;96m'        # Cyan
IWhite='\033[0;97m'       # White

# Bold High Intensity
BIBlack='\033[1;90m'      # Black
BIRed='\033[1;91m'        # Red
BIGreen='\033[1;92m'      # Green
BIYellow='\033[1;93m'     # Yellow
BIBlue='\033[1;94m'       # Blue
BIPurple='\033[1;95m'     # Purple
BICyan='\033[1;96m'       # Cyan
BIWhite='\033[1;97m'      # White

# High Intensity backgrounds
On_IBlack='\033[0;100m'   # Black
On_IRed='\033[0;101m'     # Red
On_IGreen='\033[0;102m'   # Green
On_IYellow='\033[0;103m'  # Yellow
On_IBlue='\033[0;104m'    # Blue
On_IPurple='\033[0;105m'  # Purple
On_ICyan='\033[0;106m'    # Cyan
On_IWhite='\033[0;107m'   # White

HDR_LOG_ERR="err"
HDR_LOG_WRN="wrn"
HDR_LOG_INF="inf"
HDR_LOG_DBG="dbg"

COLOR_PRINT() {
	local text=$1
	local text_color=$2

	if [[ "$text_color" == "BLACK" ]]; then
		echo -e ${COLOR_BLACK}${text}${COLOR_OFF}
	elif [[ "$text_color" == "RED" ]]; then
		echo -e ${COLOR_RED}${text}${COLOR_OFF}
	elif [[ "$text_color" == "GREEN" ]]; then
		echo -e ${COLOR_GREEN}${text}${COLOR_OFF}
	elif [[ "$text_color" == "YELLOW" ]]; then
		echo -e ${COLOR_YELLOW}${text}${COLOR_OFF}
	elif [[ "$text_color" == "BLUE" ]]; then
		echo -e ${COLOR_BLUE}${text}${COLOR_OFF}
	elif [[ "$text_color" == "PURPLE" ]]; then
		echo -e ${COLOR_PURPLE}${text}${COLOR_OFF}
	elif [[ "$text_color" == "CYAN" ]]; then
		echo -e ${COLOR_CYAN}${text}${COLOR_OFF}
	elif [[ "$text_color" == "WHITE" ]]; then
		echo -e ${COLOR_WHITE}${text}${COLOR_OFF}
	else
		echo $text
	fi
}

RECORD_INIT() {
	if [[ "$rec_lock" != 0 ]]; then
		COLOR_PRINT "<err> Log record already on going!" "RED"
		return
	fi

	local script_name=$1
	echo "Initial LOG..."
	echo ""
	local now="$(date +'%Y/%m/%d %H:%M:%S')"
	echo "[$now] <$HDR_LOG_INF> Start record log for script $script_name" > $LOG_FILE
	rec_lock=1
}

RECORD_EXIT() {
	if [[ "$rec_lock" != 1 ]]; then
		COLOR_PRINT "<err> Log record havn't init yet!" "RED"
		return
	fi

	local script_name=$1
	echo "Exit LOG..."
	echo ""
	local now="$(date +'%Y/%m/%d %H:%M:%S')"
	echo "[$now] <$HDR_LOG_INF> Stop record log for script $script_name" >> $LOG_FILE
	rec_lock=0
}

RECORD_LOG() {
	if [[ "$rec_lock" != 1 ]]; then
		COLOR_PRINT "<err> Log record havn't init yet!" "RED"
		return
	fi

	local hdr=$1
	local msg=$2
	local flag=$3
	local color

	if [[ "$hdr" == "$HDR_LOG_ERR" ]]; then
		hdr="<$hdr>"
		color="RED"
	elif [[ "$hdr" == "$HDR_LOG_WRN" ]]; then
		hdr="<$hdr>"
		color="YELLOW"
	elif [[ "$hdr" == "$HDR_LOG_DBG" ]]; then
		hdr="<$hdr>"
		color="PURPLE"
	elif [[ "$hdr" == "$HDR_LOG_INF" ]]; then
		hdr="<$hdr>"
		color="WHITE"
	fi

	local now="$(date +'%Y/%m/%d %H:%M:%S')"
	if [[ "$flag" == 0 ]]; then
		COLOR_PRINT "[$now] $hdr $msg" $color
	elif [[ "$flag" == 1 ]]; then
		echo "[$now] $hdr $msg" >> $LOG_FILE
	else
		COLOR_PRINT "[$now] $hdr $msg" $color
		echo "[$now] $hdr $msg" >> $LOG_FILE
	fi
}
# --------------------------------- LOG lib --------------------------------- #

# --------------------------------- PLATFORM lib --------------------------------- #
DEV_PICK(){
	key=$1
	if [ -z "$key" ]; then
		return 1
	elif [ $key == "0" ]; then
		device_addr=$FPGA_ADDR
	elif [ $key == "1" ]; then
		device_addr=$HMC_ADDR
	elif [ $key == "2" ]; then
		device_addr=$GPU1_ADDR
	elif [ $key == "3" ]; then
		device_addr=$GPU2_ADDR
	elif [ $key == "4" ]; then
		device_addr=$GPU3_ADDR
	elif [ $key == "5" ]; then
		device_addr=$GPU4_ADDR
	elif [ $key == "6" ]; then
		device_addr=$GPU5_ADDR
	elif [ $key == "7" ]; then
		device_addr=$GPU6_ADDR
	elif [ $key == "8" ]; then
		device_addr=$GPU7_ADDR
	elif [ $key == "9" ]; then
		device_addr=$GPU8_ADDR
	else
		echo "Invalid device id $key"
		HELP
		return 1
	fi
	
	return 0
}
# --------------------------------- PLATFORM lib --------------------------------- #

# --------------------------------- COMMON lib --------------------------------- #
APP_HEADER(){
	echo "==================================="
	echo "APP NAME: $APP_NAME"
	echo "APP VERSION: $APP_VERSION"
	echo "APP RELEASE DATE: $APP_DATE"
	echo "APP AUTHOR: $APP_AUTH"
	echo "==================================="
}

APP_HELP(){
	LOAD_CFG
	echo "Usage: $0 -m <mode> -H <server_ip> -U <user_name> -P <user_password> [command_list] -g <grep with i> -t <tail>"
	echo "       [command_list] ipmi command after -H -U -P"
	echo "       <mode> $mode(default) 0:ipmitool 1:redfish"
	echo "       <server_ip> $server_ip(default)"
	echo "       <user_name> $user_name(default)"
	echo "       <user_password> $user_pwd(default)"
	echo "Features:"
	echo "       * Support ipmitool and redfish interface"
	echo "       * Support one time server config settings"
	echo "       * Support |grep (-g) and |tail (-t)"
	echo "       * Support keywords highlight including [command_list] and '@odata' in redfish mode"	
	echo ""
}

STAGE(){
	if [ $1 == "start" ]; then
		echo "[INF] Stop mctpd..."
		COLOR_PRINT "skip" "BLACK"
		echo "[INF] Disable sensor polling..."
		COLOR_PRINT "skip" "BLACK"
		echo "[INF] Try to switch fencing to HOST BMC..."
		SMBPBI_FENCE_SWITCH "hostbmc"
	elif [ $1 == "stop" ]; then
		echo "[INF] Try to switch fencing to HMC..."
		SMBPBI_FENCE_SWITCH "hmc"
		echo "[INF] Start sensor polling..."
		COLOR_PRINT "skip" "BLACK"
		echo "[INF] Start mctpd..."
		COLOR_PRINT "skip" "BLACK"
	fi
}
# --------------------------------- COMMON lib --------------------------------- #

APP_HEADER

SHORT=m:,H:,U:,P:,t:,g:,h
LONG=mode:,ip:,user:,pwd:,tail,grep,help
OPTS=$(getopt -a -n weather --options $SHORT --longoptions $LONG -- "$@")

eval set -- "$OPTS"

MIN_CHECK_CNT=4
check_cnt=0
while :
do
  case "$1" in
	-m | --mode )
		if [ $2 == 0 ]; then
			mode=$IPMITOOL_MODE
		elif [ $2 == 1 ]; then
			mode=$REDFISH_MODE
		else
			echo "try to enter default mode.."
		fi
		shift 2
		;;
  	-H | --ip )
		SERVER_IP="$2"
		shift 2
		;;
	-U | --user )
		USER_NAME="$2"
		shift 2
		;;
	-P | --pwd )
		USER_PWD="$2"
		shift 2
		;;
	-t | --tail)
		extend_command="$extend_command |tail -n $2"
		shift 2
		;;
	-g | --grep)
		extend_command="$extend_command |grep -i $2"
		shift 2
		;;
    -h | --help)
		APP_HELP
		exit 2
		;;
    --)
		command="${@:2}"
		shift;
		break
      ;;
    *)
      echo "Unexpected option: $1"
      ;;
  esac
done

SERVER_INIT $SERVER_IP $USER_NAME $USER_PWD
if [ $ipmi_init_success == 0 ]; then
	exit 1
fi

COLOR_PRINT "Enter $mode mode..."
if [ $mode == $IPMITOOL_MODE ]; then
	IPMI_SEND 0 "$command $extend_command"
elif [ $mode == $REDFISH_MODE ]; then
	REDFISH_SEND 0 "$command" "$extend_command"
fi


#!/usr/bin/env bash
SCP_PATH=`pwd`
CMAKE_BUILD=1           #0 for Makefile, 1 for CMake
SCP_BUILD_MODE=Debug  #Release or Debug
YC810_PLATFORM_VARIANT=0       #0 for YC810 FPGA, 1 for YC810 FVP, 2 for YC810 EMU, 3 for YC810 Chip
SCP_COMPILER_PATH=/home/10093/workspace/ysemi/RD-N2-Cfg1-20220818/scp/../tools/gcc/gcc-arm-none-eabi-10-2020-q4-major/bin/
TOOL_PATH=${SCP_PATH}/tools/
TARGET_PRODUCT="yc810"
ROMPATCH_SRC_PATH=${SCP_PATH}/product/yc810/scp_rompatch
build_targets=()
SCP_TBBR_ENABLE=0
LOG_LEVEL=0		#0 for TRACE, 1 INFO, 2 warn, 3 error, 4 crit
FIP_PACK_ROMPATCH=0	# pack rompatch or not

declare -A platform_map=(["fpga"]="0" ["fvp"]="1" ["emu"]="2" ["chip"]="3")

get_shell_type() {
	tty -s && echo "INTERACTIVE" || echo "NON-INTERACTIVE"
}


set_formatting() {
	if [ "$(get_shell_type)" = "INTERACTIVE" ] ; then
		export BOLD="\e[1m"
		export NORMAL="\e[0m"
		export RED="\e[31m"
		export GREEN="\e[32m"
		export YELLOW="\e[33m"
		export BLUE="\e[94m"
		export CYAN="\e[36m"
	fi
}


get_platform_names() {
    echo "fpga"
    echo "fvp"
    echo "emu"
    echo "chip"
}


get_num_platforms() {
	get_platform_names | wc -l
}


#If missing the platform, and there's only one platform, use that
#If missing the platform, and there's many platforms, show a warning but then
#continue to build everything
set_default_platform() {
	declare -i no_platforms
	no_platforms=$(get_num_platforms)
    echo "no_platforms is ${no_platforms}"
	if [ $no_platforms -eq 1 ] ; then
		plat=$(get_platform_names)
		YC810_PLATFORM_VARIANT=$(basename $plat)
	fi
	if [ -z "$YC810_PLATFORM_VARIANT" ] ; then
		set_formatting
		echo -e "${RED}Could not deduce which platform to build.${NORMAL}"
		echo -e "${RED}Proceeding to build for YC810 FPGA platforms.${NORMAL}"
		YC810_PLATFORM_VARIANT=0
        TARGET_PRODUCT="yc810"
        SCP_TBBR_ENABLE=0
	fi
}

usage_exit ()
{
	set_formatting
	echo -e "${BOLD}Usage: ${NORMAL}"
	declare -i num_plats
	num_plats=$(get_num_platforms)
	# if [ $num_plats -eq 1 ] ; then
		# echo -en "	$0 ${RED}[-p <platform>]${NORMAL} ${GREEN}-t <target>${NORMAL} ${YELLOW}-s ${NORMAL} "
	# else
	echo -en "	$0 ${YELLOW}-p <platform>${NORMAL} \
${YELLOW}-t <target>${NORMAL} \
${YELLOW}-s ${NORMAL} \
${YELLOW}<CMD> ${NORMAL}"
	# fi
    echo ""
	echo -en "        ${GREEN}<platform>: 0---fpga, 1---fvp, 2---emu, 3---chip ${NORMAL}"
    echo ""
	echo -en "        ${BLUE}<target>: yc810,rdn2 ${NORMAL}"
    echo ""
	echo -en "        ${RED}-s: set to enable SCP_TBBR_ENABLE ${NORMAL}"
    echo ""
	echo -en "        ${CYAN}<CMD>: all/scp_rom/scp_ram/mcp_rom/mcp_ram ${NORMAL}"
    echo ""
	echo -en "        ${CYAN}fip/emu/rompatch/clean ${NORMAL}"
    echo ""
	exit $1

}



parse_params() {
	#If this is called multiple times, let's ensure that it's handled
	unset OPTIND
	unset CMD

	#Parse the named parameters
	while getopts "p:a:hgt:d:s" opt; do
		case $opt in
			p)
                TEMP=${platform_map[$OPTARG]}
                echo "TEMP is $TEMP"
                if [ -z "$TEMP" ];
                then
				    export YC810_PLATFORM_VARIANT=0
                else
				    export YC810_PLATFORM_VARIANT=$TEMP
                fi
                echo "YC810_PLATFORM_VARIANT is $YC810_PLATFORM_VARIANT"
				;;
			t)
				export TARGET_PRODUCT="$OPTARG"
                echo "TARGET_PRODUCT is $TARGET_PRODUCT"
				;;
			s)
				export SCP_TBBR_ENABLE=1
                echo "SCP_TBBR_ENABLE is $SCP_TBBR_ENABLE"
				;;
			d)
				# source $PARSE_PARAMS_DIR/.debug
                export SCP_BUILD_MODE="$OPTARG"
                echo "SCP_BUILD_MODE is $OPTARG"
				;;
			h)
				usage_exit 0
				;;
			g)
				usage_exit 0
				;;
			\?)
				usage_exit 0
				;;
		esac
	done
	export CMD=${@:$OPTIND:1}
	if [ -z "$CMD" ] ; then
        echo "122,CMD is $CMD"
		set_formatting
        usage_exit 1
	fi

    if [ -z "$YC810_PLATFORM_VARIANT" ] ; then
        echo "128,YC810_PLATFORM_VARIANT is $YC810_PLATFORM_VARIANT"
		set_default_platform
	fi

    # echo "YC810_PLATFORM_VARIANT is ${YC810_PLATFORM_VARIANT}"
    # echo "TARGET_PRODUCT is ${TARGET_PRODUCT}"
    # echo "SCP_TBBR_ENABLE is ${SCP_TBBR_ENABLE}"
}


# set -e


# #Parse the arguments passed in from the command line
# # source $DIR/parse_params.sh
# parse_params $@


# if [ "$CMD" = "all" ] ; then
# 	echo "all"
# else
# 	echo "cmd is $CMD"
# fi

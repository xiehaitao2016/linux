#!/usr/bin/env bash
set -e


do_test()
{
    for item in ${build_targets[@]}; do
        echo "item is $item"
    done
}

do_build () {
    local prd_build_params="";
    local tbbr_build_params="";

    # pushd $TOP_DIR/$SCP_PATH
    # PATH=$SCP_ARM_COMPILER_PATH:$PATH
    echo "SCP_COMPILER_PATH is ${SCP_COMPILER_PATH}"
    
    # echo "PATH is ${PATH}"

    if [ $CMAKE_BUILD -eq 1 ]; then
        if [ -d "cmake-build" ]; then
            rm -r cmake-build
            mkdir -p cmake-build
        fi
    fi

    if [ $CMAKE_BUILD -eq 1 ]; then
        # Build using cmake        

        if [ "$TARGET_PRODUCT" == "rdn2" ]
        then
            prd_build_params=" -DSCP_PLATFORM_VARIANT=1"
        else
            prd_build_params="-DYC810_PLATFORM_VARIANT=$YC810_PLATFORM_VARIANT"
        fi

        # for scp_fw in $build_targets; do
        for scp_fw in ${build_targets[@]}; do
            if [ "$scp_fw" == "scp_romfw" ]; then
                tbbr_build_params="-DSCP_TBBR_ENABLE=$SCP_TBBR_ENABLE"
            else
                tbbr_build_params=""
            fi
            local outdir=$SCP_PATH/output
            vpath=${TARGET_PRODUCT}

            rm -rf ${outdir}/$vpath/$scp_fw
            mkdir -p ${outdir}/$vpath/$scp_fw

            echo "output dir is ${outdir}/$vpath"

            mkdir -p cmake-build/"${TARGET_PRODUCT}/$scp_fw"

            echo
            echo  -e "${GREEN}Configuring CMake to build $scp_fw for $TARGET_PRODUCT on [`date`]${NORMAL}"
            echo
            set -x
            cmake -S "." -B "./cmake-build/${TARGET_PRODUCT}/$scp_fw" \
                -DSCP_TOOLCHAIN:STRING="GNU" \
                -DCMAKE_BUILD_TYPE=$SCP_BUILD_MODE \
                -DSCP_FIRMWARE_SOURCE_DIR:PATH="${TARGET_PRODUCT}/$scp_fw" \
                -DCMAKE_C_COMPILER=${SCP_COMPILER_PATH}/arm-none-eabi-gcc \
                -DCMAKE_ASM_COMPILER=${SCP_COMPILER_PATH}/arm-none-eabi-gcc \
                $prd_build_params \
                $tbbr_build_params
            { set +x;  } 2> /dev/null

            echo
            echo -e "${GREEN}Starting CMake build on [`date`]${NORMAL}"
            echo
            set -x
            cmake --build "./cmake-build/$TARGET_PRODUCT/$scp_fw" --parallel $PARALLELISM
            { set +x;  } 2> /dev/null

            cp -r cmake-build/$TARGET_PRODUCT/$scp_fw/bin/* ${outdir}/$vpath/$scp_fw/
        done
        # popd
    else # !$CMAKE_BUILD
        echo "using Makefile is not supported now"        
    fi
}

do_clean ()
{
    local plat_string="$TARGET_PRODUCT plat"
    vpath="$TARGET_PRODUCT"
    plat_string="$plat_string and variant $YC810_PLATFORM_VARIANT"

    local outdir=$SCP_PATH/output

    echo
    echo -e "${RED}Cleaning SCP for $plat_string on [`date`]${NORMAL}"
    echo
    if [ $CMAKE_BUILD -eq 1 ]; then
        # Build using cmake
        set -x
        rm -rf $SCP_PATH/cmake-build/$item
        { set +x;  } 2> /dev/null
    else
        # Build using make
        set -x
        make PLATFORM=$item clean
        { set +x;  } 2> /dev/null
    fi
    rm -rf ${outdir}
}
do_package ()
{
    echo "do_package done"
}

do_fip_create()
{
    local fip_tool=${TOOL_PATH}/fiptool/fiptool
    local cert_tool=${TOOL_PATH}/cert_create/cert_create
    local scp_bl2_bin_path=$SCP_PATH/output/yc810/scp_ramfw
    local mcp_bl2_bin_path=$SCP_PATH/output/yc810/mcp_ramfw
    local scp_rompatch_bin_path=$SCP_PATH/output/yc810/scp_rompatch

    local scp_bl2_fip_param="--scp-fw $scp_bl2_bin_path/yc810-bl2.bin"
    local mcp_bl2_fip_param="--mcp-fw $mcp_bl2_bin_path/yc810-mcp-bl2.bin"
    local scp_rompatch_fip_param=""
    if [ "${FIP_PACK_ROMPATCH}" == "1" ]; then
        scp_rompatch_fip_param="--scp-rompatch $scp_rompatch_bin_path/rompatch.bin"   
    fi

    local fip_param="${scp_bl2_fip_param} ${mcp_bl2_fip_param} ${scp_rompatch_fip_param}"
    local rot_key=$SCP_PATH/module/auth/src/rotpk/yc_rotprivk_rsa.pem

    if [ "${SCP_TBBR_ENABLE}" == "1" ]; then
        local scp_bl2_cert_param="--scp-fw-cert $SCP_PATH/output/yc810/scp_bl2.crt"

        local trusted_key_cert_param="--trusted-key-cert $SCP_PATH/output/yc810/trusted_key.crt"
        local mcp_bl2_cert_param="--mcp-fw-key-cert $SCP_PATH/output/yc810/mcp_bl2_key.crt \
                                --mcp-fw-cert $SCP_PATH/output/yc810/mcp_bl2.crt"

        local scp_rompatch_cert_param=""
        if [ "${FIP_PACK_ROMPATCH}" == "1" ]; then
        scp_rompatch_cert_param="--scp-rompatch-key-cert $SCP_PATH/output/yc810/scp_rompatch_key.crt \
                                        --scp-rompatch-cert $SCP_PATH/output/yc810/scp_rompatch.crt"
        fi

        fip_param="${fip_param} ${scp_bl2_cert_param} ${trusted_key_cert_param} ${mcp_bl2_cert_param}"

        cert_tool_param="${fip_param} --rot-key ${rot_key} -n --tfw-nvctr 31 --ntfw-nvctr 223"
    fi

    if [[ -f $scp_bl2_bin_path/yc810-bl2.bin && -f $mcp_bl2_bin_path/yc810-mcp-bl2.bin && "${SCP_TBBR_ENABLE}" == "1" ]]; then
        echo "cert_tool_param is $cert_tool_param"
        ${cert_tool} ${cert_tool_param}

        echo "fip_param is $fip_param"

        ${fip_tool} create ${fip_param} $SCP_PATH/output/yc810/fip.bin
        echo ${ATF_BUILD_OUT}"/fip.bin success"
    else
      echo "fip_param is $fip_param"
      ${fip_tool} create ${fip_param} $SCP_PATH/output/yc810/fip.bin
      echo "create normale fip.bin success"
    fi
}

if [ $# -lt 1 ]; then
	echo "Usage: $0 [arg]"
	echo "all: build the all mscp images"
	echo "scp_rom: build scp_rom"
	echo "scp_ram: build scp_ram"
	echo "mcp_rom: build mcp_rom"
	echo "mcp_ram: build mcp_ram"
    echo "clean: clean all output files"
fi

make_mscp()
{
    do_build
    # do_test
}

do_emu_convert()
{
    od  -v -A n -t x8 -w8 output/${TARGET_PRODUCT}/scp_romfw/${TARGET_PRODUCT}-bl1.bin | tr -d ' ' > output/${TARGET_PRODUCT}/scp_rom_chip_0.image64
    od  -v -A n -t x8 -w8 output/${TARGET_PRODUCT}/scp_ramfw/${TARGET_PRODUCT}-bl2.bin | tr -d ' ' > output/${TARGET_PRODUCT}/scp_ram_chip_0.image64
    od  -v -A n -t x8 -w8 output/${TARGET_PRODUCT}/mcp_romfw/${TARGET_PRODUCT}-mcp-bl1.bin | tr -d ' ' > output/${TARGET_PRODUCT}/mcp_rom_chip_0.image64
    od  -v -A n -t x8 -w8 output/${TARGET_PRODUCT}/mcp_ramfw/${TARGET_PRODUCT}-mcp-bl2.bin | tr -d ' ' > output/${TARGET_PRODUCT}/mcp_ram_chip_0.image64
    echo "convert all bin to image64"
    find ./output/${TARGET_PRODUCT}/ -name "*.image64"
}

make_rompatch()
{
    if [ "$TARGET_PRODUCT" == "yc810" ]
    then
        echo "compile rompatch"
        cd ${ROMPATCH_SRC_PATH} && ./build_rompatch.sh all
    else
        echo "no need compile rompatch"
    fi
}

make_fip()
{
    if [ "$TARGET_PRODUCT" == "yc810" ]
    then
        echo "do fip create"
        do_fip_create
    else
        echo "no fip create"
    fi
}

__do_build_all_loop() 
{
	if [ -z "$TARGET" ] ; then
        TARGET="xxx"
    else
		TARGET=$TARGET
    fi
    echo "__do_build_all_loop"
    echo "CMD is ${CMD}"
}

__do_build_all()
{
	local CMD=$1
    echo "__do_build_all"
    echo "CMD is ${CMD}"
}

#Parse the arguments passed in from the command line
source ./env.sh

# echo "SCP_PATH is ${SCP_PATH}"

parse_params $@


echo "begin to build"
echo "YC810_PLATFORM_VARIANT is ${YC810_PLATFORM_VARIANT}"
echo "TARGET_PRODUCT is ${TARGET_PRODUCT}"
echo "SCP_TBBR_ENABLE is ${SCP_TBBR_ENABLE}"
echo "SCP_BUILD_MODE is ${SCP_BUILD_MODE}"

case $CMD in
    clean)
    echo "do_clean"
    do_clean
    ;;

    scp_rom)
    echo "scp_rom"
    build_targets=(scp_romfw)
    make_mscp
    ;;

    scp_ram)
    echo "scp_ram"
    build_targets=(scp_ramfw)
    make_mscp
    ;;

    mcp_rom)
    echo "mcp_rom"
    build_targets=(mcp_romfw)
    make_mscp
    ;;

    mcp_ram)
    echo "mcp_ram"
    build_targets=(mcp_ramfw)
    make_mscp
    ;;

    fip)
    echo "fip"
    build_targets=(fip)
    make_fip
    ;;

    rompatch)
    echo "rompatch"
    make_rompatch
    ;;

    emu)
    echo "emu"
    do_emu_convert
    ;;

    all)
        echo "all"
        build_targets=(scp_romfw scp_ramfw mcp_romfw mcp_ramfw)
        make_mscp
        make_rompatch
        make_fip
    ;;
esac
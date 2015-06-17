#!/bin/bash

updateBox()
{
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root" 1>&2
        exit 1
    fi

    echo "-> Installing apt-get packages"

    aptitude update
    aptitude -y install build-essential vagrant
    aptitude -y install ruby1.9.1-full
    gem install fpm

    echo "Done!"
}

getXtoolsArmv5()
{
    if [ ! -d x-tools ]; then
        echo "-> Installing Cross Compiler ARMv5"
        echo "-> Downloading Cross Compiler ARMv5"
        wget -q http://archlinuxarm.org/builder/xtools/x-tools.tar.xz;
        echo "-> End of Download Cross Compiler ARMv5"
        tar Jxfv x-tools.tar.xz
    else
        echo "Cross Compiler for ARMv5 already installed ..."
    fi
}

getXtoolsArmv6()
{
   if [ ! -d x-tools6h ]; then
         echo "-> Installing Cross Compiler ARMv6"
         echo "-> Downloading Cross Compiler ARMv6"
         wget -q http://archlinuxarm.org/builder/xtools/x-tools6h.tar.xz;
         echo "-> End of Download Cross Compiler ARMv6"
         tar Jxfv x-tools6h.tar.xz
      else
         echo "Cross Compiler for ARMv6 already installed ..."
   fi
}

getXtoolsArmv7()
{
   pwd
   if [ ! -d x-tools7h ]; then
         echo "-> Installing Cross Compiler ARMv7"
         echo "-> Downloading Cross Compiler ARMv7"
         wget -q http://archlinuxarm.org/builder/xtools/x-tools7h.tar.xz;
         echo "-> End of Download Cross Compiler ARMv7"
         tar Jxfv x-tools7h.tar.xz
      else
         echo "Cross Compiler for ARMv7 already installed ..."
   fi
}

getNode()
{
    echo "-> Getting latest node.js version"
    result=$(wget -qO- http://nodejs.org/dist/latest/ | egrep -o 'node-v[0-9\.]+.tar.gz' | tail -1)
    tmp=$(echo $result | egrep -o 'node-v[0-9\.]+')
    mm=$(echo $result | egrep -o '[0-9\.]+')
    majorminor=${mm:0:${#mm} - 3} # chop 3 last chars
    version=${tmp:0:${#tmp} - 1}
    if [ ! -e $result ]; then
        echo "-> Downloading $result"
        wget -q http://nodejs.org/dist/latest/$result
        echo "-> End of Download $result"
        tar xvzf $result
        ln -s $version node
     else
        echo "You already have the latest node.js version : $version. majorminor: $majorminor"
    fi
}

buildNodeJSArmV5()
{
   OLDPATH=${PATH}
   export PATH="${PWD}/x-tools/arm-unknown-linux-gnueabi/bin:$PATH"
   export TOOL_PREFIX="arm-unknown-linux-gnueabi"
   export CC="${TOOL_PREFIX}-gcc"
   export CXX="${TOOL_PREFIX}-g++"
   export AR="${TOOL_PREFIX}-ar"
   export RANLIB="${TOOL_PREFIX}-ranlib"
   export LINK="${CXX}"
   export CCFLAGS="-march=armv5t -mfpu=softfp -marm"
   export CXXFLAGS="-march=armv5t -mno-unaligned-access"
   export OPENSSL_armcap=5
   export GYPFLAGS="-Darmeabi=soft -Dv8_can_use_vfp_instructions=false -Dv8_can_use_unaligned_accesses=false -Darmv7=0"
   export VFP3=off
   export VFP2=off
   PREFIX_DIR="/usr/local"
   version=$(readlink node | egrep -o '[0-9\.]+')
   majorminor=${version:0:${#version} - 3}
   cd node
   ./configure --without-snapshot --dest-cpu=arm --dest-os=linux --prefix="${PREFIX_DIR}"
   make -j 2
   make install DESTDIR=/tmp/installARMv5
   fpm -s dir -t deb -n nodejs -v "$version" --category web -m "Yuncong Zhang <njitzyc@gmail.com>" --url http://nodejs.org/ \
   --description "Node.js event-based server-side javascript engine Node.js is similar in design to and influenced by systems like Ruby's Event Machine or Python's Twisted. It takes the event model a bit further - it presents the event loop as a language construct instead of as a library. Node.js is bundled with several useful libraries to handle server tasks : System, Events, Standard I/O, Modules, Timers, Child Processes, POSIX, HTTP, Multipart Parsing, TCP, DNS, Assert, Path, URL, Query Strings." \
   -C /tmp/installARMv5 -a armel  -p /tmp/nodejs_$version-armv5_armel.deb  usr/local/
   make clean
   cd -
   export PATH="$OLDPATH"
}

buildNodeJSArmV6()
{
   OLDPATH=${PATH}
   export PATH="${PWD}/x-tools6h/arm-unknown-linux-gnueabihf/bin:$PATH"
   export TOOL_PREFIX="arm-unknown-linux-gnueabihf"
   export CC="${TOOL_PREFIX}-gcc"
   export CXX="${TOOL_PREFIX}-g++"
   export AR="${TOOL_PREFIX}-ar"
   export RANLIB="${TOOL_PREFIX}-ranlib"
   export LINK="${CXX}"
   export CCFLAGS="-march=armv6j -mfpu=vfp -mfloat-abi=hard -DUSE_EABI_HARDFLOAT"
   export CXXFLAGS="-march=armv6j -mfpu=vfp -mfloat-abi=hard -DUSE_EABI_HARDFLOAT"
   export OPENSSL_armcap=6
   export GYPFLAGS="-Darmeabi=hard -Dv8_use_arm_eabi_hardfloat=true -Dv8_can_use_vfp3_instructions=false -Dv8_can_use_vfp2_instructions=true -Darm7=0 -Darm_vfp=vfp"
   export VFP3=off
   export VFP2=on
   PREFIX_DIR="/usr/local"
   version=$(readlink node | egrep -o '[0-9\.]+')
   majorminor=${version:0:${#version} - 3}
   cd node
   ./configure --without-snapshot --dest-cpu=arm --dest-os=linux --prefix="${PREFIX_DIR}"
   make -j 2
   make install DESTDIR=/tmp/installARMv6
   fpm -s dir -t deb -n nodejs -v "$version" --category web -m "Yuncong Zhang <njitzyc@gmail.com>" --url http://nodejs.org/ \
   --description "Node.js event-based server-side javascript engine Node.js is similar in design to and influenced by systems like Ruby's Event Machine or Python's Twisted. It takes the event model a bit further - it presents the event loop as a language construct instead of as a library. Node.js is bundled with several useful libraries to handle server tasks : System, Events, Standard I/O, Modules, Timers, Child Processes, POSIX, HTTP, Multipart Parsing, TCP, DNS, Assert, Path, URL, Query Strings." \
   -C /tmp/installARMv6 -a armhf  -p /tmp/nodejs_$version-armv6_armhf.deb  usr/local
   make clean
   cd -
   export PATH="$OLDPATH"
}

buildNodeJSArmV7()
{
   OLDPATH=${PATH}
   export PATH="${PWD}/x-tools7h/arm-unknown-linux-gnueabihf/bin:$PATH"
   export TOOL_PREFIX="arm-unknown-linux-gnueabihf"
   export CC="${TOOL_PREFIX}-gcc"
   export CXX="${TOOL_PREFIX}-g++"
   export AR="${TOOL_PREFIX}-ar"
   export RANLIB="${TOOL_PREFIX}-ranlib"
   export LINK="${CXX}"
   export CCFLAGS="-march=armv7-a -mtune=cortex-a8 -mfpu=vfp -mfloat-abi=hard -DUSE_EABI_HARDFLOAT"
   export CXXFLAGS="-march=armv7-a -mtune=cortex-a8 -mfpu=vfp -mfloat-abi=hard -DUSE_EABI_HARDFLOAT"
   export OPENSSL_armcap=7
   export GYPFLAGS="-Darmeabi=hard -Dv8_use_arm_eabi_hardfloat=true -Dv8_can_use_vfp3_instructions=true -Dv8_can_use_vfp2_instructions=true -Darm7=1"
   export VFP3=on
   export VFP2=on
   PREFIX_DIR="/usr/local"
   version=$(readlink node | egrep -o '[0-9\.]+')
   majorminor=${version:0:${#version} - 3}
   cd node
   ./configure --without-snapshot --without-ssl --dest-cpu=arm --dest-os=linux --prefix="${PREFIX_DIR}"
   make -j 2
   make install DESTDIR=/tmp/installARMv7
   fpm -s dir -t deb -n nodejs -v "$version" --category web -m "Yuncong Zhang <njitzyc@gmail.com>" --url http://nodejs.org/ \
   --description "Node.js event-based server-side javascript engine Node.js is similar in design to and influenced by systems like Ruby's Event Machine or Python's Twisted. It takes the event model a bit further - it presents the event loop as a language construct instead of as a library. Node.js is bundled with several useful libraries to handle server tasks : System, Events, Standard I/O, Modules, Timers, Child Processes, POSIX, HTTP, Multipart Parsing, TCP, DNS, Assert, Path, URL, Query Strings." \
   -C /tmp/installARMv7 -a armhf  -p /tmp/nodejs_$version-armv7_armhf.deb  usr/local
   make clean
   cd -
   export PATH="$OLDPATH"
}

setEnv()
{
   export TOOL_PREFIX="arm-unknown-linux-gnueabi"
   export CC="${TOOL_PREFIX}-gcc"
   export CXX="${TOOL_PREFIX}-g++"
   export AR="${TOOL_PREFIX}-ar"
   export RANLIB="${TOOL_PREFIX}-ranlib"
   export LINK="${CXX}"
   export PREFIX_DIR="/usr/local"
   export version=$(readlink node | egrep -o '[0-9\.]+')
   export majorminor=${version:0:${#version} - 3}
}

clean()
{
    rm -rf node*
    rm -rf x-tools*
}

case "$1" in
        updateBox)
            updateBox
            ;;

        getNode)
            getNode
            ;;

        getXtools)
            case "$2" in
                5)
                    getXtoolsArmv5
                    ;;
                6)
                    getXtoolsArmv6
                    ;;
                7)
                    getXtoolsArmv7
                    ;;
                *)
                    getXtoolsArmv5
                    getXtoolsArmv6
                    getXtoolsArmv7
                    ;;
            esac
            ;;
        build)
            case "$2" in
                5)
                    buildNodeJSArmV5
                    ;;
                6)
                    buildNodeJSArmV6
                    ;;
                7)
                    buildNodeJSArmV7
                    ;;
                *)
                    buildNodeJSArmV5
                    buildNodeJSArmV6
                    buildNodeJSArmV7
                    ;;
            esac
            ;;

        clean)
            clean
            ;;

        *)
            echo $"Usage: $0 {updateBox|getXtools|getNode|build}"
            exit 1

esac

PATH="$OLDPATH"


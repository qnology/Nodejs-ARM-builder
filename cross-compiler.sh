#!/bin/bash

OLDPATH=${PATH}

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
   fpm -s dir -t deb -n nodejs -v "$majorminor-1vr~squeeze1" --category web -m "Yuncong Zhang <njitzyc@gmail.com>" --url http://nodejs.org/ \
   --description "Node.js event-based server-side javascript engine Node.js is similar in design to and influenced by systems like Ruby's Event Machine or Python's Twisted. It takes the event model a bit further - it presents the event loop as a language construct instead of as a library. Node.js is bundled with several useful libraries to handle server tasks : System, Events, Standard I/O, Modules, Timers, Child Processes, POSIX, HTTP, Multipart Parsing, TCP, DNS, Assert, Path, URL, Query Strings." \
   -C /tmp/installARMv5 -a armel  -p /tmp/nodejs_$version-armv5~squeeze1_armel.deb  usr/local/
   make clean
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
            getXtoolsArmv5
            ;;

        build)
            buildNodeJSArmV5
            ;;
         
        clean)
            clean
            ;;
         
        *)
            echo $"Usage: $0 {updateBox|getXtools|getNode|build}"
            exit 1
 
esac

PATH="$OLDPATH"


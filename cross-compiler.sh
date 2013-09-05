#!/bin/bash

OLDPATH=${PATH}

UpdateBox()
{
   echo "-> Installing apt-get packages"
   aptitude update
   aptitude -y install build-essential
   aptitude -y remove libruby1.8 ruby1.8 ruby1.8-dev rubygems1.8
   aptitude -y install ruby1.9.1-full
   gem install fpm
}

XtoolsArmv5()
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

DownloadNodeJS()
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
         echo "You already have the latest node.js version : $version"
   fi
}

BuildNodeJSArmv5()
{
   export PATH=/home/vagrant/x-tools/arm-unknown-linux-gnueabi/bin:$PATH
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
   PREFIX_DIR="/usr"
   sudo chown -R vagrant: /home/vagrant/
   cd /home/vagrant/node
   ./configure --without-snapshot --dest-cpu=arm --dest-os=linux --prefix="${PREFIX_DIR}"
   make -j 2
   sudo chown -R vagrant: /home/vagrant/
   make install DESTDIR=/tmp/installARMv5
   fpm -s dir -t deb -n nodejs -v "$majorminor-1vr~squeeze1" --category web -m "Yuncong Zhang <njitzyc@gmail.com>" --url http://nodejs.org/ \
   --description "Node.js event-based server-side javascript engine Node.js is similar in design to and influenced by systems like Ruby's Event Machine or Python's Twisted. It takes the event model a bit further - it presents the event loop as a language construct instead of as a library. Node.js is bundled with several useful libraries to handle server tasks : System, Events, Standard I/O, Modules, Timers, Child Processes, POSIX, HTTP, Multipart Parsing, TCP, DNS, Assert, Path, URL, Query Strings." \
   -C /tmp/installARMv5 -a armel  -p /tmp/nodejs_$majorminor-1vr~squeeze1_armel.deb  usr/
   make clean
}

#UpdateBox
cd /home/vagrant/
DownloadNodeJS
#XtoolsArmv5
BuildNodeJSArmv5
PATH="$OLDPATH"

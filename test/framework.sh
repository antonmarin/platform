#!/usr/bin/env sh

should() {
	printf "Should $1"
}
ok() {
	printf "\e[32m ✔ \e[0m\n"
}
initOsVars() {
	OS=`uname -s`
    REV=`uname -r`
    MACH=`uname -m`
    if [ "${OS}" = "Darwin" ]; then
        OIFS="$IFS"
        IFS=$'\n'
        set `sw_vers` > /dev/null
        DIST=`echo $1 | tr "\n" ' ' | sed 's/ProductName:[ ]*//'`
        VERSION=`echo $2 | tr "\n" ' ' | sed 's/ProductVersion:[ ]*//'`
        BUILD=`echo $3 | tr "\n" ' ' | sed 's/BuildVersion:[ ]*//'`
        OSSTR="${OS} ${DIST} ${REV}(SORRY_NO_PSEUDONAME ${BUILD} ${MACH})"
        IFS="$OIFS"
    else
    	# shellcheck disable=SC1091
    	. /etc/os-release
    fi
    echo ${OSSTR}
}

importEnv(){
	set -o allexport
    source $1
    set +o allexport
}

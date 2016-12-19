#!/bin/bash

# ip functions that set variables instead of returning to STDOUT

hexToInt() {
    printf -v $1 "%d\n" 0x${2:6:2}${2:4:2}${2:2:2}${2:0:2}
}
intToIp() {
    local var=$1 iIp
    shift
    for iIp ;do 
        printf -v $var "%s %s.%s.%s.%s" "${!var}" $(($iIp>>24)) \
            $(($iIp>>16&255)) $(($iIp>>8&255)) $(($iIp&255))
    done
}
maskLen() {
    local i
    for ((i=0; i<32 && ( 1 & $2 >> (31-i) ) ;i++));do :;done
    printf -v $1 "%d" $i
}

# The main loop.

while read -a rtLine ;do
    if [ ${rtLine[2]} == "00000000" ] && [ ${rtLine[7]} != "00000000" ] ;then
        hexToInt netInt  ${rtLine[1]}
        hexToInt maskInt ${rtLine[7]}
        if [ $((netInt&maskInt)) == $netInt ] ;then
            for procConnList in /proc/net/{tcp,udp} ;do
                while IFS=': \t\n' read -a conLine ;do
                    if [[ ${conLine[1]} =~ ^[0-9a-fA-F]*$ ]] ;then
                        hexToInt ipInt ${conLine[1]}
                        [ $((ipInt&maskInt)) == $netInt ] && break 3
                    fi
                done < $procConnList
            done
        fi
    fi
done < /proc/net/route 

# And finaly the printout of what's found

maskLen maskBits $maskInt
intToIp addrLine $ipInt $netInt $maskInt
printf -v outForm '%-12s: %%s\\n' Interface Address Network Netmask Masklen
printf "$outForm" $rtLine $addrLine $maskBits\ bits

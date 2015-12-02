#! /bin/sh
echo "Edge leaf configuration."
echo "";
echo "Nickname:";
read nick
echo "Realname:";
read realname
echo "IPv4:";
read ip
echo "IPv6:";
read ip6
if test -z "$ip"
then
echo "Hostname?:";
read hostname
fi
echo "Port:";
read port
echo "Hub? (0=no 1=yes)"
read hubbot

echo "Need to set nat settings ? (1=yes 0=no)"
read nat

if [ $nat -eq 1 ]; then
 echo "Nat ip"
 read natip
 echo "reserved-portramge"
 read natrange
else
 export natip="";
 export natrange="";
fi

if [ $hubbot -eq 1 ]; then
 echo "Run as limbo? (1=yes 0=No)"
 read limbohub
fi

if [ $hubbot -eq 0 ]; then
 export limbohub=0
fi

echo "Which network to use?";
echo "1:EFNET";
echo "2:EFNET IPv6";
echo "3:LiNKNET";
echo "4:LiNKNET SSL";
echo "5:QuakeNet";
echo "6:UnderNet";
echo "0:Custom server file";
read servernet

export serverfile="$nick.servers.tcl"

if [ $servernet -eq 1 ]; then
 wget http://www.codebin.dk/edge09/servers/efnet.tcl
 mv efnet.tcl $nick.servers.tcl
fi

if [ $servernet -eq 2 ]; then
 wget http://www.codebin.dk/edge09/servers/efnetipv6.tcl
 mv efnetipv6.tcl $nick.servers.tcl
fi

if [ $servernet -eq 3 ]; then
 wget http://www.codebin.dk/edge09/servers/linknet.tcl
 mv linknet.tcl $nick.servers.tcl
fi

if [ $servernet -eq 4 ]; then
 wget http://www.codebin.dk/edge09/servers/linknetssl.tcl
 mv linknetssl.tcl $nick.servers.tcl
fi

if [ $servernet -eq 5 ]; then
 wget http://www.codebin.dk/edge09/servers/quakenet.tcl
 mv quakenet.tcl $nick.servers.tcl
fi

if [ $servernet -eq 6 ]; then
 wget http://www.codebin.dk/edge09/servers/undernet.tcl
 mv undernet.tcl $nick.servers.tcl
fi

if [ $servernet -eq 0 ]; then
 wget http://www.codebin.dk/edge09/servers/custom.tcl
 mv custom.tcl $nick.servers.tcl
fi


if test -z "$ip"
then
export b="set my-hostname $hostname"
else
export b=""
fi

cat /dev/null > "tmp.conf";
cat >> "tmp.conf" << EOF
set edge(ip) "$ip"
set edge(ip6) "$ip6"
set edge(port) "$port"
set edge(nick) "$nick"
set edge(altnick) ""
set edge(realname) "$realname"
set edge(username) "$nick"
set edge(limbo) $limbohub

set edge(serverfile) "$serverfile"

set edge(natip) "$natip"
set edge(natrange) "$natrange"

#Any special settings must be below here

source edge.conf
$b
EOF

echo "";
echo "Config file done.";
echo -e "Config file name is $nick.conf";
echo "";
mv tmp.conf $nick.conf

 ./autobotchk $nick -noemail
 ./Edge -m $nick.conf

echo "Create another bot? (1/0)"
read morebots
if [ $morebots -eq 1 ]; then
./makebot
fi

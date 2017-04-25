#!/bin/bash
### Hychem Script Elastic on VDC
### Version 1.0

# Prerequisite is to unstall jq utility to parse json files
#set -x

# Colors for better display
Red='\033[0;31m'
Yel='\033[1;33m'
NC='\033[0m' # No Color

# Variables to run the test
PROFILE="Dady"												#-> VDC Profile to use
ZONEID="374b937d-2051-4440-b02c-a314dd9cb27e"				#-> VDC Zone ID
TEMPLATEID="1c7e1212-efab-48a3-987c-2a00ab51e8f5"			#-> VDC Template ID
SERVICEOFFERINGID="4cb92069-e001-4637-8848-76d74f406bb8"	#-> VDC Service ID
NETWORKID="abbd9ba8-18ba-4910-9286-c57b0091f453"			#-> VDC Network ID
LBID="91d43fb5-6f81-4315-8bb7-b3df23e836e9"					#-> VDC LoadBalancer ID

#z="fasle"
VMID=""
LBTMP=""
File="/tmp/hearbeat.vdc"									#-> File where is process the heardbeat
TMP="/tmp/tmp.vdc"											#-> File for tmp deployment
MIN="50"
MAX="70"
VMS="2"

# Set VDC profile to use for the test
/bin/cloudmonkey set profile $PROFILE

lb_check () {
# List number of nodes in the LB
LBTMP=`/bin/cloudmonkey -d 'json'  list loadbalancerruleinstances id=$1`
clear
COUNT=`echo $LBTMP | /usr/bin/jq '.count'`
printf "\nNumber of Nodes in Load-Balancer = ${Red}$COUNT${NC}\n\n"
}
lb_add () {
/bin/cloudmonkey -b assign toloadbalancerrule id=$1 virtualmachineids=$2 > /dev/null
if [ $? -ne 0 ]
then
	/bin/cloudmonkey -b assign toloadbalancerrule id=$1 virtualmachineids=$2 > /dev/null
fi
}
snmp_CPU_check () {
# We test the CPU IDLE please change the test as your convinient
PERF="0"
i="0"
while [ $i -lt $1 ]
do
	# Get the hostname
	HOST=`echo $LBTMP | /usr/bin/jq '.loadbalancerruleinstance['$i'].nic[0].ipaddress'`
	echo $HOST
	# Get the VM id
	VMID=`echo $LBTMP | /usr/bin/jq '.loadbalancerruleinstance['$i'].id'`
	echo $VMID
	# Get 
	IDLE=`/bin/snmpget -t 300 -c public -v 2c -On $HOST .1.3.6.1.4.1.2021.11.11.0 | cut -d: -f2`
	printf "Node $i ${Yel}: $HOST\t: $VMID\t=\t$IDLE%%${NC}\n"
	PERF=`expr $PERF + $IDLE`
	i=$[$i+1]
done
PERF=`expr $PERF / $1`
printf "\nAVG CPU Idle = ${Red}$PERF%%${NC}\n\n"

if [ $PERF -lt $MIN ]
then
	printf "${Red}Performance:$PERF%% is too low${NC}\n"
	return 1
	elif [ $PERF -gt $MAX ] && [ $1 -gt $VMS ]
	then
		printf "${Red}Performance:$PERF%% is too high${NC}\n"
		return 2
		else
		printf "${Red}Performance:$PERF%% is perfect${NC}\n"
		return 0
fi
}
vm_deploy () {
/bin/cloudmonkey -b -d 'json' deploy virtualmachine \
zoneid=$1 \
templateid=$2 \
serviceofferingid=$3 \
networkids=$4 > $5
sed -i '1d' $5
VMID=`cat $5 | /usr/bin/jq ".jobresult.virtualmachine.id" | cut -d"\"" -f2`
sleep 120
printf "${Yel}--> Adding the VM to the LB${NC}\n"
lb_add $LBID $VMID 
}
vm_destroy () {
i=$[$1-1]
VMID=`cat $2 | /usr/bin/jq '.loadbalancerruleinstance['$i'].id' | cut -d"\"" -f2`
/bin/cloudmonkey -b destroy virtualmachine expunge=true id=$VMID > /dev/null
}

# Run the daemon to check the service breack it by CLT c
while [ 0 -eq 0 ]
do
	# List number of nodes in the LB
	lb_check $LBID
	snmp_CPU_check $COUNT
case $? in
0) echo "nothin." 
printf "${Yel}--> Nothing to do${NC}\n"
;;
1) echo "Add." 
printf "${Yel}--> Deploying another VM${NC}\n"
;;
2) echo "remove." 
printf "${Yel}--> Removing a VM${NC}\n"
;;
esac

	sleep 10
done
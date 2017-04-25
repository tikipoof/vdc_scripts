#!/bin/bash
### Hychem Script API test VDC
### Version 1.0

DISPLAY="json"
FOLDER=/root/.cloudmonkey/vm_deploy.vdc
ZONEID="374b937d-2051-4440-b02c-a314dd9cb27e"
TEMPLATEID="9db5fe28-531a-4404-a37f-e1a5c940c4ee"
SERVICEOFFERINGID="f41b6bd2-8b5b-4350-bd4b-d91d84beef6b"
NETWORKID="5262ba61-00dd-4913-849a-5337082fc7a1"

list="Venus
Mars
Jupiter
Uranus
Neptune"

for i in $list
do
### Create a machine with IP
time /usr/bin/cloudmonkey -b -d 'json' deploy virtualmachine \
zoneid=$ZONEID \
templateid=$TEMPLATEID \
serviceofferingid=$SERVICEOFFERINGID \
name=$i \
networkids=$NETWORKID >> $FOLDER
done

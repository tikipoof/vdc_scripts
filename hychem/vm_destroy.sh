#!/bin/bash
### Hychem Script API test VDC
### Version 1.0

DISPLAY="json"
FOLDER=/root/.cloudmonkey/vm_destroy.vdc
list=" 
d453926c-35c8-4cc1-9de9-7860f073f29e
63f06893-301c-49f9-a929-154cf427e84b
09fc8f4f-8670-4082-b859-41b563b60050
42f5e91a-1903-4271-b09d-155064d0d7d0
780d07e9-c736-4dd9-91fc-912aa82a0317
"

for i in $list
do
### Create a machine with IP
time /usr/bin/cloudmonkey -b destroy virtualmachine expunge=true id=$i >> $FOLDER
done

# OOB_ACCESS
Out-band ipmi/redfish access tool

### Purpose:
    Tools that used to send oob command via ipmitool/redfish.

### Latest rlease:
    * ipmi_access: v1.3.0 - 2023/10/13

### Version:
**[ipmi_access]**
- 1.3.0 - Support redfish post mode - 2023/10/13
  - Feature:
    - Support action(-a) and data(-d) ARGS for REDFISH mode.
    - Support keyword color print in redfish mode.
  - Bug:
  	- none

- 1.2.0 - Support redfish keywords print - 2023/10/12
  - Feature:
    - Support json format in redfish mode.
    - Support keyword color print in redfish mode.
  - Bug:
  	- none

- 1.1.0 - xx - 2023/10/04
  - Feature:
  	- none
  - Bug:
  	- none
 
- 1.0.0 - First commit - 2023/09/21
  - Feature:
  	- none 
  - Bug:
  	- none

### Requirement:
- OS
  - Linux: support
- Enviroment
  - Ubuntu 18.04

### Usage
  - **STEP0. Create server config file(only do once)**\
  Create server config file by following command.\
  ./ipmi_access.sh -H < server_ip > -U < user_name > -P < user_password > -m < mode > -a < action > [ command_list ] -d < data > -g < grep_with_i > -t < tail >
  
  - **STEP1. Send commands**\
```
**HELP**
mouchen@mouchen-System-Product-Name:~$ ./ipmi_access.sh -h
===================================
APP NAME: IPMI ACCESS TOOL
APP VERSION: 1.3.0
APP RELEASE DATE: 2023/10/13
APP AUTHOR: Mouchen
===================================
Usage: /usr/local/bin/mc_command/mcoob -H <server_ip> -U <user_name> -P <user_password> -m <mode> -a <action> [command_list] -d <data> -g <grep with i> -t <tail>
       [command_list] ipmi command after -H -U -P
       <mode> ipmitool(default) 0:ipmitool 1:redfish
       <action> get(default) get:REDFISH_GET post:REDFISH_POST
       <data> data for REDFISH mode input only
       <server_ip> 10.10.11.78(default)
       <user_name> admin(default)
       <user_password> admin(default)
Features:
       * Support ipmitool and redfish interface
       * Support one time server config settings
       * Support |grep (-g) and |tail (-t)
       * Support keywords highlight including [command_list] and '@odata' in redfish mode

**IPMI example**
mouchen@mouchen-System-Product-Name:~/Documents/BMC/common/tool/OOB_ACCESS$ ./ipmi_access.sh raw 6 1
===================================
APP NAME: IPMI ACCESS TOOL
APP VERSION: 1.3.0
APP RELEASE DATE: 2023/10/12
APP AUTHOR: Mouchen
===================================
{Server info}
* ip:       10.10.11.78
* user:     admin
* password: admin

Enter ipmitool mode...
[input]
ipmitool -H 10.10.11.78 -U admin -P admin raw 6 1
[output]
 20 81 03 05 02 bf 37 01 00 e5 0a 00 00 00 00

**REDFISH example**
mouchen@mouchen-System-Product-Name:~/Documents/BMC/common/tool/OOB_ACCESS$ ./ipmi_access.sh -m 1 hmc/redfish/v1/Chassis/HGX_GPU_SXM_1/Sensors/HGX_GPU_SXM_1_TEMP_0
===================================
APP NAME: IPMI ACCESS TOOL
APP VERSION: 1.3.0
APP RELEASE DATE: 2023/10/12
APP AUTHOR: Mouchen
===================================
{Server info}
* ip:       10.10.11.78
* user:     admin
* password: admin

Enter redfish mode...
[input]
curl -s -k -u admin:admin https://10.10.11.78/hmc/redfish/v1/Chassis/HGX_GPU_SXM_1/Sensors/HGX_GPU_SXM_1_TEMP_0
[output]
{
    "@odata.id": "/redfish/v1/Chassis/HGX_GPU_SXM_1/Sensors/HGX_GPU_SXM_1_TEMP_0",
    "@odata.type": "#Sensor.v1_2_0.Sensor",
    "Id": "HGX_GPU_SXM_1_TEMP_0",
    "Name": "HGX GPU SXM 1 TEMP 0",
    "PhysicalContext": "GPU",
    "Reading": 34.875,
    "ReadingType": "Temperature",
    "ReadingUnits": "Cel",
    "RelatedItem": [
        {
            "@odata.id": "/redfish/v1/Systems/HGX_Baseboard_0/Processors/GPU_SXM_1"
        }
    ],
    "Status": {
        "Conditions": [],
        "Health": "OK",
        "HealthRollup": "OK",
        "State": "Enabled"
    }
}
```

### Note
- Do not delete **server_cfg**, otherwise STEP0 is required once.


#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/home

#######################################################################
# Version 0.5 DRBackup.sh
# direct transfer from source to destination
#######################################################################
##########################
# DR_backup parameters
##########################
# colors output
ON_RED='\e[41m'
ON_GREEN='\e[42m'
ON_WHITE='\033[47m'
BLUE='\e[0;34m'
YELLOW='\e[0;33m'
WHITE='\e[0;37m'
BLACK='\e[0;30m'
GREEN='\e[0;32m'
NC="\033[0m" # No Color
# TMP params
I=0
K=1
# arrays IP_VPN list, DRCODE list
declare -a ARRAY_VPN=("170.0.0.118" "170.0.0.111" "170.0.0.104" "170.0.0.106" "170.0.0.108" "170.0.0.109" "170.0.0.110" "170.0.0.112"
        "170.0.0.113" "170.0.0.114" "170.0.0.115" "170.0.0.121" "170.0.0.122" "170.0.0.123" "170.0.0.125" "170.0.0.126" "170.0.0.127" "170.0.0.128"
        "170.0.0.129" "170.0.0.130" "170.0.0.131" "170.0.0.132" "170.0.0.134" "170.0.0.135" "170.0.0.136" "170.0.0.158" "170.0.0.138" "170.0.0.139"
        "170.0.0.140" "170.0.0.141" "170.0.0.142" "170.0.0.143" "170.0.0.145" "170.0.0.146" "170.0.0.147" "170.0.0.148" "170.0.0.149" "170.0.0.150"
        "170.0.0.151" "170.0.0.152" "170.0.0.154" "170.0.0.155" "170.0.0.156" "170.0.0.157" "170.0.0.160" "170.0.0.161" "170.0.0.162" "170.0.0.165"
        "170.0.0.166" "170.0.0.116" "170.0.0.137" "170.0.0.159" "170.0.0.153" "170.0.0.133")
declare -a ARRAY_DRCODE=("C1-B052-DR1" "C1-B036-DR1" "C1-B308-DR1" "C1-B018-DR1" "C1-B028-DR1" "C1-B031-DR1" "C1-B035-DR1" "C1-B037-DR1"
        "C1-B040-DR1" "C1-B041-DR1" "C1-B050-DR1" "C1-B024-DR1" "C1-B062-DR1" "C1-B014-DR1" "C1-B218-DR1" "C1-B063-DR1" "C1-B061-DR1" "C1-B064-DR1"
        "C1-B065-DR1" "C1-B067-DR1" "C1-B074-DR1" "C1-B130-DR1" "C1-B214-DR1" "C1-B215-DR1" "C1-B215-DR2" "C1-B016-DR1" "C1-B217-DR1" "C1-B219-DR1"
        "C1-B221-DR1" "C1-B222-DR1" "C1-B301-DR1" "C1-B302-DR1" "C1-B307-DR1" "C1-B309-DR1" "C1-B310-DR1" "C1-B318-DR1" "C1-B054-DR1" "C1-B054-DR2"
        "C1-B211-DR1" "C1-B009-DR1" "C1-B056-DR1" "C1-B213-DR1" "C1-B213-DR2" "C1-B314-DR1" "C1-B008-DR1" "C1-B000-DR1" "C1-B074-DR2" "C1-B016-DR2"
        "C1-B016-DR3" "C1-B051-DR1" "C1-B216-DR1" "C1-B028-DR2" "C1-B134-DR1" "C1-B212-DR1")
DATE_TIME=$(date '+%d-%b-%Y|%I:%M:%S')
DATE=$(date '+%d-%b-%Y')

## Remote PARAMETER
# server/drstore/data/conf.ini
CONF_INI_FILE="conf.ini"
# server/drstore/data/openvpn
DATA_FOLDER_NAME="data/"
# server/drstore/conf
CONF_FOLDER_NAME="conf/"
TAR_GZ_EXTENSION=".tar.gz"
DRSTORE_FOLDER_REMOTE_PATH="/server/drstore/"

## Local Parameter
# log file path
BACKUP_LOG_FILE_NAME=$DATE"-dr-backup.log"
LOG_VPN_CONNECTION_FILE_NAME="vpn-connection.log"
DRSTORE_ARCHIVE_FOLDER=$DATE"/"
DRSTORES_BACKUP_FOLDER_LOCAL_PATH=$HOME"/DRSTORES_BACKUP/"
DRSTORE_FULL_LOCAL_PATH=${DRSTORES_BACKUP_FOLDER_LOCAL_PATH}${DRSTORE_ARCHIVE_FOLDER}

# VPN IP address & internet Address
ATI_DNS="8.8.8.8"
ATI_DNS_PING_RESULT=0
IP_VPN_SERVER="170.0.0.1"
IP_VPN_SERVER_PING_RESULT=0
NETWORK_CONNECTION_RESULT=0

##########################
# End DR_backup parameters
##########################
##########################
# start scripting
##########################
# start process
function start_screen () {
    echo -e "${BLACK}${ON_WHITE}----------------------------------------------------------------------------------------------------${NC}"
    echo -e "${BLACK}${ON_WHITE}----------------------------  D A T A - R E C E I V E R - B A C K U P  -----------------------------${NC}"
    echo -e "${BLACK}${ON_WHITE}----------------------------------------------------------------------------------------------------${NC}"
}
# end process
function end_screen () {
    # list of not connected DR
    write_on_log_file ${DRSTORES_BACKUP_FOLDER_LOCAL_PATH}${LOG_VPN_CONNECTION_FILE_NAME} "-----------------------|---------------------------------------------------------------------------------"
    write_on_log_file ${DRSTORES_BACKUP_FOLDER_LOCAL_PATH}${LOG_VPN_CONNECTION_FILE_NAME} "$(date '+%d-%b-%Y|%I:%M:%S') | ${ARRAY_DRCODE[@]} -- Not Connected - Finish Process"
    echo -e "${BLACK}${ON_WHITE}----------------------------------------------------------------------------------------------------${NC}"
    echo -e "${BLACK}${ON_WHITE}-- ${ARRAY_DRCODE[@]} -- Not Connected${NC}"
    echo -e "${BLACK}${ON_WHITE}---- $(date '+%d-%b-%Y|%I:%M:%S') -------  D A T A   R E C E I V E R - B A C K U P   COMPLETE ------------${NC}"
}
# create DRSTORE_BACKUP if not exist ,name : day_month_year
# creat LOG file if not Found ,log name : vpn_connection.log
function write_on_log_file () {
    ######################################
    TMP_FILE_NAME=$1
    TMP_TEXT_LINE=$2

    echo $TMP_TEXT_LINE >> $TMP_FILE_NAME
    ######################################
    ######################################
    ######################################
}
function create_backup_folder () {
    mkdir -p ${DRSTORES_BACKUP_FOLDER_LOCAL_PATH}
    touch ${DRSTORES_BACKUP_FOLDER_LOCAL_PATH}${LOG_VPN_CONNECTION_FILE_NAME}
}
# create DRSTORE_ARCHIVE_FOLDER if not exist ,name : day_month_year
# creat LOG file if not exist ,log name : day_month_year_dr_backup.log
function create_archive_folder () {
    #statements
    mkdir -p ${DRSTORES_BACKUP_FOLDER_LOCAL_PATH}${DRSTORE_ARCHIVE_FOLDER}
    rm -r ${DRSTORES_BACKUP_FOLDER_LOCAL_PATH}${DRSTORE_ARCHIVE_FOLDER}${BACKUP_LOG_FILE_NAME}
    touch ${DRSTORES_BACKUP_FOLDER_LOCAL_PATH}${DRSTORE_ARCHIVE_FOLDER}${BACKUP_LOG_FILE_NAME}
    write_on_log_file ${DRSTORES_BACKUP_FOLDER_LOCAL_PATH}${DRSTORE_ARCHIVE_FOLDER}${BACKUP_LOG_FILE_NAME} "____________________________________________________________________________________________________"
    write_on_log_file ${DRSTORES_BACKUP_FOLDER_LOCAL_PATH}${DRSTORE_ARCHIVE_FOLDER}${BACKUP_LOG_FILE_NAME} "-----------------  D A T A - R E C E I V E R - $DATE - A R C H I V E  B A C K U P  -----------------"
    write_on_log_file ${DRSTORES_BACKUP_FOLDER_LOCAL_PATH}${DRSTORE_ARCHIVE_FOLDER}${BACKUP_LOG_FILE_NAME} "----------------------------------------------------------------------------------------------------"
}
# verify internet & VPN server connection 
function verify_vpn_server_connection () {
    ping -q -c10 $ATI_DNS > /dev/null 
    ATI_DNS_PING_RESULT=$? 
    ping -q -c10 $IP_VPN_SERVER > /dev/null
    IP_VPN_SERVER_PING_RESULT=$? 
    if [[ $ATI_DNS_PING_RESULT -eq 0 ]] && [[ $IP_VPN_SERVER_PING_RESULT -eq 0 ]]; then
        #statements
        create_backup_folder
        create_archive_folder
        write_on_log_file ${DRSTORES_BACKUP_FOLDER_LOCAL_PATH}${LOG_VPN_CONNECTION_FILE_NAME} "-----------------------|---------------------------------------------------------------------------------"
        write_on_log_file ${DRSTORES_BACKUP_FOLDER_LOCAL_PATH}${LOG_VPN_CONNECTION_FILE_NAME} "$(date '+%d-%b-%Y|%I:%M:%S') | VPN SERVER CONNECTION OK : INTERNET OK - Start Process"
        echo -e "${ON_GREEN}-------------------------------VPN SERVER CONNECTION OK : INTERNET OK-------------------------------${NC}"
        echo -e "${ON_GREEN}------------------------ S T A R T - P R O C E S S - ${DATE_TIME} ------------------------${NC}"
    elif [[ ! $ATI_DNS_PING_RESULT -eq 0 ]] && [[ ! $IP_VPN_SERVER_PING_RESULT -eq 0 ]]; then
        create_backup_folder
        write_on_log_file ${DRSTORES_BACKUP_FOLDER_LOCAL_PATH}${LOG_VPN_CONNECTION_FILE_NAME} "-----------------------|---------------------------------------------------------------------------------"
        write_on_log_file ${DRSTORES_BACKUP_FOLDER_LOCAL_PATH}${LOG_VPN_CONNECTION_FILE_NAME} "$(date '+%d-%b-%Y|%I:%M:%S') | NO VPN SERVER CONNECTION : NO INTERNET - VPN server not connected - Halt process"
        echo -e "${ON_RED}---------------------------  NO VPN SERVER CONNECTION : NO INTERNET  -------------------------------${NC}"
        echo -e "${ON_RED}------------------------ S T O P - P R O C E S S - ${DATE_TIME} --------------------------${NC}"
        exit 0;
    elif [[ ! $ATI_DNS_PING_RESULT -eq 0 ]] && [[ $IP_VPN_SERVER_PING_RESULT -eq 0 ]]; then
        create_backup_folder
        write_on_log_file ${DRSTORES_BACKUP_FOLDER_LOCAL_PATH}${LOG_VPN_CONNECTION_FILE_NAME} "-----------------------|---------------------------------------------------------------------------------"
        write_on_log_file ${DRSTORES_BACKUP_FOLDER_LOCAL_PATH}${LOG_VPN_CONNECTION_FILE_NAME} "$(date '+%d-%b-%Y|%I:%M:%S') | VPN SERVER CONNECTION OK : NO INTERNET - VPN server not connected - Halt process"
        echo -e "${ON_RED}----------------------------  VPN SERVER CONNECTION OK : NO INTERNET  ------------------------------${NC}"
        echo -e "${ON_RED}------------------------ S T O P - P R O C E S S - ${DATE_TIME} --------------------------${NC}"
        exit 0;
    elif [[ $ATI_DNS_PING_RESULT -eq 0 ]] && [[ ! $IP_VPN_SERVER_PING_RESULT -eq 0 ]]; then
        create_backup_folder
        write_on_log_file ${DRSTORES_BACKUP_FOLDER_LOCAL_PATH}${LOG_VPN_CONNECTION_FILE_NAME} "-----------------------|---------------------------------------------------------------------------------"
        write_on_log_file ${DRSTORES_BACKUP_FOLDER_LOCAL_PATH}${LOG_VPN_CONNECTION_FILE_NAME} "$(date '+%d-%b-%Y|%I:%M:%S') | NO VPN SERVER CONNECTION : INTERNET OK - VPN server not connected - Halt process"
        echo -e "${ON_RED}-----------------------------  NO VPN SERVER CONNECTION : INTERNET OK ------------------------------${NC}"
        echo -e "${ON_RED}------------------------- S T O P - P R O C E S S - ${DATE_TIME} -------------------------${NC}"
        exit 0;
    fi;
}
function main_backup () {
    while [[ $K<=3 ]]; do
        #statements
        for I in "${!ARRAY_VPN[@]}"
        do
            ping -q -c5 ${ARRAY_VPN[$I]} > /dev/null
            if [ $? -eq 0 ]; then
                # transfer the drstore from the DataReceiver to their dr_code_folder in local_path
                if ssh root@${ARRAY_VPN[$I]} stat $DRSTORE_FOLDER_REMOTE_PATH \> /dev/null 2\>\&1;  then
                    echo ""
                    echo -e "${ON_GREEN}-- S T A R T ${BLACK}${ON_WHITE}${ARRAY_DRCODE[$I]} - ${ARRAY_VPN[$I]}${NC}${ON_GREEN} - $(date '+%d-%b-%Y|%I:%M:%S') --------------------- CONNECTED  O.K${NC}"
                    write_on_log_file ${DRSTORES_BACKUP_FOLDER_LOCAL_PATH}${DRSTORE_ARCHIVE_FOLDER}${BACKUP_LOG_FILE_NAME} "----------------------------------------------------------------------------------------------------"
                    write_on_log_file ${DRSTORES_BACKUP_FOLDER_LOCAL_PATH}${DRSTORE_ARCHIVE_FOLDER}${BACKUP_LOG_FILE_NAME} "$(date '+%d-%b-%Y|%I:%M:%S') - ${ARRAY_DRCODE[$I]} - connected O.K"
                    # compress drstore folder in DRCODE.tar.gz at remote path
                    ssh root@${ARRAY_VPN[$I]} "cd ${DRSTORE_FOLDER_REMOTE_PATH} && tar -czf ${ARRAY_DRCODE[$I]}${TAR_GZ_EXTENSION} ${CONF_FOLDER_NAME} ${DATA_FOLDER_NAME}${CONF_INI_FILE}"
                    # verify if the DRCODE.tar.gz exist
                    if ssh root@${ARRAY_VPN[$I]} stat $DRSTORE_FOLDER_REMOTE_PATH${ARRAY_DRCODE[$I]}${TAR_GZ_EXTENSION} \> /dev/null 2\>\&1;  then
                        sleep 1
                        echo -ne "${ON_GREEN}-- Compress o.k-- ${ARRAY_DRCODE[$I]}${TAR_GZ_EXTENSION} $(date '+%I:%M:%S')${BLUE}${ON_GREEN} =========================>                       (50%)\r${NC}"
                        # download the DRCODE.tar.gz from remote datareviver 
                        scp -qr root@${ARRAY_VPN[$I]}:${DRSTORE_FOLDER_REMOTE_PATH}${ARRAY_DRCODE[$I]}${TAR_GZ_EXTENSION} ${DRSTORE_FULL_LOCAL_PATH}
                        sleep 1
                        echo -ne "${ON_GREEN}-- Download o.k-- ${ARRAY_DRCODE[$I]}${TAR_GZ_EXTENSION} $(date '+%I:%M:%S')${YELLOW}${ON_GREEN} ========================================>        (80%)\r${NC}"
                        #####################################
                        #####################################
                        #####################################
                        # compare the 2 file cheksum
                        # verify local checksum DRCODE.tar.gz file
                        #read cksum ${DRSTORE_FULL_LOCAL_PATH}${ARRAY_DRCODE[$I]}${TAR_GZ_EXTENSION}
                        # verify remote cheksum DRCODE.tar.gz file
                        #ssh root@${ARRAY_VPN[$I]} cksum  ${DRSTORE_FOLDER_REMOTE_PATH}${ARRAY_DRCODE[$I]}${TAR_GZ_EXTENSION}
                        #read remote_check
                        #####################################
                        #####################################
                        #####################################
                        sleep 1
                        echo -ne "${ON_GREEN}-- Checksum o.k-- ${ARRAY_DRCODE[$I]}${TAR_GZ_EXTENSION} $(date '+%I:%M:%S')${WHITE}${ON_GREEN} ===============================================> (98%)\r${NC}"
                        write_on_log_file ${DRSTORES_BACKUP_FOLDER_LOCAL_PATH}${DRSTORE_ARCHIVE_FOLDER}${BACKUP_LOG_FILE_NAME} "$(date '+%d-%b-%Y|%I:%M:%S') - ${ARRAY_DRCODE[$I]}${TAR_GZ_EXTENSION} - transfered O.K"
                        ##
                        ##
                        sleep 1
                        echo -ne "${ON_GREEN}-- FINISH -- ${ARRAY_DRCODE[$I]}${TAR_GZ_EXTENSION} $(date '+%I:%M:%S') ====================================================>${NC}${BLACK}${ON_GREEN}(100%)\r${NC}"
                        echo -ne "\n"
                        write_on_log_file ${DRSTORES_BACKUP_FOLDER_LOCAL_PATH}${DRSTORE_ARCHIVE_FOLDER}${BACKUP_LOG_FILE_NAME} "$(date '+%d-%b-%Y|%I:%M:%S') - ${ARRAY_DRCODE[$I]}${TAR_GZ_EXTENSION} - backup O.K"
                    # every data receiver connected will eliminate from the backup list array
                    unset ARRAY_VPN[$I]
                    unset ARRAY_DRCODE[$I]
                    else
                        echo -e "${ON_RED}---- F I N I S H -- $(date '+%d-%b-%Y|%I:%M:%S')  ${NC}${BLACK}----------- ${NC}${ON_RED} ---------------- Corrupted File ------------${NC}" 
                        write_on_log_file ${DRSTORES_BACKUP_FOLDER_LOCAL_PATH}${DRSTORE_ARCHIVE_FOLDER}${BACKUP_LOG_FILE_NAME} "$(date '+%d-%b-%Y|%I:%M:%S') - ${ARRAY_DRCODE[$I]}${TAR_GZ_EXTENSION} - Download error"
                        write_on_log_file ${DRSTORES_BACKUP_FOLDER_LOCAL_PATH}${DRSTORE_ARCHIVE_FOLDER}${BACKUP_LOG_FILE_NAME} "$(date '+%d-%b-%Y|%I:%M:%S') - ${ARRAY_DRCODE[$I]}${TAR_GZ_EXTENSION} - ${ARRAY_VPN[$I]} - error backup"
                    fi;
                else
                    echo ""
                    echo -e "${ON_RED} STOP : $(date '+%d-%b-%Y|%I:%M:%S') - ${ARRAY_DRCODE[$I]} - ${ARRAY_VPN[$I]} - CONNECTED - DRSTORE NOT FOUND${NC}"
                    write_on_log_file ${DRSTORES_BACKUP_FOLDER_LOCAL_PATH}${DRSTORE_ARCHIVE_FOLDER}${BACKUP_LOG_FILE_NAME} "----------------------------------------------------------------------------------------------------"
                    write_on_log_file ${DRSTORES_BACKUP_FOLDER_LOCAL_PATH}${DRSTORE_ARCHIVE_FOLDER}${BACKUP_LOG_FILE_NAME} "$(date '+%d-%b-%Y|%I:%M:%S') - ${ARRAY_DRCODE[$I]}${TAR_GZ_EXTENSION} --  Connected -- Drstore not Found"
                    # every data receiver connected will eliminate from the backup list array
                    unset ARRAY_VPN[$I]
                    unset ARRAY_DRCODE[$I]
                fi;
            else
                write_on_log_file ${DRSTORES_BACKUP_FOLDER_LOCAL_PATH}${DRSTORE_ARCHIVE_FOLDER}${BACKUP_LOG_FILE_NAME} "----------------------------------------------------------------------------------------------------"
                write_on_log_file ${DRSTORES_BACKUP_FOLDER_LOCAL_PATH}${DRSTORE_ARCHIVE_FOLDER}${BACKUP_LOG_FILE_NAME} "$(date '+%d-%b-%Y|%I:%M:%S') - ${ARRAY_DRCODE[$I]} - ${ARRAY_VPN[$I]} ---- Not Connected"
                echo ""
                echo -e "${ON_RED} STOP : $(date '+%d-%b-%Y|%I:%M:%S') - ${ARRAY_DRCODE[$I]} - ${ARRAY_VPN[$I]} - N O T  C O N N E C T E D${NC}"
            fi;
        done;
        # sleep 1 minute and start over backup iteration for disconnected datareceiver
        sleep 60
        if [[ $k==3 ]]; then
            #statements
            end_screen
            exit 0
        fi
        let "K +=1"
    done;
}
######################
### main script part
######################
start_screen
verify_vpn_server_connection
main_backup

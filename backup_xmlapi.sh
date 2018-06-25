#!/bin/bash

##########################################################################################################
#                                                                                                        #
#  Author        :  Raman Deep                                                                           #
#  Email         :  raman@sky-tours.com                                                                  #
#  Date          :  22 June 2018                                                                         #
#  Description   :  Script to backup xmlapi servers                                                      #
#  Version       :  1.0                                                                                  #
#                                                                                                        #
##########################################################################################################


HOSTNAME=$(hostname)
DATE=$(/bin/date "+%Y-%m-%d")
TIMESTAMP=$(/bin/date "+%Y-%m-%d %H:%M:%S")
BACKUP_PATH="/var/backup/"
OUT_FILE="/var/${HOSTNAME}_bkp_${DATE}.zip"
LOG_FILE="/tmp/${DATE}_${HOSTNAME}_BKP.log"

# Directories to backup
DIRS_TO_BACKUP="/etc /root/scripts /opt/scripts /var/log /var/www/vhosts"

# DO NOT CHANGE ANYTHING BELOW

#------------------------------------------#
#-----------        ~~~~        -----------#
#-----------  HERE BE DRAGONS   -----------#
#-----------        ~~~~        -----------#
#------------------------------------------#

check_backup_path() {
	if [[ -d "$BACKUP_PATH" ]]; then
		echo "OK : $BACKUP_PATH exists." >> "$LOG_FILE"
	else
		echo "KO : $BACKUP_PATH doesn't exists. Creating it..." >> "$LOG_FILE"
		mkdir "$BACKUP_PATH" >> "$LOG_FILE" 2>&1
	fi
}

get_packages_version() {
	PACKAGES_FILE="${BACKUP_PATH}installed_packages.txt"
	dpkg-query --show -f '${source:Package} ${source:Version}\n' | sort -u > "$PACKAGES_FILE"
}

get_apache_modules() {
	APACHE_MODULES_FILE="${BACKUP_PATH}apache_modules.txt"
	apache2ctl -M > "$APACHE_MODULES_FILE"
}

get_php_modules(){
	PHP_MODULES_FILE="${BACKUP_PATH}php_modules.txt"
	php -m > "$PHP_MODULES_FILE"
}

compress_dirs_to_backup() {
	for DIR in $DIRS_TO_BACKUP; do
		#echo "$DIR" >> $LOG_FILE
		DIR_NAME=$(echo "$DIR" | sed 's/^\///g' | sed 's/\//_/g')
		#echo "$DIR_NAME"
		echo "Compressing : $DIR to : $BACKUP_PATH$DIR_NAME.tar.gz" >> "$LOG_FILE"
		DIR_TAR=$(/bin/tar -zcvf "$BACKUP_PATH$DIR_NAME".tar.gz "$DIR" >> "$LOG_FILE" 2>&1)
		echo "" >> "$LOG_FILE"
		echo "Dir compressed successfully." >> "$LOG_FILE"
		echo "" >> "$LOG_FILE"
	done
}

mysql_backup() {
	echo "MYSQL BACKUP" >> "$LOG_FILE"
	DATABASES=$(mysql -e "SHOW DATABASES;" | tr -d "| " | grep -v Database)
	if [[ ! -z "$DATABASES" ]]; then
		MYSQL_DIR="${BACKUP_PATH}mysql"
		mkdir $MYSQL_DIR
		for DB in $DATABASES; do
			if [[ "$DB" != "information_schema" ]] && [[ "$DB" != "performance_schema" ]] && [[ "$DB" != "sys" ]] && [[ "$DB" != _* ]] ; then
				echo "Dumping database : $DB" >> "$LOG_FILE" 
				mysqldump "$DB" --skip-lock-tables > "${MYSQL_DIR}/${DB}_${HOSTNAME}_${DATE}.sql"
			fi
		done
		echo "Creating mysql tar file ${BACKUP_PATH}mysql.tar.gz" >> "$LOG_FILE"
		MYSQL_TAR=$(/bin/tar -zcvf "${BACKUP_PATH}mysql.tar.gz" "${MYSQL_DIR}" >> "$LOG_FILE" 2>&1)
		echo "Deleting $MYSQL_DIR temprary directory" >> "$LOG_FILE"
		/bin/rm -rf "$MYSQL_DIR" >> "$LOG_FILE" 2>&1
	else
		echo "No databases found for backup" >> "$LOG_FILE"
	fi
}

echo "            BACKUP SCRIPT                       " >> "$LOG_FILE"
echo "------------------------------------------------" >> "$LOG_FILE"
echo  "" >> "$LOG_FILE"
echo "$TIMESTAMP - Starting backup $HOSTNAME" >> "$LOG_FILE"
echo "Checking if $BACKUP_PATH exists" >> "$LOG_FILE"

# Check if backups destination directory exists, if not the script will create it.
check_backup_path

# Get installed packages version
get_packages_version

# Get enabled apache modules
get_apache_modules

# Get enabled php modules
get_php_modules

# Compress directories given in DIRS_TO_BACKUP 
compress_dirs_to_backup

# Create mysql databases backup
mysql_backup

echo "Compressing $BACKUP_PATH to create unique compressed file." >> "$LOG_FILE"

ZIP_FOLDER=$(/usr/bin/zip -r "$OUT_FILE" "$BACKUP_PATH" >> "$LOG_FILE" 2>&1)

echo "" >> "$LOG_FILE"

TIMESTAMP=$(/bin/date "+%Y-%m-%d %H:%M:%S")

echo "$TIMESTAMP - Script END." >> "$LOG_FILE"
echo "================================================" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

/usr/bin/zip "${OUT_FILE}" "${LOG_FILE}"

exit 0
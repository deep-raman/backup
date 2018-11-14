#!/bin/bash
HOSTNAME=$(hostname)
DATE=$(/bin/date "+%Y-%m-%d")
DATABASES="ibe_cache ibe_flight1"
REMOTE_HOST="tools03"
for DB in $DATABASES; do
	#statements
	DUMP_FILE="/tmp/${DB}_${HOSTNAME}_${DATE}.sql"
	echo "Creating mysqldump of database : $DB"
	mysqldump "$DB" --skip-lock-tables > "$DUMP_FILE"
	echo "Mysqldump of : $DB created."
	echo "Copyting dump to $REMOTE_HOST"
	scp "${DUMP_FILE}" "${REMOTE_HOST}":/tmp/
	echo "Restoring backup to the database."
	ssh root@"${REMOTE_HOST}" "mysql ${DB} < $DUMP_FILE" 
done
exit 0
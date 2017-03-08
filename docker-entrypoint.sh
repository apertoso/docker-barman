#!/bin/bash
set -e

BARMAN_CONF="/etc/barman.conf"
TEMP_CONF="/tmp/barman.conf"

add_property() {
	echo $(echo "$1" | awk '{print tolower($0)}')'='${!1}
}

generate_configuration() {
	mkdir -p "BARMAN_LOG_FILE"
	> "$TEMP_CONF"
	echo "[barman]" >> "$TEMP_CONF"
	compgen -e | grep -e "^BARMAN_" | while read -r line ; do 
		add_property "$line" >> "$TEMP_CONF"
	done
	sed -e 's/^barman_//g' "$TEMP_CONF" > "$BARMAN_CONF"
}

generate_cron () {
	cron
	gosu barman bash -c "echo '* * * * * barman cron' | crontab -"	
}

ensure_permissions() {
	touch $BARMAN_LOG_FILE
	for path in \
		/etc/barman.conf \
		"$BARMAN_BARMAN_HOME" \
		"$BARMAN_CONFIGURATION_FILES_DIRECTORY" \
		"$BARMAN_LOG_FILE" \
	; do
		chown -R barman:barman "$path"
	done	
}

if [ "$1" = 'barman' ]; then
	generate_configuration
	generate_cron	
	ensure_permissions
	exec gosu barman bash -c 'tail -f "$BARMAN_LOG_FILE" 2>&1'
fi

exec "$@"
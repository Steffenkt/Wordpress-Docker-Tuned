#!/usr/bin/env bash
set -Eeuo pipefail

# Funktion für Operationen, die Root-Rechte benötigen
run_as_root() {
	if [ "$(id -u)" != "0" ]; then
		exec gosu root "$@"
	else
		exec "$@"
	fi
}

# Funktion für Operationen, die als www-data ausgeführt werden sollten
run_as_www_data() {
	if [ "$(id -u)" = "0" ]; then
		exec gosu www-data "$@"
	else
		exec "$@"
	fi
}

if [[ "$1" == apache2* ]] || [ "$1" = 'php-fpm' ]; then
	uid="$(id -u)"
	gid="$(id -g)"
	
	# Setze Variablen für User und Group basierend auf dem Umgebungsmodus
	if [ "$uid" = '0' ]; then
		case "$1" in
			apache2*)
				user="${APACHE_RUN_USER:-www-data}"
				group="${APACHE_RUN_GROUP:-www-data}"

				# strip off any '#' symbol ('#1000' is valid syntax for Apache)
				pound='#'
				user="${user#$pound}"
				group="${group#$pound}"
				;;
			*) # php-fpm
				user='www-data'
				group='www-data'
				;;
		esac
	else
		user="$uid"
		group="$gid"
	fi

	if [ ! -e index.php ] && [ ! -e wp-includes/version.php ]; then
		# WordPress-Dateien kopieren und Berechtigungen setzen
		echo >&2 "WordPress not found in $PWD - copying now..."
		if [ -n "$(find -mindepth 1 -maxdepth 1 -not -name wp-content)" ]; then
			echo >&2 "WARNING: $PWD is not empty! (copying anyhow)"
		fi
		
		# Bei Bedarf Root-Berechtigungen für Dateikopier-Operationen verwenden
		if [ "$uid" != '0' ]; then
			run_as_root cp -a /usr/src/wordpress/. .
			run_as_root chown -R "$user:$group" .
		else
			cp -a /usr/src/wordpress/. .
			chown -R "$user:$group" .
		fi
		
		echo >&2 "Complete! WordPress has been successfully copied to $PWD"
	fi

	wpEnvs=( "${!WORDPRESS_@}" )
	if [ ! -s wp-config.php ] && [ "${#wpEnvs[@]}" -gt 0 ]; then
		for wpConfigDocker in \
			wp-config-docker.php \
			/usr/src/wordpress/wp-config-docker.php \
		; do
			if [ -s "$wpConfigDocker" ]; then
				echo >&2 "No 'wp-config.php' found in $PWD, but 'WORDPRESS_...' variables supplied; copying '$wpConfigDocker' (${wpEnvs[*]})"
				# Generiere wp-config.php mit zufälligen Schlüsseln
				awk '
					/put your unique phrase here/ {
						cmd = "head -c1m /dev/urandom | sha1sum | cut -d\\  -f1"
						cmd | getline str
						close(cmd)
						gsub("put your unique phrase here", str)
					}
					{ print }
				' "$wpConfigDocker" > wp-config.php
				
				# Setze korrekte Berechtigungen
				if [ "$uid" = '0' ]; then
					chown "$user:$group" wp-config.php || true
				elif [ "$uid" != '0' ]; then
					run_as_root chown "$user:$group" wp-config.php || true
				fi
				break
			fi
		done
	fi
fi

# Starte Apache oder PHP-FPM als richtiger Benutzer
if [[ "$1" == apache2* ]]; then
	if [ "$(id -u)" = '0' ]; then
		# Apache muss als Root starten, aber dann auf www-data wechseln
		exec "$@"
	else
		# Wenn wir bereits als www-data laufen, starte Apache mit gosu root
		# Apache wird dann intern auf www-data wechseln
		run_as_root "$@"
	fi
else
	# Andere Befehle (z.B. php-fpm) können direkt ausgeführt werden
	exec "$@"
fi
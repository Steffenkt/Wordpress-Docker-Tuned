#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "apply-templates.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

FROM php:8.3-apache-bullseye

# persistent dependencies
RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
# Ghostscript is required for rendering PDF previews
		ghostscript \
		gosu \
	; \
	rm -rf /var/lib/apt/lists/*

# Set up non-root user explicitly
RUN set -eux; \
	# Stelle sicher, dass die User-ID von www-data bekannt ist
	usermod --shell /bin/bash www-data; \
	# Erstelle Verzeichnisse, die der non-root User benötigt
	mkdir -p /var/www/.config; \
	chown -R www-data:www-data /var/www/

# install the PHP extensions we need (https://make.wordpress.org/hosting/handbook/handbook/server-environment/#php-extensions)
RUN set -ex; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	\
	apt-get update; \
	apt-get install -y --no-install-recommends \
		libavif-dev \
		libfreetype6-dev \
		libicu-dev \
		libjpeg-dev \
		libmagickwand-dev \
		libpng-dev \
		libwebp-dev \
		libzip-dev \
		libldap2-dev \
	; \
	\
	docker-php-ext-configure gd \
		--with-avif \
		--with-freetype \
		--with-jpeg \
		--with-webp \
	; \
	docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/; \
	docker-php-ext-install -j "$(nproc)" \
		bcmath \
		exif \
		gd \
		intl \
		mysqli \
		zip \
		ldap \
		ftp \
	; \
# https://pecl.php.net/package/imagick
	pecl install imagick-3.8.0; \
	docker-php-ext-enable imagick; \
	rm -r /tmp/pear; \
	\
# some misbehaving extensions end up outputting to stdout 🙈 (https://github.com/docker-library/wordpress/issues/669#issuecomment-993945967)
	out="$(php -r 'exit(0);')"; \
	[ -z "$out" ]; \
	err="$(php -r 'exit(0);' 3>&1 1>&2 2>&3)"; \
	[ -z "$err" ]; \
	\
	extDir="$(php -r 'echo ini_get("extension_dir");')"; \
	[ -d "$extDir" ]; \
# reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
	apt-mark auto '.*' > /dev/null; \
	apt-mark manual $savedAptMark; \
	ldd "$extDir"/*.so \
		| awk '/=>/ { so = $(NF-1); if (index(so, "/usr/local/") == 1) { next }; gsub("^/(usr/)?", "", so); printf "*%s\n", so }' \
		| sort -u \
		| xargs -r dpkg-query --search \
		| cut -d: -f1 \
		| sort -u \
		| xargs -rt apt-mark manual; \
	\
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	rm -rf /var/lib/apt/lists/*; \
	\
	! { ldd "$extDir"/*.so | grep 'not found'; }; \
# check for output like "PHP Warning:  PHP Startup: Unable to load dynamic library 'foo' (tried: ...)
	err="$(php --version 3>&1 1>&2 2>&3)"; \
	[ -z "$err" ]

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN set -eux; \
	docker-php-ext-enable opcache; \
	{ \
		echo 'opcache.memory_consumption=256'; \
		echo 'opcache.interned_strings_buffer=16'; \
		echo 'opcache.max_accelerated_files=10000'; \
		echo 'opcache.revalidate_freq=0'; \
		echo 'opcache.validate_timestamps=1'; \
		echo 'opcache.save_comments=1'; \
		echo 'opcache.enable_file_override=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini
# https://wordpress.org/support/article/editing-wp-config-php/#configure-error-logging
RUN { \
# https://www.php.net/manual/en/errorfunc.constants.php
# https://github.com/docker-library/wordpress/issues/420#issuecomment-517839670
		echo 'error_reporting = E_ERROR | E_WARNING | E_PARSE | E_CORE_ERROR | E_CORE_WARNING | E_COMPILE_ERROR | E_COMPILE_WARNING | E_RECOVERABLE_ERROR'; \
		echo 'display_errors = Off'; \
		echo 'display_startup_errors = Off'; \
		echo 'log_errors = On'; \
		echo 'error_log = /dev/stderr'; \
		echo 'log_errors_max_len = 1024'; \
		echo 'ignore_repeated_errors = On'; \
		echo 'ignore_repeated_source = Off'; \
		echo 'html_errors = Off'; \
	} > /usr/local/etc/php/conf.d/error-logging.ini

# set WordPress PHP limits
RUN { \
		echo 'memory_limit = 512M'; \
		echo 'upload_max_filesize = 512M'; \
		echo 'post_max_size = 512M'; \
		echo 'max_input_vars = 5000'; \
		echo 'max_execution_time = 3660'; \
		echo 'max_input_time = 3660'; \
	} > /usr/local/etc/php/conf.d/wordpress-limits.ini

# additional PHP settings
RUN { \
		echo '; Enable output buffering für bessere Performance'; \
		echo 'output_buffering = On'; \
		echo 'output_handler = mb_output_handler'; \
		echo ''; \
		echo '; Maximale Ausführungstiefe - verhindert endlose Rekursionen'; \
		echo 'max_execution_depth = 1000'; \
		echo ''; \
		echo '; Explizit PHP-Sitzungskonfiguration'; \
		echo 'session.save_handler = files'; \
		echo 'session.use_strict_mode = 1'; \
		echo 'session.use_cookies = 1'; \
		echo 'session.use_only_cookies = 1'; \
		echo 'session.cookie_secure = 1'; \
		echo 'session.cookie_httponly = 1'; \
		echo 'session.cookie_samesite = "Lax"'; \
		echo 'session.gc_maxlifetime = 3600'; \
		echo ''; \
		echo '; LDAP-Spezifische Einstellungen'; \
		echo 'ldap.max_links = -1'; \
	} > /usr/local/etc/php/conf.d/wordpress-additional.ini

RUN set -eux; \
	a2enmod rewrite expires; \
	\
# https://httpd.apache.org/docs/2.4/mod/mod_remoteip.html
	a2enmod remoteip; \
	{ \
		echo 'RemoteIPHeader X-Forwarded-For'; \
# these IP ranges are reserved for "private" use and should thus *usually* be safe inside Docker
		echo 'RemoteIPInternalProxy 10.0.0.0/8'; \
		echo 'RemoteIPInternalProxy 172.16.0.0/12'; \
		echo 'RemoteIPInternalProxy 192.168.0.0/16'; \
		echo 'RemoteIPInternalProxy 169.254.0.0/16'; \
		echo 'RemoteIPInternalProxy 127.0.0.0/8'; \
	} > /etc/apache2/conf-available/remoteip.conf; \
	a2enconf remoteip; \
# https://github.com/docker-library/wordpress/issues/383#issuecomment-507886512
# (replace all instances of "%h" with "%a" in LogFormat)
	find /etc/apache2 -type f -name '*.conf' -exec sed -ri 's/([[:space:]]*LogFormat[[:space:]]+"[^"]*)%h([^"]*")/\1%a\2/g' '{}' +

# Performance Optimierungen für Apache
RUN { \
    echo '<IfModule mod_deflate.c>'; \
    echo '    # Komprimiere HTML, CSS, JavaScript, Text, XML und fonts'; \
    echo '    AddOutputFilterByType DEFLATE application/javascript'; \
    echo '    AddOutputFilterByType DEFLATE application/rss+xml'; \
    echo '    AddOutputFilterByType DEFLATE application/vnd.ms-fontobject'; \
    echo '    AddOutputFilterByType DEFLATE application/x-font'; \
    echo '    AddOutputFilterByType DEFLATE application/x-font-opentype'; \
    echo '    AddOutputFilterByType DEFLATE application/x-font-otf'; \
    echo '    AddOutputFilterByType DEFLATE application/x-font-truetype'; \
    echo '    AddOutputFilterByType DEFLATE application/x-font-ttf'; \
    echo '    AddOutputFilterByType DEFLATE application/x-javascript'; \
    echo '    AddOutputFilterByType DEFLATE application/xhtml+xml'; \
    echo '    AddOutputFilterByType DEFLATE application/xml'; \
    echo '    AddOutputFilterByType DEFLATE font/opentype'; \
    echo '    AddOutputFilterByType DEFLATE font/otf'; \
    echo '    AddOutputFilterByType DEFLATE font/ttf'; \
    echo '    AddOutputFilterByType DEFLATE image/svg+xml'; \
    echo '    AddOutputFilterByType DEFLATE image/x-icon'; \
    echo '    AddOutputFilterByType DEFLATE text/css'; \
    echo '    AddOutputFilterByType DEFLATE text/html'; \
    echo '    AddOutputFilterByType DEFLATE text/javascript'; \
    echo '    AddOutputFilterByType DEFLATE text/plain'; \
    echo '    AddOutputFilterByType DEFLATE text/xml'; \
    echo '</IfModule>'; \
} > /etc/apache2/conf-available/compression.conf; \
a2enconf compression; \
a2enmod headers deflate expires

RUN set -eux; \
    version='6.8'; \
    \
    curl -o wordpress.tar.gz -fL "https://wordpress.org/wordpress-$version.tar.gz"; \
    \
# upstream tarballs include ./wordpress/ so this gives us /usr/src/wordpress
    tar -xzf wordpress.tar.gz -C /usr/src/; \
    rm wordpress.tar.gz; \
    \
# https://wordpress.org/support/article/htaccess/
    [ ! -e /usr/src/wordpress/.htaccess ]; \
    { \
        echo '# BEGIN WordPress'; \
        echo ''; \
        echo 'RewriteEngine On'; \
        echo 'RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]'; \
        echo 'RewriteBase /'; \
        echo 'RewriteRule ^index\.php$ - [L]'; \
        echo 'RewriteCond %{REQUEST_FILENAME} !-f'; \
        echo 'RewriteCond %{REQUEST_FILENAME} !-d'; \
        echo 'RewriteRule . /index.php [L]'; \
        echo ''; \
        echo '# END WordPress'; \
    } > /usr/src/wordpress/.htaccess; \
    \
    chown -R www-data:www-data /usr/src/wordpress; \
# pre-create wp-content (and single-level children) for folks who want to bind-mount themes, etc so permissions are pre-created properly instead of root:root
# wp-content/cache: https://github.com/docker-library/wordpress/issues/534#issuecomment-705733507
    mkdir wp-content; \
    for dir in /usr/src/wordpress/wp-content/*/ cache; do \
        dir="$(basename "${dir%/}")"; \
        mkdir "wp-content/$dir"; \
    done; \
    chown -R www-data:www-data wp-content; \
    chmod -R 1777 wp-content

VOLUME /var/www/html

COPY --chown=www-data:www-data wp-config-docker.php /usr/src/wordpress/
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Die USER www-data Zeile wird entfernt, damit der Container als root startet
# und docker-entrypoint.sh die Benutzerrechte verwalten kann

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
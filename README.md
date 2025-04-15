# WordPress Docker Tuned

A Docker-based WordPress setup with Apache and PHP 8.3, featuring enhanced performance and security configurations.

## Overview

This project provides a customized WordPress Docker environment with:

- PHP 8.3 with Apache
- Additional PHP extensions (LDAP, FTP) pre-installed
- Performance-optimized PHP configuration
- Security-enhanced settings
- Latest WordPress version (6.7.2)

## Features

### Pre-installed PHP Extensions

- Standard WordPress required extensions
- **LDAP**: For directory service integration
- **FTP**: For file transfer protocol support
- **ImageMagick**: For advanced image processing

### PHP Configuration Enhancements

- **Memory Limits**: Increased to 512M
- **Upload Limits**: Increased to 512M
- **Performance Tweaks**:
  - Optimized opcache settings
  - Output buffering enabled
  - Increased max input vars (5000)
  - Extended execution time limits (3660s)

### Security Settings

- Configured error logging
- Secure session handling
- HTTP-only cookies
- SameSite cookie policy

## Usage

### Starting the Container

```bash
docker-compose up -d
```

### Environment Variables

The container uses standard WordPress environment variables:

- `WORDPRESS_DB_HOST`: Database hostname (default: 'mysql')
- `WORDPRESS_DB_USER`: Database username
- `WORDPRESS_DB_PASSWORD`: Database password
- `WORDPRESS_DB_NAME`: Database name (default: 'wordpress')
- `WORDPRESS_TABLE_PREFIX`: Table prefix (default: 'wp_')
- `WORDPRESS_DEBUG`: Enable debug mode

### Volumes

- `/var/www/html`: WordPress files

## Project Structure

```
latest/
  └── php8.3/
      └── apache/
          ├── docker-entrypoint.sh  # Container initialization script
          ├── Dockerfile            # Container build definition
          └── wp-config-docker.php  # WordPress configuration template
```

## Inspiration

This project is based on the official WordPress Docker image with custom enhancements:
- https://github.com/docker-library/wordpress

## License

This project is distributed under the same license as WordPress.
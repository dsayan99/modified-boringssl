# I found this script was found at: https://tinyurl.com/tr7de9km

#!/bin/bash

LATESTNGINX="1.25.1"
BUILDROOT="/home/sayan"

# Pre-req
sudo apt-get update && sudo apt-get upgrade -y

# Install deps
sudo apt-get install build-essential cmake curl git gnupg golang libpcre3-dev libcurl4-openssl-dev zlib1g-dev -y

# make build root dir
sudo mkdir -p $BUILDROOT
cd $BUILDROOT

# Build BoringSSL
#git clone https://boringssl.googlesource.com/boringssl
#cd boringssl
#mkdir build
#cd $BUILDROOT/boringssl/build
#cmake ..
#make

# Make an .openssl directory for nginx and then symlink BoringSSL's include directory tree
mkdir -p "$BUILDROOT/boringssl/.openssl/lib"
cd "$BUILDROOT/boringssl/.openssl"
ln -s ../include include

# Copy the BoringSSL crypto libraries to .openssl/lib so nginx can find them
cd "$BUILDROOT/boringssl"
cp "build/crypto/libcrypto.a" ".openssl/lib"
cp "build/ssl/libssl.a" ".openssl/lib"

# Make the necessary directories to prepare for the Nginx configuration
sudo mkdir /var/lib/nginx
sudo mkdir /var/lib/nginx/{body,fastcgi,proxy,scgi,uwsgi}
sudo chown www-data:root /var/lib/nginx/body
sudo chown www-data:root /var/lib/nginx/fastcgi
sudo chown www-data:root /var/lib/nginx/proxy
sudo chown www-data:root /var/lib/nginx/scgi
sudo chown www-data:root /var/lib/nginx/uwsgi

# Prep nginx
mkdir -p "$BUILDROOT/nginx"
cd $BUILDROOT/nginx
curl -L -O "http://nginx.org/download/nginx-$LATESTNGINX.tar.gz"
tar -xvzf "nginx-$LATESTNGINX.tar.gz"
cd "$BUILDROOT/nginx/nginx-$LATESTNGINX"

# Configure NGinx
sudo ./configure --prefix=/usr/share/nginx --conf-path=/etc/nginx/nginx.conf --sbin-path=/usr/sbin/nginx --http-log-path=/var/log/nginx/access.log --error-log-path=/var/log/nginx/error.log --lock-path=/var/lock/nginx.lock --pid-path=/run/nginx.pid --http-client-body-temp-path=/var/lib/nginx/body --http-fastcgi-temp-path=/var/lib/nginx/fastcgi --http-proxy-temp-path=/var/lib/nginx/proxy --http-scgi-temp-path=/var/lib/nginx/scgi --http-uwsgi-temp-path=/var/lib/nginx/uwsgi --modules-path=/usr/lib/nginx/modules --with-compat --with-debug --user=www-data --group=www-data --with-file-aio --with-http_flv_module --with-http_realip_module --with-http_v2_module --with-http_v3_module --with-http_ssl_module --with-http_stub_status_module --with-http_sub_module --with-pcre --with-http_gunzip_module --with-http_gzip_static_module --with-threads --with-cc-opt="-g -O2 -fPIE -fstack-protector-all -D_FORTIFY_SOURCE=2 -Wformat -Werror=format-security -I /tmp/boring-nginx/boringssl/.openssl/include/" --with-ld-opt="-Wl,-Bsymbolic-functions -Wl,-z,relro -L /tmp/boring-nginx/boringssl/.openssl/lib/"

# Fix "Error 127" during build
touch "$BUILDROOT/boringssl/.openssl/include/openssl/ssl.h"

# Build nginx
sudo make && sudo make install

# Add systemd service
cat >/lib/systemd/system/nginx.service <<EOL
[Unit]
Description=The NGINX HTTP and reverse proxy server
After=syslog.target network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target

[Service]
Type=forking
PIDFile=/run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t
ExecStart=/usr/sbin/nginx
ExecReload=/usr/sbin/nginx -s reload
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOL

# Enable & start service
sudo systemctl enable nginx.service
sudo systemctl start nginx.service

# Finish script
sudo systemctl reload nginx.service
sudo systemctl status nginx.service -l --no-pager
sudo nginx -V 

#!/bin/bash
echo "Welcome to the dockerized GR8cloud server"
echo "========================================="
cat /srv/gr8cloudserver/readme.txt
echo ""
echo "Downloading default GR8cloud cloud volume..."
wget http://www.gr8bit.ru/software/gr8cloudserver/default-gr8cloud-volimg.rar -O /srv/gr8cloudserver/data/default-gr8cloud-volimg.rar
echo ""

if [ -z ${FTP_PWD} ]; then
  FTP_PWD=$(< /dev/urandom tr -dc A-Za-z0-9 | head -c${1:-8};echo;)
  echo "Generated password for user 'gr8ftp': ${FTP_PWD}"
fi
echo "gr8ftp:${FTP_PWD}" | /usr/sbin/chpasswd
echo ""

echo "Creating TLS self-signed certificate..."
openssl req -x509 -nodes -days 730 -newkey rsa:2048 -keyout /etc/ssl/private/vsftpd.key -out /etc/ssl/certs/vsftpd.crt -subj "/C=ES/ST=Self-signed/L=Certificate/O=HispaMSX/OU=org/CN=hispamsx.org"
echo ""

if ! [ -z ${FTP_PASV_ADDRESS} ]; then
    echo "Setting pasv_address to ${FTP_PASV_ADDRESS}"
    echo "pasv_address=${FTP_PASV_ADDRESS}" >> /etc/vsftpd/vsftpd.conf
fi

if ! [ -z ${PASSWD_URL} ]; then
    echo "Downloading passwd from: ${PASSWD_URL}"
    wget ${PASSWD_URL} -O /srv/gr8cloudserver/data/passwd
    echo ""
fi

if ! [ -z "${PASSWD_CSV}" ]; then
    echo "PASSWD_CSV variable found: ${PASSWD_CSV}"
    IFS=',' read -ra PASSWD_ARRAY <<< "$PASSWD_CSV"
    for i in "${PASSWD_ARRAY[@]}"; do
        echo "Adding ${i} to /srv/gr8cloudserver/data/passwd"
        echo ${i} >> /srv/gr8cloudserver/data/passwd
    done
fi

echo ""
echo "All done! Running services now, entering supervisord..."
echo ""
exec "$@"

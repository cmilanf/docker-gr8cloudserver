FROM microsoft/dotnet:2.1-runtime-alpine3.7

ARG DOWNLOAD_URL=http://www.gr8bit.ru/software/gr8cloudserver/gr8cloudserver.rar
ARG RAR_PWD=gr8net

LABEL title="GR8cloud server" \
  author="AGE Labs / Eugeny Brychkov" \
  maintainer="Carlos Milán Figueredo" \
  version="20181007" \
  url1="https://github.com/cmilanf/docker-gr8cloudserver" \
  url2="http://www.gr8bit.ru/software/gr8cloudserver" \
  url3="http://rs.gr8bit.ru/Documentation/GR8NET-manual.pdf" \
  twitter="@cmilanf" \
  thanksto1="Beatriz Sebastián Peña" \
  usage="docker run -it -p 684:684 -p 20:20 -p 21:21 -p 34000-34010:34000-34010 --rm --name gr8cloud -e \"FTP_PWD=gr8net\" -e \"PASSWD_CSV=101600040501 MyPassword,10160004051E i*love+gr8net,10160004057A msx_is_the_best\" -e \"FTP_PASV_ADDRESS=127.0.0.1\" cmilanf/gr8cloudserver:latest"

LABEL FTP_PWD="The FTP user password" \
    PASSWD_URL="URL for downloading a passwd file for the GR8 Cloud Server. Please note exsiting file will be overwriten!" \
    PASSWD_CSV="MAC-password pair for the GR8 Cloud Server passwd file delimited by comma. Example: 101600040501 MyPassword,10160004051E i*love+gr8net,10160004057A msx_is_the_best" \
    FTP_PASV_ADDRESS="FTP pasive mode address. If not present, it will be autodetected."

RUN mkdir -p /srv/gr8cloudserver/data \
    && mkdir -p /var/log/supervisord \
    && apk update \
    && apk add --no-cache unrar supervisor vsftpd bash openssl \
    && cd /srv/gr8cloudserver \
    && wget ${DOWNLOAD_URL} \
    && unrar e ${DOWNLOAD_URL##*/} -p${RAR_PWD} \
    && rm -f ${DOWNLOAD_URL##*/} \
    && adduser -h /srv/gr8cloudserver/data -s /sbin/nologin -D gr8ftp \
    && chown -R gr8ftp:gr8ftp /srv/gr8cloudserver/data

RUN mkdir -p /etc/ssl/private \
    && echo 'gr8ftp' >> /etc/vsftpd/vsftpd.allowed_users

VOLUME /srv/gr8cloudserver/data
COPY docker-entrypoint.bash /
COPY supervisord.conf /etc/
COPY vsftpd.conf /etc/vsftpd/

EXPOSE 684/tcp 20/tcp 21/tcp 34000-34010/tcp

ENTRYPOINT ["/docker-entrypoint.bash"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
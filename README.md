# Docker image for GR8cloud server
GR8cloud server is the server backend of the [GR8NET](https://www.msx.org/wiki/GR8NET) network virtual volume. This feature allows GR8NET equiped [MSX](https://en.wikipedia.org/wiki/MSX) computers to become effectively cloud-enabled, mapping and remote network drive as it was locally attached one, even through WAN links. This way an MSX computer can be booted from the network and it is readable and writable.

The feature and his architecture is explained in detail in chapter 7 of the [GR8NET manual](http://rs.gr8bit.ru/Documentation/GR8NET-manual.pdf).

GR8NET and GR8cloud server are developed by [Eugeny Brychkov](http://www.gr8bit.ru/).

# Architecture
Architecture follows a simple client-server model with a good reminescense of [Novell NetWare](https://en.wikipedia.org/wiki/NetWare) servers. It is composed of:

  * **The GR8cloud server**. Developed for .NET Core 2.1, exposes the port 684/tcp (configurable) that will be used by MSX computers to connect with. Authentication and data transfer are done through this port.
  * **The GR8NET client**. Client is embeded in the ROM of the GR8NET network and multimedia card for MSX. CALL NETSETCLOUD is used for the setup.

# Security considerations
MSX computers have very limited processing power, that makes any protocol encryption mostly useless and easily breakable by modern processors. As such, **communications of this software are not encrypted and hence insecure by default**. An atacker could easily intercept and read the data that is being transfered between the MSX and the GR8cloud server.

It is recommended to run this software in a isolated environment with controlled network access. Docker containerzation can help with this issue, but by no means solve it.

# The container image
Please, refer to the chapter 13.5 of the [GR8NET manual](http://rs.gr8bit.ru/Documentation/GR8NET-manual.pdf) to know the inner working details of the server. This documentation assumes it has been read and understood.

GR8cloud server has been developed with .NET Core 2.1, meaning it will run without any modification in Windows or Linux. Microsoft hosts a [big deal of .NET Core images in Docker Hub](https://hub.docker.com/r/microsoft/dotnet/) for both operating systems. For his lightweightness and deployment speed I have chosen the one for [Alpine Linux](https://alpinelinux.org/), whose base image is as small as 5 MB, ~27 MB with .NET Core runtime.

The image will run three processes:
  * **GR8cloud server**. That is the core of the solution. It is installed on `/srv/gr8cloudserver`.
  * **vsftpd**. A good support companion for the server, as it will expose his data directory through FTP, meaning we can easily upload/download volume images, logs and the password management file. It support both, plain unsecure (for the MSX) connections and TLS secured ones.
  * **Supervisord**, that basically controls the other two.

## Data persistance
I think nobody wants to lose volumes, log files and accounting data if the container dies for some reason; remember that containers must live and die dynamically without that affecting much to our sleep.

For ensuring data persistance, the `/srv/gr8cloudserver/data` directory is mounted in a [Docker Volume](https://docs.docker.com/storage/volumes/) and managed with the `-v` parameter of `docker run`. Your data can persist even if the container dies and you map the new one to the same volume. Mind the initialization of passwd file is this case.

## vsftpd
GR8cloud server reads dynamically `passwd` and volume image files in each access, meaning it is not necessary to restart the server if new files are added or the existing ones change. This is ideal for embeding an FTP service that eases the management of the solution data files. vsftpd has been integrated for this reason and his connection chrooted to the `/srv/gr8cloudserver/data` folder.

# Building instructions
It is as simple as the following one:
```
$ docker build -t myaccount/myrepo:version .
```
You can change `myaccount`, `myrepo` and `version` with your own values. `DOWNLOAD_URL` and `RAR_PWD` ARGS are supported in case the GR8cloud download URL would change.

# Running instructions
Running the service is also fairly simple, that's what Docker is about. Let's take a look to the optional environment variables:

## Optional environment variables
  * **FTP_PWD**. The FTP user password. If not present, `docker-entrypoint.bash` will generate a random one. Take a look at the log for viewing it.
  * **PASSWD_URL**. URL for downloading a passwd file for the GR8 Cloud Server. **Please note exsiting file will be overwriten!** If not present, nothing is downloaded.
  * **PASSWD_CSV**. MAC-password pair for the GR8 Cloud Server passwd file delimited by comma. The values will be added to the existing ones in the file. Example: `101600040501 MyPassword,10160004051E i*love+gr8net,10160004057A msx_is_the_best`. If not present, nothing is added to the `passwd` file.
  * **FTP_PASV_ADDRESS**. FTP pasive mode address. If not present, it will be autodetected.

## Usage
Sample running command:
```
docker run -it -p 684:684 -p 20:20 -p 21:21 -p 34000-34010:34000-34010 --rm --name gr8cloud -e "FTP_PWD=gr8net" -e "PASSWD_CSV=101600040501 MyPassword,10160004051E i*love+gr8net,10160004057A msx_is_the_best" -e "FTP_PASV_ADDRESS=127.0.0.1" cmilanf/gr8cloudserver:latest
```
This `docker-run` command exposes all the needed ports to the Docker host, give the container the name `gr8cloud`, set the FTP password to `gr8net`, add the 3 MAC addresses and passwords `101600040501 MyPassword,10160004051E i*love+gr8net,10160004057A msx_is_the_best` to the `passwd` file and specify my local computer IP address for the FTP passive connections. Finally, it uses the image from my repository, but it could be yours also!

Feel free to modify it to your needs!

# Building an MSX volume image
Building an MSX volume image is not obvious, so I will provide some guidance here. I don't know of any modern operating system tool that can do the process, so if there is not one, we will have to rely on the brilliant and advanced [openMSX](https://openmsx.org/), the cross-platform MSX emulators that aims for perfections, and I must say that it mostly achieves it!

Steps:

  1. We must configure openMSX to run with an MSX 2 computer or higher and a Nextor compatible disk interface, such as [MegaflashROM SCC+ SD](https://openmsx.org/manual/user.html#sd).
  2. Set drive size in `MegaFlashROM_SCC+_SD.xml`. It will create the SD interface images in your harddisk upon first openMSX boot up.
  3. If MegaflashROM SCC+ SD ROM is loaded correctly, you will be able to do a `CALL FDISK` from MSX-BASIC and partition your virtual SD card.
  4. Reboot openMSX, so the drive is available. You can stuff it with the files you want. For my example here, I just copied over the MegaflashROM SCC+ SD disk rom to it.
  5. Close openMSX.
  6. Upload your SD card file to the `/srv/gr8cloudserver/data/` folder. You can use the Docker image built in FTP server!
  7. Rename your image file to `yourmacaddress.img`. For instance: `101600040501.img`.
  8. Ensure the `passwd` file is correctly with the MAC and the password.
  9. Now back to your real MSX with the GR8NET!
  10. Configure your GR8cloud server from MSX-BASIC: `CALL NETSETCLOUD("myserver.mydomain.org:684","MyPassword")`
  11. Ensure GR8cloud is enabled in GR8NET: `CALL NETSETCLOUD(1)`
  12. And finally, reboot your computer in a mapper mode that has Nextor support included. For example: `CALL NETSETMAP(30)`
  13. Your MSX computer should connect to the server, mount the cloud volume and boot up from it.
  14. You can use the cloud volume as it a regular local disk were, writes supported!

Some screenshots of a real MSX:

Configuration process:

<img src="/cmilanf/docker-gr8cloudserver/screenshots/msx_config.png" width="200px" />

Bootup:

<img src="/cmilanf/docker-gr8cloudserver/screenshots/msx_network_bootup.png" width="200px" />

MSX-DOS 2 and Multimente loaded from the network!

<img src="/cmilanf/docker-gr8cloudserver/screenshots/msx_network_mm.png" width="200px" />
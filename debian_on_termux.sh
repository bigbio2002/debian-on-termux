#!/data/data/com.termux/files/usr/bin/bash

#set -x  
ARCHITECTURE=armhf
VERSION=stretch
DO_FIRST_STAGE=:  #false   # required
DO_SECOND_STAGE=: #false   # required
DO_THIRD_STAGE=:  #false   # optional (enable local policies)

filter() {
    egrep -v '^$|^WARNING: apt does'
}

cd
#
# ===============================================================
# first stage - do the initial unpack phase of bootstrapping only
#
$DO_FIRST_STAGE && {
apt update 2>&1 | filter
DEBIAN_FRONTEND=noninteractive apt -y install perl proot 2>&1 | filter                              
wget http://http.debian.net/debian/pool/main/d/debootstrap/debootstrap_1.0.91.tar.gz -O - | tar xfz -
cd debootstrap-1.0.91
#
# minimum patch needed for debootstrap to work in this environment
#
patch << 'EOF'
--- debootstrap-1.0.91.1/functions	2017-07-25 05:02:27.000000000 +0200
+++ debootstrap-1.0.91/functions	2017-10-16 18:23:46.707005005 +0200
@@ -1083,6 +1083,10 @@
 }
 
 setup_proc () {
+
+echo setup_proc
+return 0
+
 	case "$HOST_OS" in
 	    *freebsd*)
 		umount_on_exit /dev
@@ -1162,6 +1166,10 @@
 }
 
 setup_devices_simple () {
+
+echo setup_devices_simple
+return 0
+
 	# The list of devices that can be created in a container comes from
 	# src/core/cgroup.c in the systemd source tree.
 	mknod -m 666 $TARGET/dev/null	c 1 3
EOF
#
# you can watch the debootstrap progress via
# tail -F $HOME/deboot_debian9/debootstrap/debootstrap.log
#
export DEBOOTSTRAP_DIR=`pwd`
LD_PRELOAD= $PREFIX/bin/proot \
    -b /system:/system \
    -b /vendor:/vendor \
    -b /data:/data \
    -b /property_contexts:/property_contexts \
    -b /storage:/storage \
    -b $PREFIX:/usr \
    -b $PREFIX/bin:/bin \
    -b $PREFIX/etc:/etc \
    -b $PREFIX/lib:/lib \
    -b $PREFIX/share:/share \
    -b $PREFIX/tmp:/tmp \
    -b $PREFIX/var:/var \
    -b /dev:/dev \
    -b /proc:/proc \
    -r $PREFIX/.. \
    -0 \
    --link2symlink \
    ./debootstrap --foreign --arch=$ARCHITECTURE $VERSION $HOME/deboot_debian9 http://deb.debian.org/debian
} # end DO_FIRST_STAGE

#
# =================================================
# second stage - complete the bootstrapping process
#
$DO_SECOND_STAGE && {
#
# place some precrafted templates to avoid execution of adduser, addgroup
# and the like. Since these do not work well in this 
# environment (at least at the time of writing)
#
cat << 'EOF' > $HOME/deboot_debian9/etc/passwd
root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin
sys:x:3:3:sys:/dev:/usr/sbin/nologin
sync:x:4:65534:sync:/bin:/bin/sync
games:x:5:60:games:/usr/games:/usr/sbin/nologin
man:x:6:12:man:/var/cache/man:/usr/sbin/nologin
lp:x:7:7:lp:/var/spool/lpd:/usr/sbin/nologin
mail:x:8:8:mail:/var/mail:/usr/sbin/nologin
news:x:9:9:news:/var/spool/news:/usr/sbin/nologin
uucp:x:10:10:uucp:/var/spool/uucp:/usr/sbin/nologin
proxy:x:13:13:proxy:/bin:/usr/sbin/nologin
www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin
backup:x:34:34:backup:/var/backups:/usr/sbin/nologin
list:x:38:38:Mailing List Manager:/var/list:/usr/sbin/nologin
irc:x:39:39:ircd:/var/run/ircd:/usr/sbin/nologin
gnats:x:41:41:Gnats Bug-Reporting System (admin):/var/lib/gnats:/usr/sbin/nologin
nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin
systemd-timesync:x:100:102:systemd Time Synchronization,,,:/run/systemd:/bin/false
systemd-network:x:101:103:systemd Network Management,,,:/run/systemd/netif:/bin/false
systemd-resolve:x:102:104:systemd Resolver,,,:/run/systemd/resolve:/bin/false
systemd-bus-proxy:x:103:105:systemd Bus Proxy,,,:/run/systemd:/bin/false
_apt:x:104:65534::/nonexistent:/bin/false
messagebus:x:105:110::/var/run/dbus:/bin/false
sshd:x:106:65534::/run/sshd:/usr/sbin/nologin
EOF
chmod 644 $HOME/deboot_debian9/etc/passwd

cat << 'EOF' > $HOME/deboot_debian9/etc/group
root:x:0:
daemon:x:1:
bin:x:2:
sys:x:3:
adm:x:4:
tty:x:5:
disk:x:6:
lp:x:7:
mail:x:8:
news:x:9:
uucp:x:10:
man:x:12:
proxy:x:13:
kmem:x:15:
dialout:x:20:
fax:x:21:
voice:x:22:
cdrom:x:24:
floppy:x:25:
tape:x:26:
sudo:x:27:
audio:x:29:
dip:x:30:
www-data:x:33:
backup:x:34:
operator:x:37:
list:x:38:
irc:x:39:
src:x:40:
gnats:x:41:
shadow:x:42:
utmp:x:43:
video:x:44:
sasl:x:45:
plugdev:x:46:
staff:x:50:
games:x:60:
users:x:100:
nogroup:x:65534:
systemd-journal:x:101:
systemd-timesync:x:102:
systemd-network:x:103:
systemd-resolve:x:104:
systemd-bus-proxy:x:105:
input:x:106:
crontab:x:107:
netdev:x:108:
ssh:x:109:
messagebus:x:110:
EOF
chmod 644 $HOME/deboot_debian9/etc/group

cat << 'EOF' > $HOME/deboot_debian9/etc/shadow
root:*:17448:0:99999:7:::
daemon:*:17448:0:99999:7:::
bin:*:17448:0:99999:7:::
sys:*:17448:0:99999:7:::
sync:*:17448:0:99999:7:::
games:*:17448:0:99999:7:::
man:*:17448:0:99999:7:::
lp:*:17448:0:99999:7:::
mail:*:17448:0:99999:7:::
news:*:17448:0:99999:7:::
uucp:*:17448:0:99999:7:::
proxy:*:17448:0:99999:7:::
www-data:*:17448:0:99999:7:::
backup:*:17448:0:99999:7:::
list:*:17448:0:99999:7:::
irc:*:17448:0:99999:7:::
gnats:*:17448:0:99999:7:::
nobody:*:17448:0:99999:7:::
systemd-timesync:*:17448:0:99999:7:::
systemd-network:*:17448:0:99999:7:::
systemd-resolve:*:17448:0:99999:7:::
systemd-bus-proxy:*:17448:0:99999:7:::
_apt:*:17448:0:99999:7:::
messagebus:*:17448:0:99999:7:::
sshd:*:17448:0:99999:7:::
EOF
chmod 640 $HOME/deboot_debian9/etc/shadow

# since there are issues with proot and /proc mounts (https://github.com/termux/termux-packages/issues/1679)
# we currently cease from mounting /proc.
# the guest system now is setup to complete the installation - just dive in
LD_PRELOAD= $PREFIX/bin/proot \
    -b /dev:/dev \
    -r $HOME/deboot_debian9 \
    -w /root \
    -0 \
    --link2symlink \
    /usr/bin/env -i HOME=/root TERM=xterm PATH=/usr/sbin:/usr/bin:/sbin:/bin /debootstrap/debootstrap --second-stage  
} # end DO_SECOND_STAGE

#
# ======================================================================================
# optional third stage - if enabled edit some system defaults - adapt this to your needs
#
$DO_THIRD_STAGE && {

#
# there is no resolv.conf as per default
#
cat << 'EOF' > $HOME/deboot_debian9/etc/resolv.conf
nameserver 208.67.222.222
nameserver 208.67.220.220
EOF
chmod 640 $HOME/deboot_debian9/etc/resolv.conf

#
# to enter the debian guest system execute 'enter_deb' on the termux host system
#
mkdir -p $HOME/bin
cat << 'EOF' > $HOME/bin/enter_deb
LD_PRELOAD= $PREFIX/bin/proot \
    -b /dev:/dev \
    -r $HOME/deboot_debian9 \
    -w /root \
    -0 \
    --link2symlink \
    /usr/bin/env -i HOME=/root TERM=xterm /bin/bash --login
EOF
chmod 755 $HOME/bin/enter_deb

cat << 'EOF' > $HOME/deboot_debian9/root/.profile
# ~/.profile: executed by Bourne-compatible login shells.

if [ "$BASH" ]; then
  if [ -f ~/.bashrc ]; then
    . ~/.bashrc
  fi
fi
EOF

cat << 'EOF' > $HOME/deboot_debian9/tmp/dot_tmp.sh
#!/bin/sh

filter() {
    egrep -v '^$|^WARNING: apt does'
}

#
# select 'vi' as default editor for debconf/frontend
#
update-alternatives --config editor << !
2
!
#
# prefer a text editor for debconf (a GUI makes no sense here)
#
cat << ! | debconf-set-selections -v
debconf debconf/frontend                       select Editor
debconf debconf/priority                       select low
locales locales/locales_to_be_generated        select en_US.UTF-8 UTF-8
locales locales/default_environment_locale     select en_US.UTF-8
!
ln -nfs /usr/share/zoneinfo/Europe/Berlin /etc/localtime
dpkg-reconfigure -fnoninteractive tzdata
dpkg-reconfigure -fnoninteractive debconf

DEBIAN_FRONTEND=noninteractive apt -y update 2>&1 | filter                    
DEBIAN_FRONTEND=noninteractive apt -y upgrade 2>&1 | filter
DEBIAN_FRONTEND=noninteractive apt -y install locales 2>&1 | filter
update-locale LANG=en_US.UTF-8 LC_COLLATE=C
#
# place any additional packages here as you like
#
#DEBIAN_FRONTEND=noninteractive apt -y install rsync less gawk ssh 2>&1 | filter  
apt clean 2>&1 | filter
EOF
chmod 755 $HOME/deboot_debian9/tmp/dot_tmp.sh

LD_PRELOAD= $PREFIX/bin/proot \
    -b /dev:/dev \
    -r $HOME/deboot_debian9 \
    -w /root \
    -0 \
    --link2symlink \
    /usr/bin/env -i HOME=/root TERM=xterm PATH=/usr/sbin:/usr/bin:/sbin:/bin /tmp/dot_tmp.sh

} # end DO_THIRD_STAGE

echo 
echo installation successfully completed
echo to enter the guest system type '$HOME/bin/enter_deb'
echo

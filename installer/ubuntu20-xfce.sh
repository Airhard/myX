#!/data/data/com.termux/files/usr/bin/bash
folder=ubuntu20-fs
dlink="https://raw.githubusercontent.com/Airhard/myX/master/scripts"
if [ -d "$folder" ]; then
	first=1
	echo "skipping downloading"
fi
tarball="ubuntu20-rootfs.tar.gz"

if [ "$first" != 1 ];then
	if [ ! -f $tarball ]; then
		echo "Download Rootfs, this may take a while base on your internet speed."
		case `dpkg --print-architecture` in
		aarch64)
			archurl="arm64" ;;
		arm)
			archurl="armhf" ;;
		amd64)
			archurl="amd64" ;;
		x86_64)
			archurl="amd64" ;;
		*)
			echo "unknown architecture"; exit 1 ;;
		esac
		wget "https://github.com/Airhard/myX/raw/master/root-fs/focal-${archurl}.tar.gz" -O $tarball

fi
	cur=`pwd`
	mkdir -p "$folder"
	cd "$folder"
	echo "Decompressing Rootfs, please be patient."
	proot --link2symlink tar -xf ${cur}/${tarball} --exclude=dev||:
	cd "$cur"
fi
mkdir -p ubuntu20-binds
bin=start-ubuntu20.sh
echo "writing launch script"
cat > $bin <<- EOM
#!/bin/bash
cd \$(dirname \$0)
## unset LD_PRELOAD in case termux-exec is installed
unset LD_PRELOAD
command="proot"
command+=" --link2symlink"
command+=" -0"
command+=" -r $folder"
if [ -n "\$(ls -A ubuntu20-binds)" ]; then
    for f in ubuntu20-binds/* ;do
      . \$f
    done
fi
command+=" -b /dev"
command+=" -b /proc"
command+=" -b ubuntu20-fs/root:/dev/shm"
## uncomment the following line to have access to the home directory of termux
#command+=" -b /data/data/com.termux/files/home:/root"
## uncomment the following line to mount /sdcard directly to /
#command+=" -b /sdcard"
command+=" -w /root"
command+=" /usr/bin/env -i"
command+=" HOME=/root"
command+=" PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/games:/usr/local/games"
command+=" TERM=\$TERM"
command+=" LANG=C.UTF-8"
command+=" /bin/bash --login"
com="\$@"
if [ -z "\$1" ];then
    exec \$command
else
    \$command -c "\$com"
fi
EOM

mkdir -p ubuntu20-fs/var/tmp
rm -rf ubuntu20-fs/usr/local/bin/*
echo "127.0.0.1 localhost localhost" > $folder/etc/hosts
script_src="https://raw.githubusercontent.com/Airhard/myX/master/ubuntu"
wget -q $script_src/.profile -O ubuntu20-fs/root/.profile.1 > /dev/null
cat $folder/root/.profile.1 >> $folder/root/.profile && rm -rf $folder/root/.profile.1
wget -q $script_src/.bash_profile -O $folder/root/.bash_profile > /dev/null
wget -q $script_src/.bashrc -O $folder/root/.bashrc > /dev/null
wget -q $script_src/vnc -P $folder/usr/local/bin > /dev/null
wget -q $script_src/vncpasswd -P $folder/usr/local/bin > /dev/null
wget -q $script_src/vncserver-stop -P $folder/usr/local/bin > /dev/null
wget -q $script_src/vncserver-start -P $folder/usr/local/bin > /dev/null

chmod +x $folder/root/.bash_profile
chmod +x $folder/root/.profile
chmod +x $folder/usr/local/bin/vnc
chmod +x $folder/usr/local/bin/vncpasswd
chmod +x $folder/usr/local/bin/vncserver-start
chmod +x $folder/usr/local/bin/vncserver-stop

echo "fixing shebang of $bin"
termux-fix-shebang $bin
echo "making $bin executable"
chmod +x $bin
echo "removing image for some space"
rm $tarball


#DE installation addition
echo "install xfce"
wget --tries=20 $dlink/xfce19.sh -O $folder/root/xfce19.sh
clear
echo "install airPack"
wget --tries=20 $dlink/awesome.sh -O /root/awesome.sh
bash ~/awesome.sh
echo "install vscode"
wget --tries=20 $dlink/vscode_patch.sh -O /root/vscode_patch.sh
bash ~/vscode_patch.sh
echo "Setting up the installation of XFCE VNC"

echo "APT::Acquire::Retries \"3\";" > $folder/etc/apt/apt.conf.d/80-retries #Setting APT retry count
touch $folder/root/.hushlogin
echo "#!/bin/bash
rm -rf /etc/resolv.conf
echo 'nameserver 8.8.8.8' >> /etc/resolv.conf
mkdir -p ~/.vnc
apt update -y && apt install sudo dialog wget -y > /dev/null
clear
if [ ! -f /root/xfce19.sh ]; then
    wget --tries=20 $dlink/xfce19.sh -O /root/xfce19.sh
    bash ~/xfce19.sh
else
    bash ~/xfce19.sh
fi
clear
if [ ! -f /root/awesome.sh ]; then
    wget --tries=20 $dlink/awesome.sh -O /root/awesome.sh
    bash ~/awesome.sh
else
    bash ~/awesome.sh
fi
clear
if [ ! -f /usr/local/bin/vncserver-start ]; then
    wget --tries=20  $dlink/vncserver-start -O /usr/local/bin/vncserver-start
    wget --tries=20 $dlink/vncserver-stop -O /usr/local/bin/vncserver-stop
    chmod +x /usr/local/bin/vncserver-stop
    chmod +x /usr/local/bin/vncserver-start
fi
if [ ! -f /usr/bin/vncserver ]; then
    apt install tigervnc-standalone-server -y
fi
rm -rf /root/xfce19.sh
rm -rf ~/.bash_profile" > $folder/root/.bash_profile

bash $bin

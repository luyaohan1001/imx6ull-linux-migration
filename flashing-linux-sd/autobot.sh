#! /bin/sh
ff

# I.MX6ULL SD boot system flasher
# Author: Luyao Han
# Date: 03-17-2022

VERSION="1.1"

# Print the usage
usage ()
{
  echo "

Usage: `basename $1` [options] <-device> <(optional)-flash> <(optional)-ddrsize>
Examples：
sudo ./autobot.sh -device /dev/sdd
sudo ./autobot.sh -device /dev/sdd -flash emmc -ddrsize 512 
Options:
  -device              SD bulk device (e.g. /dev/<sdb>)
  -flash	       Flash type of dev board [emmc | nand]
  -ddrsize	       Select DDR size [512 | 256]
Info:
  --version            Print version.
  --help               Print help information.
"
  exit 1
}

# Default files for u-boot.
Uboot='u-boot.imx'

# execute a command and print its success status.
execute ()
{
    $* >/dev/null
    if [ $? -ne 0 ]; then
        echo
        echo "(!)error: executing $*"
        echo
        exit 1
    fi
}


# Print version 
version ()
{
  echo
  echo "`basename $1` version $VERSION"
  echo "Script for I.MX6 SD card flashing."
  echo

  exit 0
}


# Get number of args.
arg=$#
if [ $arg -ne 6 ];then
number=1

while [ $# -gt 0 ]; do
  case $1 in
    --help | -h)
      usage $0
      ;;
    -device) shift; device=$1; shift; ;;
    --version) version $0;;
    *) copy="$copy $1"; shift; ;;
  esac
done

# Validate the args.
test -z $device && usage $0
echo ""
echo "根据下面的提示，补全缺省的参数-flash -ddrsize"
read -p "请选择开发板参数，输入数字1~4，按Enter键确认
1.-flash emmc，-ddrsize 512
2.-flash emmc，-ddrsize 256
3.-flash nand，-ddrsize 512
4.-flash nand，-ddrsize 256 
输入数字1~4(default 1): " number
if [ -z $number ];then
  echo "Using default configuration: 512MB DDR EMMC"
else
  Uboot='u-boot.imx'
fi
else
# Otherwise use the parameters specified in command line.
while [ $# -gt 0 ]; do
  case $1 in
    --help | -h)
      usage $0
      ;;
    -device) shift; device=$1; shift; ;;
    -flash) shift; flash=$1; shift; ;;
    -ddrsize) shift; ddrsize=$1; shift; ;;
    --version) version $0;;
    *) copy="$copy $1"; shift; ;;
  esac
done
  if [ $flash = "emmc" -a $ddrsize = "512" ];then
    Uboot='u-boot.imx'
  fi 
fi

#测试制卡包当前目录下是否缺失制卡所需要的文件
sdkdir=$PWD/recipe
print()

if [ ! -d $sdkdir ]; then
   echo "(!)error: $sdkdir does not exist."
   exit 1
fi

if [ ! -f $sdkdir/filesystem/*.tar.* ]; then # if using tar.bz2 file
# if [ ! -f $sdkdir/filesystem/*.tar ]; then
  echo "(!)error: Cannot find compressed rootfs under $sdkdir/filesystem/"
  exit 1
fi

if [ ! -f $sdkdir/boot/zImage ]; then
  echo "(!)error: Cannot find zImage under $sdkdir/boot/"
  exit 1
fi


# Determine if the bulk device exists.
if [ ! -b $device ]; then
  echo "(!)error: $device is not a blk device."
  exit 1
fi




# Ask the user is they have selected the right device.
if [ $device = '/dev/sda' ];then
  echo "(!) Please do not choose sda device，/dev/sda is usually your computer harddisk! The script exits now..."
  exit 1 
fi
echo "Start making the SD boot system..."
echo "************************************************************"
echo "*         (!)：This will wipe off all data on $device      *"
echo "*         Do not pull out $device during this process      *"
echo "*             Press <Enter> to continue                    *"
echo "************************************************************"
read enter

# Unmount the device before formatting
for i in `ls -1 $device?`; do
 echo "Unmounting device '$i'"
 umount $i 2>/dev/null
done

# Format the $device, execution.
execute "dd if=/dev/zero of=$device bs=1024 count=1024"

# Two partitions were made:
# Partiton 1 (FAT32): device tree + kernel image => relatively small space needed.
# Partiton 2 (EXT3): root file system => relative larger space needed (64M).
cat << END | fdisk -H 255 -S 63 $device
n
p
1

+64M
n
p
2


t
1
c
a
1
w
END

# Partition 1 on SD should look like, e.g. sdb1
PARTITION1=${device}1
if [ ! -b ${PARTITION1} ]; then
        PARTITION1=${device}1
fi

# Partition 2 on SD should look like, e.g. sdb2
PARTITION2=${device}2
if [ ! -b ${PARTITION2} ]; then
        PARTITION2=${device}2
fi

# Format first partition to FAT32
echo "Formatting ${device}1 ..."
if [ -b ${PARTITION1} ]; then
	mkfs.vfat -F 32 -n "boot" ${PARTITION1}
else
	echo "(!)error: Cannot find boot partition under /dev in SD."
fi
# Format second partition as ext3
echo "Formatting ${device}2 ..."
if [ -b ${PARITION2} ]; then
	mkfs.ext3 -F -L "rootfs" ${PARTITION2}
else
	echo "(!)error: Cannot find rootfs partition under /dev in SD."
fi

while [ ! -e $device ]
do
sleep 1
echo "wait for $device appear"
done

echo "Flashing ${Uboot} to ${device}"
execute "dd if=$sdkdir/boot/$Uboot of=$device bs=1024 seek=1 conv=fsync"
sync
echo "Completed: Flashing ${Uboot} to ${device}."

echo "Start cloning..."
echo "Cloning the device tree and kernel to ${device}1..."
execute "mkdir -p /tmp/sdk/$$"

while [ ! -e ${device}1 ]
do
sleep 1
echo "wait for ${device}1 appear"
done

execute "mount ${device}1 /tmp/sdk/$$"
#execute "cp -r $sdkdir/boot/*${flash}*.dtb /tmp/sdk/$$/"
execute "cp -r $sdkdir/boot/imx6ull-alientek-emmc-luyaohan1001.dtb /tmp/sdk/$$/"
execute "cp -r $sdkdir/boot/zImage /tmp/sdk/$$/"
#execute "cp $sdkdir/boot/alientek.bmp /tmp/sdk/$$/"
sync
echo "Completed: Cloning device tree and kernel to ${device}1！"

if [ "$copy" != "" ]; then
  echo "Copying additional file(s) on ${device}p1"
  execute "cp -r $copy /tmp/sdk/$$"
fi

echo "unmounting${device}1..."
execute "umount /tmp/sdk/$$"
sleep 1

# Decompress files system to its partition.
# Mount the file system partition.
execute "mkdir -p /tmp/sdk/$$"
execute "mount ${device}2 /tmp/sdk/$$"

echo "Decompressing file system to ${device}2..."
rootfs=`ls -1 $sdkdir/filesystem/*.tar.*` # if using rootfs.tar.bz2
# rootfs=`ls -1 $sdkdir/filesystem/*.tar` # if using rootfs.tar
execute "tar jxfm $rootfs -C /tmp/sdk/$$" # if using rootfs.tar.bz2
# execute "tar xvf $rootfs -C /tmp/sdk/$$" # if using rootfs.tar
sync
echo "Completed: Depressing file system to ${device}2."

'''
#判断是否存在这个目录，如果不存在就为文件系统创建一个modules目录
if [ ! -e "/tmp/sdk//lib/modules/" ];then
mkdir -p /tmp/sdk/lib/modules/
fi

echo "正在解压模块到${device}2/lib/modules/ ，请稍候..."
modules=`ls -1 modules/*.tar.*`
execute "tar jxfm $modules -C /tmp/sdk/$$/lib/modules/"
sync
echo "解压模块到${device}2/lib/modules/完成！"
'''

echo "unmounting ${device}2..."
execute "umount /tmp/sdk/$$"

execute "rm -rf /tmp/sdk/$$"
sync

echo '---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----'
echo "*** Completed flashing the SD boot system! ***"
echo '---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----'




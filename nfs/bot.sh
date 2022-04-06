# Copies the file from symlinks to this current folder.
if [[ $1 == '' ]]; then
	echo 'Usage: 
		./bot clean		=> Delete all copied files.
		./bot fetch		=> Copy files from the symlinks.'
fi

if [[ $1 == 'clean' ]]; then 
	echo 'deleting imxdownload | u-boot.bin | rootfs files...'
	rm -rf imxdownload u-boot.bin rootfs
	echo 'Done.'
	exit 0
fi

if [[ $1 == 'fetch' ]]; then 
	echo 'fetching from symlinks...'
	cd symlinks
	for FILE in *; do
		symlink_dest=`readlink -f $FILE`
		cp -r $symlink_dest ..
	done
	echo 'Done.'
	exit 0
fi


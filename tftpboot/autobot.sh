# Copies the file from symlinks to this current folder.

if [[ $1 == '' ]]; then
	echo 'Usage: 
		./autobot clean		=> Deletes the .dtb (device tree binary) and zImage (kernel).
		./autobot fetch		=> Copies the files from the symlinks.'
fi

if [[ $1 == 'clean' ]]; then 
	echo 'deleting .dtb | zImage files...'
	rm *.dtb zImage
	echo '- done -'
	exit 0
fi

if [[ $1 == 'fetch' ]]; then 
	echo 'fetching from symlinks...'
	cd symlinks
	for FILE in *; do
		symlink_dest=`readlink -f $FILE`
		cp $symlink_dest ..
	done
	echo '- done -'
	exit 0
fi

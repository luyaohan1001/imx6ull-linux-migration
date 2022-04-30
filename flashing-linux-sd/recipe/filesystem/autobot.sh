

# Copies the file from symlinks to this current folder.

if [[ $1 == '' ]]; then
	echo 'Usage: 
		./autobot clean		=> Deletes the .dtb (device tree binary), zImage (kernel), and .imx (uboot) files.
		./autobot fetch		=> Copies the files from the symlinks in symlinks folder.'
fi

if [[ $1 == 'clean' ]]; then 
	echo 'deleting compressed rootfs...'
	rm rootfs.tar.bz2
	echo '- done -'
	exit 0
fi

if [[ $1 == 'fetch' ]]; then 
	echo 'fetching from symlinks...'

	sudo cp -r symlinks/rootfs .
	cd rootfs 
	tar -cvjSf rootfs.tar.bz2 ./*
	cd ..
	mv ./rootfs/rootfs.tar.bz2 .
	rm -rf rootfs

	# mkdir rootfs
	# cp symlinks/rootfs.tar ./rootfs
	# cd rootfs
	# tar -xvf rootfs.tar
	# tar -cvjSf rootfs.tar.bz2 ./*
	# cd ..
	# mv ./rootfs/rootfs.tar.bz2 .
	# rm -rf rootfs
	
	echo '- done -'
	exit 0
fi

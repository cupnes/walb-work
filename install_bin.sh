#!/bin/bash

src_path=$1
dst_root=$2

src_dir_path=$(dirname ${src_path})

sudo mkdir -p ${dst_root}/${src_dir_path}
sudo cp -a ${src_path} ${dst_root}/${src_dir_path}/

for lib in $(ldd ${src_path} | grep -v 'linux-vdso' | sed 's/.*\(\/lib.*\/.*\) .*/\1/g'); do
	path=$(dirname $lib)
	sudo mkdir -p ${dst_root}/$path
	sudo cp -a -H $lib ${dst_root}/$path/
done

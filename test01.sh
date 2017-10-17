#!/bin/sh

cd /root

# ## ディスクの準備

# * ループパックデバイス用に 100MiB のファイルを作る。
dd if=/dev/zero of=tutorial-disk bs=1M seek=100 count=1

# * /dev/loop0 に割り当てる。
dev_loop_warp=$(losetup -f)
losetup ${dev_loop_warp} tutorial-disk

# * 物理ボリュームを初期化する。
pvcreate ${dev_loop_warp}

# * LV をいくつか作る。
vgcreate tutorial ${dev_loop_warp}
mkdir -p /dev/tutorial

# lvcreate -n wdata -L 10m tutorial
# lvcreate -n wdata -L 10m --noudevsync tutorial
# dmsetup create tutorial-wdata --table '0 24576 linear 7:1 2048'
# dev_dm_wdata=$(ls /dev/dm-* | tail -n 1)
# ln -s ${dev_dm_wdata} /dev/tutorial/wdata

# lvcreate -n wlog -L 10m tutorial
# dmsetup create tutorial-wlog --table '0 24576 linear 7:1 26624'
# dev_dm_wlog=$(ls /dev/dm-* | tail -n 1)
# ln -s ${dev_dm_wlog} /dev/tutorial/wlog

# lvcreate -n data -L 20m tutorial
# dmsetup create tutorial-data --table '0 40960 linear 7:1 51200'
# dev_dm_data=$(ls /dev/dm-* | tail -n 1)
# ln -s ${dev_dm_data} /dev/tutorial/data

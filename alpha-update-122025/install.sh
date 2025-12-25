read -r -p "Press enter to backup current files..." _
mount /dev/mmcblk0p1 /mnt/sd

mkdir -p backup
cp /mnt/sd/soc_system.rbf ./backup/
cp -R /usr/local/bin ./backup/usr_local_bin/
cp -R /mnt/data/dma_demos ./backup/dma_demos
cp -R /mnt/data/demos ./backup/demos

read -r -p "Press enter to update FPGA core and binaries in /usr/local/bin..." _
cp -v ./soc_system-121925-1_pem_1.23.rbf /mnt/sd/soc_system.rbf

pkill sysop
pkill pll_config

tar -xvzf ./usr_local_bin_122025.tar.gz -C /usr/local/bin

read -r -p "Press enter to update /mnt/data/demos and /mnt/data/dma_demos..." _
tar -xvzf ./mnt_data.tar.gz -C /mnt/data

read -r -p "Press enter to reboot (required)..." _
reboot now

#!/bin/bash
#check kernel dir
ls -ld /usr/src/kernels/$(uname -r)
if [ $? -ne 0 ];then
   echo '###The kernel dir problem please check the env!###'
   exit 8
fi

#begin install drbd
mkdir /application
mkdir -p /application/drbd8.4.4/var/run/drbd
tar xf drbd-8.4.4.tar.gz
cd drbd-8.4.4
./configure --prefix=/application/drbd8.4.4 --with-km --with-heartbeat --sysconfdir=/etc/
make KDIR=/usr/src/kernels/$(uname -r)
make install

#modify configuration
cp /etc/drbd.conf /etc/drbd.conf_$(date +%F)
rm -f /etc/drbd.conf
cat >>/etc/drbd.conf<<eof
global {
    usage-count no;
}

common {
    syncer {
        rate 1000M;
        verify-alg crc32c;
    }
}

# primary for drbd1
resource data {
    protocol C;

    disk {
      on-io-error detach;
    }

    on data-1-1 {
      device     /dev/drbd0;
      disk       /dev/sdb1;
      address    10.0.0.221:7788;
      meta-disk  /dev/sdb2[0];
     }

     on data-1-2 {
       device     /dev/drbd0;
       disk       /dev/sdb1;
       address    10.0.0.222:7788;
       meta-disk   /dev/sdb2[0];
      }
}
eof

#load kernel model
modprobe drbd

#create metal
drbdadm create-md data

#start service
drbdadm up data


#!/bin/bash

sqlmode="$(mysql -B -e "show global variables like 'sql_mode'" | grep sql_mode | awk '{ print $2; }' | sed -e 's/ONLY_FULL_GROUP_BY,//')"

cat > /etc/mysql/mysql.conf.d/cloudstack.cnf <<EOF
[mysqld]
server_id = 1
sql_mode = "$sqlmode"
innodb_rollback_on_timeout = 1
innodb_lock_wait_timeout = 600
max_connections = 1000
log_bin = mysql-bin
binlog_format = "ROW"
EOF

systemctl restart mysql

#### NFS 
echo "/export  *(rw,async,no_root_squash,no_subtree_check)" >> /etc/exports
mkdir -p /export/primary /export/secondary
exportfs -a

sed -i -e 's/^RPCMOUNTDOPTS="--manage-gids"$/RPCMOUNTDOPTS="-p 892 --manage-gids"/g' /etc/default/nfs-kernel-server
sed -i -e 's/^STATDOPTS=$/STATDOPTS="--port 662 --outgoing-port 2020"/g' /etc/default/nfs-common
if ! grep 'NEED_STATD=yes' /etc/default/nfs-common > /dev/null; then
    echo "NEED_STATD=yes" >> /etc/default/nfs-common
fi
sed -i -e 's/^RPCRQUOTADOPTS=$/RPCRQUOTADOPTS="-p 875"/g' /etc/default/quota

service nfs-kernel-server restart

### KVM

sed -i -e 's/\#vnc_listen.*$/vnc_listen = "0.0.0.0"/g' /etc/libvirt/qemu.conf
if ! grep '^LIBVIRTD_ARGS="--listen"' /etc/default/libvirtd > /dev/null; then
    echo LIBVIRTD_ARGS=\"--listen\" >> /etc/default/libvirtd
fi
if ! grep 'listen_tcp=1' /etc/libvirt/libvirtd.conf > /dev/null; then
  echo 'listen_tcp=1' >> /etc/libvirt/libvirtd.conf
  echo 'listen_tls=0' >> /etc/libvirt/libvirtd.conf
  echo 'tcp_port = "16509"' >> /etc/libvirt/libvirtd.conf
  echo 'mdns_adv = 0' >> /etc/libvirt/libvirtd.conf
  echo 'auth_tcp = "none"' >> /etc/libvirt/libvirtd.conf
systemctl mask libvirtd.socket libvirtd-ro.socket libvirtd-admin.socket libvirtd-tls.socket libvirtd-tcp.socket

systemctl restart libvirtd


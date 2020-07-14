#!/bin/bash

function set_systemd() {
  mkdir -p /etc/systemd/system.conf.d/
  cat << EOF >/etc/systemd/system.conf.d/limits.conf
[Manager]
DefaultLimitNOFILE=65535
EOF
  systemctl daemon-reexec
}

#禁用selinux
function set_selinux() {

if [ $(grep -cE '^SELINUX=disabled$' /etc/selinux/config) -eq 0 ];then
    /usr/sbin/setenforce 0
    sed -i '/^SELINUX=/s/SELINUX=.*/SELINUX=disabled/' /etc/selinux/config > /dev/null
    echo "selinux is disabled,you must reboot!"
fi
}

#配置内核参数
function set_sysctl() {

grep -qE '^###ops_diy_flag_limits$' /etc/security/limits.conf || \
echo "###ops_diy_flag_limits
*    soft    nofile    52100
*    hard    nofile    52100
*    soft    nproc    32768
*    hard    nproc    65536
*    soft    core    0" >> /etc/security/limits.conf

[ -f /etc/sysctl.conf ] || touch /etc/sysctl.conf

if (! grep -qE '^###ops_diy_flag_sysctl$' /etc/sysctl.conf);then
mv /etc/sysctl.conf /etc/sysctl.conf_bak

iMyRam=`free -m|grep Mem:|awk '{print $2}'`
ikernel_shmmax=`expr $iMyRam \* 1024 \* 1024 \* 80 \/ 100`


echo "###ops_diy_flag_sysctl
net.ipv4.ip_forward = 0
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.default.accept_source_route = 0
kernel.sysrq = 0
kernel.core_uses_pid = 1
net.ipv4.tcp_syncookies = 1
kernel.msgmnb = 65536
kernel.msgmax = 65536
#kernel.shmmax = ${ikernel_shmmax}
#kernel.shmall = 134217728
#net.ipv4.ip_local_port_range = 10240 63535
#net.ipv4.ip_local_reserved_ports = 10241, 10242-12000
net.ipv4.ip_local_port_range = 30000 63535
net.ipv4.tcp_max_tw_buckets = 9000
net.ipv4.tcp_keepalive_time = 180
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_keepalive_probes = 2
net.ipv6.conf.all.disable_ipv6 = 1
net.core.rmem_max = 33554432
net.core.wmem_max = 33554432
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.nf_conntrack_max = 524288
net.ipv4.tcp_fin_timeout = 30
#net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 0
net.core.netdev_max_backlog = 30000
net.core.somaxconn = 65535
net.ipv4.tcp_max_orphans = 262144
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 2
vm.swappiness = 5
vm.overcommit_memory = 1
fs.file-max = 4096000
kernel.ctrl-alt-del = 1" > /etc/sysctl.conf

sysctl -p /etc/sysctl.conf

fi
}

set_systemd
set_selinux
set_sysctl

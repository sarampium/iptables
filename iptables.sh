#!/bin/bash

# 1. Instalación de paquetes
echo "Instalando paquetes necesarios..."
apt-get update
apt-get install -y iptables iputils-ping net-tools vlan rsyslog


# 2. Activación del protocolo dot1q y forwarding de paquetes
echo 1 > /proc/sys/net/ipv4/ip_forward
echo "Activando el protocolo dot1q..."
modprobe 8021q
echo "8021q" | tee -a /etc/modules

# 3. Configuración de red
echo "Configurando las interfaces de red..."
ip link add link <TU INTERFAZ> name LAN type vlan id 10
ip link add link <TU INTERFAZ> name WAN type vlan id 20
ip link add link <TU INTERFAZ> name DMZ type vlan id 30

ip addr add 10.10.10.1/24 dev LAN
ip addr add 10.10.20.1/24 dev WAN
ip addr add 10.10.30.1/24 dev DMZ

ip route add default via 192.168.29.2 dev <TU INTERFAZ>

ip link set up LAN
ip link set up WAN
ip link set up DMZ

# 4. Restaurar reglas de iptables
echo "Restaurando reglas de iptables..."
iptables-restore < reglas.backup

# 5. Aplicando reglas de Fail2ban
cp jail.local /etc/fail2ban/jail.local

systemctl restart fail2ban
fail2ban-client status sshd

echo "El firewall está listo."
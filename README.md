# Firewall iptables
Este es un Firewall escrito con iptables para un servidor Linux.

### Instalación rápida
Edita los campos indicados en los archivos `iptables.sh` y `reglas.backup` respectivamente.

* <TU INTERFAZ> sería algo como `eth0`, `ens33`, `enp0s3`...
* <HOST MACHINE IP/MASK> se refiere a la dirección IP de, idealmente, el gateway. Suponiendo que este firewall está en un ámbito virtualizado. La máscara se pone en notación con barra, ej. `/24`.
* <FIREWALL IP/MASK> es la IP del servidor donde se está instalando el firewall.
* NOTA: si estás usando una distro que no sea Debian based, edita también la sección de instalación de dependencias para usar el gestor de paquetes de tu distro.

Hecho esto, dale permisos de ejecución al script y ejecuta `bash iptables.sh` y se instalará automáticamente. Puedes ver las reglas del firewall con el comando `iptables -L -n -v`

Para hacer que todos los cambios sean permanentes, hay que editar la configuración en `/etc/netplan50-cloud-init.yaml`, más adelante en esta explicación se explica cómo.

# Instalación manual

## Stateless firewall
Haremos primero la configuración inicial de un firewall stateless para luego construir sobre él una estructura más compleja.

Dependencias:
`sudo su
apt update
apt install nano openssh-server iptables iputils-ping net-tools vlan apache2 rsyslog nmap fail2ban`

Habilitamos el protocolo dot1Q para el encapsulamiento de paquetes debido a las VLAN:
`sudo modprobe 8021q
echo "8021q" | sudo tee -a /etc/modules`

Se puede verificar si se activó el protocolo mediante `lsmod | grep 8021q`, debería salir un mensaje diciendo 8021q. Si no aparece, no importa, igualmente más adelante se verificará la comunicación entre VLANs.

Creemos las VLANs:

`ip link add link ens33 name LAN type vlan id 10`

`ip link add link ens33 name WAN type vlan id 20`

`ip link add link ens33 name DMZ type vlan id 30`

`ip addr add 10.10.10.1/24 dev LAN`

`ip addr add 10.10.20.1/24 dev WAN`

`ip addr add 10.10.30.1/24 dev DMZ`

Se crean redes WAN, LAN y DMZ pero puedes crear VLANs con el nombre y ID que quieras. También puedes crear más de tres, poner un direccionamiento distinto, etc. Pero más adelante tendrás que cambiar los nombres de las VLAN y las direcciones con las que tú hayas escogido. 

Crea una ruta por defecto si no tienes una. `ip route add default via 192.168.29.2 dev ens33`

### Agregar reglas
Para poder poner a prueba nuestro firewall, es una buena idea poner como base unas reglas seguras:
* No admitir tráfico entrante `iptables -P INPUT DROP`
* No admitir tráfico interVLAN `iptables -P FORWARD DROP`
* Permitir el envío de paquetes `iptables -P OUTPUT ACCEPT`

Crear estas reglas de primero es importante porque las siguientes que agreguemos estarán por encima de ellas en la jerarquía, esto les dará más importancia a las reglas que vayamos agregando. Sin embargo, si hay tráfico que no sea filtrado por ninguna de nuestras reglas, terminarán filtradas por estos tres criterios. Si quieres que las reglas base sean aún más seguras, puedes reemplazar la última regla por `iptables -P OUTPUT DROP` para evitar ataques con netcat.

* También deberíamos agregar una regla que permita la comunicación entre el firewall y la máquina host (si tu firewall no es virtualizado puedes ignorar este paso): `iptables -A INPUT -s <HOST MACHINE IP/MASK> -d <FIREWALL IP/MASK> -j ACCEPT`

Agregar reglas típicas para la DMZ sería solo permitir el tráfico en puertos especiales, ej. 22, 23, 80 y 8080. Podríamos entonces crear reglas con la siguiente sintaxis:

`iptables -A INPUT -i DMZ -p tcp --dport 22 -j ACCEPT`

`iptables -A INPUT -i DMZ -p tcp --dport 80 -j ACCEPT`

Agregar reglas para proteger aún más la DMZ: `iptables -A OUTPUT -s 10.10.30.1 -p icmp -j DROP`

Crear network address translation (NAT) para la red del firewall `iptables -t nat -A POSTROUTING -o ens33 -j MASQUERADE`

NOTA: Nuestras interfaces consideran que las redes WAN, LAN y DMZ son VLANs, pero en un contexto de poner el firewall a prueba, son redes internas. Claramente queremos que exista una comunicación entre estas redes (con ciertas restricciones).

Para permitir esta comunicación tenemos que permitir el forwarding de paquetes con `echo 1 > /proc/sys/net/ipv4/ip_forward`

`iptables -A FORWARD -i LAN -o ens33 -j ACCEPT`

`iptables -A FORWARD -i WAN -o ens33 -j ACCEPT`

`iptables -A FORWARD -i DMZ -o ens33 -j ACCEPT`

# Stateful firewall
Por brevedad no se explicará qué es un firewall con estados. En pocas palabras es un firewall que es más selectivo al permitir comunicaciones entre los puertos dinámicos.

`iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT`: Admitir la entrada de paquetes para conexiones ya establecidas.

`iptables -A INPUT -m conntrack --ctstate INVALID -j DROP`: Soltar paquetes para conexiones entrantes que no estén relacionadas a ninguna conexión actual.

`iptables -A INPUT -p tcp --dport X -m conntrack --ctstate NEW -j ACCEPT`: Admitir comunicación entre conexiones nuevas en el puerto X (cambiar X con el puerto deseado, ej. 22).

# Permanencia 
Hay que asegurar que las VLANs, el direccionamiento y el enrutamiento no se pierdan al reiniciar el servidor, para ello tenemos que modificar la configuración en nuestro archivo `/etc/netplan/xyz.yaml`, en este directorio hay un ejemplo de archivo que puedes colocar en tu configuración para que no se pierda la configuración de red al reiniciar.

Si usaste mi configuración, haz: `chmod 600 /etc/netplan/50-cloud-init.yaml` y luego `netplan apply` (verifica que el proceso `systemd-networkd` está activo y corriendo.

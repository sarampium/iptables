# Firewall iptables
Este es un Firewall escrito con iptables para un servidor Linux

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

`sudo su
apt update
apt install nano openssh-server iptables iputils-ping net-tools vlan apache2 rsyslog nmap fail2ban`

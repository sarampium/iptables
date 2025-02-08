# iptables
Este es un Firewall escrito con iptables para servidor Linux

### Instalación rápida
Edita los campos indicados en los archivos iptables.sh y <reglas.backup respectivamente.

* <TU INTERFAZ> sería algo como eth0, ens33, enp0s3...
* <HOST MACHINE IP/MASK> se refiere a la dirección IP de, idealmente, el gateway. Suponiendo que este firewall está en un ámbito virtualizado. La máscara se pone en notación con barra, ej. /24
* <FIREWALL IP/MASK> es la IP del servidor donde se está instalando el firewall

Hecho esto, dale permisos de ejecución al script y ejecuta `bash iptables.sh` y se instalará automáticamente. Puedes ver las reglas del firewall con el comando `iptables -L -n -v`

Puedes agregar más reglas y modificar el firewall como gustes utilizando la sintaxis de las reglas iptables.


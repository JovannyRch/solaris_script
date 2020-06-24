#!/usr/bin/env bash

#Autor:  Jovanny Ramírez Chimal

showNics() {
    dladm show_phys
}

showIp() {
    nat = $1
    ipadm show-addr | grep $nat
}

chooseNic() {
    showNics
    read -p "Elige un adpatador de red: " adapter
    echo $adapter
}

createIp() {
    nat = $1
    check = "$(ipadm create-ip $nat)"
}

configDhcp() {
    nat = $1
    createIP $nat
    ipadm create-addr -T dhcp $nat/v4
    showIP $nat/v4
}

configIpv6() {
    nat = $1
    ip = $2
    createIP $nat
    ipadm create-addr -T static -a local=$ip $nat/v4
    showIp $nat
}

deleteIp() {
    nat = $1
    res = "$(ipadm delete-addr $nat)"
}

configIp() {
    nat = $1
    ip = $2
    deleteIp $nat/v4
    ipadm create-addr -T static -a local=$ip $nat/v4
    showIp $nat/v4
}

quit() {
    exit
}

echo "$(date)                              "
echo "=======   MENU PRINCIPAL  ==========="
echo "1.- Listar interfaces de red"
echo "2.- Levantar una interfaz de red"
echo "3.- Asignar dirección IP estatica"
echo "4.- Configurar DHCP"
echo "5.- Ver direcciones IP"
echo ""
read -p "Elige una opcion: " opcion

echo $opcion

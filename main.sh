#!/usr/bin/env bash

#Autor:  Jovanny Ramírez Chimal

showNics() {
    #i=1
    for col in $(dladm show-phys | awk '{ print $1":"$3 }'); do
        if [[ "$col" = *net* ]]; then
            echo "  - $col"
            #i=$(($i + 1))
        fi
    done
}

showIps() {
    ipadm show-addr | grep /v4
}

pressAnyKey() {
    echo ""
    echo "Presiona cualquier tecla para continuar... "
    read -n1
}

title() {
    msg=$1
    echo "============================================"
    echo "          $msg"
    echo "============================================"
}

subtitle() {
    msg=$1
    echo "------------------------------------------------"
    echo "          $msg"
    echo "------------------------------------------------"
}

setIpDhcp() {
    clear
    subtitle "Asignar IPv4 por DHCP"
    showNics
    echo -e "\n  0 para salir \n"
    read -p "Escriba la interfaz de red: " net

    if [ "$net" != "0" ]; then
        isValid="$(ipadm show-addr | grep $net/v4dhpc | grep dhcp | awk '{ print $4 }')"
        ok=1
        if [ -n "$isValid" ]; then
            ok=0
            echo -e "La interfaz ya tiene una IP asignada por DHCP\n"
            ipadm show-addr | grep $net/v4
            echo ""
            read -p "¿Desea eliminar la ip? (S/N) " opc
            if [ "${opc^^}" = "S" ]; then
                ipadm delete-addr $net/v4
                ok=1
            fi

        fi
        if (($ok == 1)); then
            echo "Asignando IP por DHCP..."
            status=$(showStatus $net)
            if [ "$status" = "unknown" ]; then
                echo "Habilitanto la interfaz..."
                ipadm create-ip $net
            fi
            ipadm create-addr -T dhcp $net/v4dhcp
            ipadm show-addr | grep $net/v4dhcp | grep dhcp
        fi
    fi
}

setDhcpFile() {
    subtitle "Configurar archivo de DHCP"
    read -p "Ingrese id de la red: " id
    read -p "Mascara de red: " mask
    read -p "Interfaz: " net
    read -p "Rango inicial: " rango1
    read -p "Rango final: " rango2
    read -p "Dirección de broadcast: " broadcast
    cat >/etc/inet/dhcpd4.conf <<EOL
subnet ${id} netmask ${mask} {
    interface ${net};
    range ${rango1} ${rango2};
    option routers ${id};
    option broadcast-address ${broadcast};
}
EOL
}

showStatusDhcp() {
    status="$(svcs -a | grep dhcp | grep server | grep ipv4 | awk '{ print $1 }')"
    if [ "$status" = "disabled" ]; then
        echo "Deshabilitado"
    elif [ "$status" = "online" ]; then
        echo "Habilitado"
    else
        echo "En mantenimiento"
    fi

}

configDhcp() {

    while [ $opcion != "5" ]; do
        clear
        ok=0
        echo ""
        echo "Obteniendo estado del servicio de DHCP ..."
        status="$(showStatusDhcp)"
        if [ "$status" = "Habilitado" ]; then
            ok=1
        fi
        clear
        subtitle "Configurar servicio de DHCP"

        echo -e "\nStatus del servicio: $status \n"
        if (($ok == 1)); then
            echo "1.- Deshabilitar servicio"
        else
            echo "1.- Habilitar servicio"
        fi
        echo "2.- Reiniciar servicio de DHCP"
        echo "3.- Setear archivo de configuración"
        echo "4.- Ver archivo de configuración"
        echo "5.- Salir"
        echo ""
        echo
        read -p "Elige una opcion: " opcion
        clear
        case "$opcion" in
        1)
            if (($ok == 1)); then
                echo "Deshabilitando el servicio de DHCP..."
                svcadm disable /network/dhcp/server:ipv4
                sleep 1
            else
                echo "Habilitando el servicio de DHCP..."
                svcadm enable /network/dhcp/server:ipv4
                sleep 1
            fi
            ;;
        2)
            echo "Reiniciando servicio de DHCP..."
            svcadm disable /network/dhcp/server:ipv4
            svcadm enable /network/dhcp/server:ipv4
            sleep 1
            ;;

        3)
            subtitle "Configurar archivo de configuración"
            setDhcpFile
            pressAnyKey
            ;;
        4)
            subtitle "Archivo de configuración dhcpd4.conf"
            cat /etc/inet/dhcpd4.conf
            pressAnyKey
            ;;

        5) ;;
        *)
            echo "Opcion incorrecta"
            ;;
        esac
    done
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

listarInterfaces() {
    subtitle "Lista de interfaces de red"
    showNics
}

showStatus() {
    net=$1
    echo "$(dladm show-phys | grep $net | awk '{ print $3 }')"
}

levantarInterfaz() {
    net="1"
    while [ $net != "0" ]; do
        clear
        subtitle "Levantar o bajar una interfaz de red"
        showNics
        echo -e "\n  0 para salir \n"
        read -p "Escriba la interfaz de red: " net
        if [ "$net" != "0" ]; then
            status=$(showStatus $net)
            echo "Status: $status"
            if [ "$status" = "up" ]; then
                echo "La interfaz esta levantada"
                read -p "¿Deseas eliminar la interfaz? (s/n): " option

                if [ "${option^^}" = "S" ]; then
                    echo "Configurando..."
                    ipadm delete-ip $net
                    sleep 2
                    echo "Nuevo estado de la interfaz"
                    echo "$net : $(showStatus $net)"
                fi

            else
                echo "La interfaz NO esta levantada"
                read -p "¿Deseas crear la interfaz? (s/n): " option

                if [ "${option^^}" = "S" ]; then
                    echo "Configurando..."
                    ipadm create-ip $net
                    sleep 2
                    echo "Nuevo estado de la interfaz"
                    echo "$net : $(showStatus $net)"
                fi
            fi
            pressAnyKey
        fi

    done

}

validarIpv4() {
    net=$1
    echo "$(ipadm show-addr | grep $net/v4 | grep static | awk '{ print $4 }')"
}

validarIpv4Dhcp() {
    net=$1
    echo "$(ipadm show-addr | grep $net/v4 | grep dhcp | awk '{ print $4 }')"
}

asignarIP() {
    clear
    subtitle "Asignar IPv4 estática"
    showNics
    echo -e "\n  0 para salir \n"
    read -p "Escriba la interfaz de red: " net

    if [ "$net" != "0" ]; then
        isValid="$(ipadm show-addr | grep $net/v4 | grep static | awk '{ print $4 }')"
        ok=1
        if [ -n "$isValid" ]; then
            ok=0
            echo -e "La interfaz ya tiene una IP asignada \n"
            ipadm show-addr | grep $net/v4
            echo ""
            read -p "¿Desea eliminar la ip? (S/N) " opc
            if [ "${opc^^}" = "S" ]; then
                ipadm delete-addr $net/v4
                ok=1
            fi

        fi
        if (($ok == 1)); then
            read -p "Escriba la dirección ip: " ip
            echo "Asignando IP..."
            status=$(showStatus $net)
            if [ "$status" = "unknown" ]; then
                echo "Habilitanto la interfaz..."
                ipadm create-ip $net
            fi
            ipadm create-addr -T static -a local=$ip $net/v4
            ipadm show-addr | grep $net/v4 | grep static
        fi
    fi

}

deleteIp() {
    subtitle "Eliminar IP"
    showIps
    echo ""
    read -p "Ingrese ADDROBJ: " id
    echo "Eliminando ip..."
    sleep 2
    ipadm delete-addr $id
}

configIp() {
    while [ $opcion != "5" ]; do
        clear
        subtitle "Configurar IP"
        echo "1.- Ver lista de IPs"
        echo "2.- Crear IPv4 estática"
        echo "3.- Asignar IPv4 por DHCP"
        echo "4.- Eliminar IP"
        echo "5.- Salir"
        echo ""
        read -p "Elige una opcion: " opcion
        clear
        case "$opcion" in
        1)
            subtitle "Lista de direcciones IPs  "
            showIps
            pressAnyKey
            ;;
        2)
            asignarIP
            pressAnyKey
            ;;
        3)
            setIpDhcp
            pressAnyKey
            ;;
        4)
            deleteIp
            pressAnyKey
            ;;
        5) ;;

        *)
            echo "Opcion incorrecta"
            ;;
        esac
    done
}

main() {

    while :; do
        clear
        echo "$(date)                              "
        title "MENÚ PRINCIPAL"
        echo "1.- Listar interfaces de red"
        echo "2.- Levantar/Bajar una interfaz de red"
        echo "3.- Configurar IP"
        echo "4.- Configurar DHCP"
        echo "5.- Salir"
        echo ""
        echo
        read -p "Elige una opcion: " opcion
        clear
        case "$opcion" in
        1)
            listarInterfaces
            pressAnyKey
            ;;
        2)
            levantarInterfaz
            ;;
        3)
            configIp
            ;;
        4)
            configDhcp

            ;;
        5)
            exit
            ;;
        *)
            echo "Opcion incorrecta"
            pressAnyKey
            ;;
        esac

    done
}

main

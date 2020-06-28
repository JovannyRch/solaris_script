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

traslateEs() {
    status=$1
    if [ "$status" = "online" ]; then
        echo "Activado"
    elif [ "$status" = "disabled" ]; then
        echo "Desactivado"
    else
        echo "En mantenimiento"
    fi

}

showStatusServices() {
    dhcpIpv4="$(svcs -a | grep dhcp | grep server | grep ipv4 | awk '{ print $1 }')"
    dhcpIpv4="$(traslateEs $dhcpIpv4)"
    dhcpIpv6="$(svcs -a | grep dhcp | grep server | grep ipv6 | awk '{ print $1 }')"
    dhcpIpv6="$(traslateEs $dhcpIpv6)"
    apache="$(svcs -a | grep apache24 | awk '{ print $1 }')"
    apache="$(traslateEs $apache)"
    dns="$(svcs -a | grep dns | grep server | awk '{ print $1 }')"
    dns="$(traslateEs $dns)"
    dns="$(svcs -a | grep dns | grep server | awk '{ print $1 }')"
    dns="$(traslateEs $dns)"
    echo "______________________________________"
    echo "Estado                | Servicio"
    echo "--------------------------------------"
    echo "$dns                   | DNS"
    echo "$dhcpIpv4                 | Servidor DHCP ipv4"
    echo "$dhcpIpv6                 | Servidor DHCP ipv6"
    echo "$apache                   | Apache"
}

createService() {
    read -p "Ingresa el nombre de tu servicio: " name
    echo "sleep 10000&" >/lib/svc/method/$name
    chmod +x /lib/svc/method/$name

    cat >/var/svc/manifest/site/$name.xml <<EOL
<?xml version='1.0'?>
<!DOCTYPE service_bundle SYSTEM '/usr/share/lib/xml/dtd/service_bundle.dtd.1'>
<service_bundle type='manifest' name='export'>
  <service name='system/${name}' type='service' version='0'>
    <create_default_instance enabled='true' complete='true'/>
    <single_instance/>
   
    <exec_method name='refresh' type='method' exec=':kill -THAW' timeout_seconds='60'/>
    <exec_method name='start' type='method' exec='/lib/svc/method/${name}' timeout_seconds='60'>
      <method_context>
        <method_credential user='root' group='root' clearance='ADMIN_HIGH' trusted_path='false'/>
      </method_context>
    </exec_method>
    <exec_method name='stop' type='method' exec=':kill' timeout_seconds='60'/>
    <property_group name='general' type='framework'>
      <propval name='action_authorization' type='astring' value='solaris.smf.manage.cron'/>
    </property_group>
    <property_group name='startd' type='framework'>
      <propval name='ignore_error' type='astring' value='core,signal'/>
    </property_group>
    <stability value='Unstable'/>
    <template>
      <common_name>
        <loctext xml:lang='C'>clock daemon (cron)</loctext>
      </common_name>
      <documentation>
        <manpage title='cron' section='8' manpath='/usr/share/man'/>
        <manpage title='crontab' section='1' manpath='/usr/share/man'/>
      </documentation>
    </template>
  </service>
</service_bundle>
EOL

    svcadm restart svc:/system/manifest-import
    sleep 2s
    echo "Servicio creado: "
    svcs -a | grep $name]
    echo ""
    echo "Modifique el script del servicio en  en: /lib/svc/method/$name"
    pressAnyKey
}

configServices() {
    while [ $opcion != "0" ]; do

        clear
        echo "Cargando estados de los servicios..."
        dhcpIpv4="$(svcs -a | grep dhcp | grep server | grep ipv4 | awk '{ print $1 }')"
        dhcpIpv4="$(traslateEs $dhcpIpv4)"
        dhcpIpv6="$(svcs -a | grep dhcp | grep server | grep ipv6 | awk '{ print $1 }')"
        dhcpIpv6="$(traslateEs $dhcpIpv6)"
        apache="$(svcs -a | grep apache24 | awk '{ print $1 }')"
        apache="$(traslateEs $apache)"
        dns="$(svcs -a | grep dns | grep server | awk '{ print $1 }')"
        dns="$(traslateEs $dns)"
        clear
        echo "______________________________________"
        echo "Estado                | Servicio"
        echo "--------------------------------------"
        echo "1.- DNS       $dns"
        echo "2.- DHCP IPV4         | $dhcpIpv4"
        echo "3.- DHCP IPV6         | $dhcpIpv4"
        echo "4.- Apache            | $apache"
        echo ""
        echo "0 Para salir"

        read -p "Eliga una servicio: " opcion
        echo ""
        echo "1.- Activar"
        echo "2.- Desactivar"
        echo ""
        read -p "Elija una acción: " action
        echo "Accioón: $action"
        if [ "$action" = "1" ]; then
            echo "Activando el servicio..."
        else
            echo "Desactivando el servicio..."
        fi
        echo ""
        case "$opcion" in
        1)
            if [ "$action" = "1" ]; then
                svcadm enable svc:/network/http:apache24
            else
                svcadm disable svc:/network/http:apache24
            fi
            pressAnyKey
            ;;
        2)
            if [ "$action" = "1" ]; then
                svcadm enable svc:/network/dhcp/server:ipv4
            else
                svcadm disable svc:/network/dhcp/server:ipv4
            fi
            pressAnyKey
            ;;
        3)
            if [ "$action" = "1" ]; then
                svcadm enable svc:/network/dhcp/server:ipv6
            else
                svcadm disable svc:/network/dhcp/server:ipv6
            fi

            ;;
        4)
            if [ "$action" = "1" ]; then
                svcadm enable svc:/network/http:apache24
            else
                svcadm disable svc:/network/http:apache24
            fi
            pressAnyKey
            ;;
        *)
            echo "Servicio inválido"
            pressAnyKey
            ;;
        esac

    done

}

main() {

    while :; do
        clear
        echo "$(date)                              "
        title "SHELL PROGRAMMING"
        echo "1.- Levantar/Bajar un servicio"
        echo "2.- Crear un servicio"
        echo "3.- Salir"
        echo ""
        echo
        read -p "Elija una opcion: " opcion
        clear
        case "$opcion" in
        1)
            configServices
            pressAnyKey
            ;;
        2)
            createService
            ;;
        3)
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

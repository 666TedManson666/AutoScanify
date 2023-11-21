#!/bin/bash

cat << "BANNER"
        d8888          888              .d8888b.                             d8b  .d888
       d88888          888             d88P  Y88b                            Y8P d88P"
      d88P888          888             Y88b.                                     888
     d88P 888 888  888 888888  .d88b.   "Y888b.    .d8888b  8888b.  88888b.  888 888888 888  888
    d88P  888 888  888 888    d88""88b     "Y88b. d88P"        "88b 888 "88b 888 888    888  888
   d88P   888 888  888 888    888  888       "888 888      .d888888 888  888 888 888    888  888
  d8888888888 Y88b 888 Y88b.  Y88..88P Y88b  d88P Y88b.    888  888 888  888 888 888    Y88b 888
 d88P     888  "Y88888  "Y888  "Y88P"   "Y8888P"   "Y8888P "Y888888 888  888 888 888     "Y88888
                                                                                             888
                                                                                        Y8b d88P
                                                                                         "Y88P"
BANNER


stty -ixon


# Función para borrar la pantalla
function borrarPantalla {
    clear
    mostrarMenu
}

# Función para hacer un escaneo de red
function escaneoRed {
    clear
    echo "Realizando escaneo de red con arp-scan..."
    arp-scan -I ens33 --localnet
    mostrarMenu
}

# Función para escanear una IP introducida
function escanearIP {
  
    read -p "Introduce la dirección IP a escanear: " ip
    echo "Escaneando la IP $ip en busca de puertos abiertos..."
    mkdir $ip
    cd $ip
    mkdir nmap
    #cd namp
    nmap -p- --open -sS --min-rate 5000 -n -Pn $ip -oG /home/tedmanson/tools/$ip/nmap/allPorts
    mostrarMenu
}

# Función para ver la versión de los puertos y scripts de reconocimiento
function verVersionPuertos {
    clear
    echo "Viendo la versión de los puertos y ejecutando scripts de reconocimiento..."
    # Agrega aquí el código para ver la versión de los puertos y ejecutar scripts de reconocimiento
    mostrarMenu
}

# Función para mostrar el menú
function mostrarMenu {
    echo ""
    echo "Opciones del menú:"
    echo "1. Hacer escaneo de red"
    echo "2. Introducir la IP a escanear"
    echo "3. Ver versión de los puertos y scripts de reconocimiento"
    echo "4. Limpiar pantalla"
    echo "5. Salir"
    echo ""
}

# Menú principal
mostrarMenu

while true; do
    read -p "Selecciona una opción: " opcion
    case $opcion in
        1)
            escaneoRed
            ;;
        2)
            escanearIP
            ;;
        3)
            verVersionPuertos
            ;;


        4)
          borrarPantalla
          ;;


        5)
            exit
            ;;
       
        *)
            echo "Opción no válida, por favor selecciona una opción válida."
            ;;
    esac
done










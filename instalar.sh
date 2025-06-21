#!/bin/bash
cd $HOME

# --- Configuración de directorios y archivos ---
SCPdir="/etc/newadm" # Directorio principal para el script
SCPinstal="$HOME/install" # Directorio temporal de instalación
SCPidioma="${SCPdir}/idioma" # Archivo para guardar el idioma seleccionado
SCPusr="${SCPdir}/ger-user" # Directorio para scripts de gestión de usuarios
SCPfrm="/etc/ger-frm" # Directorio para herramientas generales (frm = "ferramentas" - herramientas)
SCPinst="/etc/ger-inst" # Directorio para scripts de instalación de servicios

# --- Instalación de dependencias básicas (gawk y mlocate) ---
# gawk: Necesario para el script 'trans' (traducción)
# mlocate: Para el comando 'locate' usado en la limpieza
[[ $(dpkg --get-selections|grep -w "gawk"|head -1) ]] || apt-get install gawk -y &>/dev/null
[[ $(dpkg --get-selections|grep -w "mlocate"|head -1) ]] || apt-get install mlocate -y &>/dev/null

# --- Limpieza del script actual (self-delete) ---
rm "$(pwd)/$0" &> /dev/null

# --- Función para mostrar mensajes con colores ---
msg () {
BRAN='\033[1;37m' && VERMELHO='\e[31m' && VERDE='\e[32m' && AMARELO='\e[33m'
AZUL='\e[34m' && MAGENTA='\e[35m' && MAG='\033[1;36m' && NEGRITO='\e[1m' && SEMCOR='\e[0m'

case "$1" in
-ne) cor="${VERMELHO}${NEGRITO}" && echo -ne "${cor}${2}${SEMCOR}";;
-ama) cor="${AMARELO}${NEGRITO}" && echo -e "${cor}${2}${SEMCOR}";;
-verm) cor="${AMARELO}${NEGRITO}[!] ${VERMELHO}" && echo -e "${cor}${2}${SEMCOR}";;
-azu) cor="${MAG}${NEGRITO}" && echo -e "${cor}${2}${SEMCOR}";;
-verd) cor="${VERDE}${NEGRITO}" && echo -e "${cor}${2}${SEMCOR}";;
-bra) cor="${BRAN}${NEGRITO}" && echo -ne "${cor}${2}${SEMCOR}";;
-bar2) cor="${AZUL}${NEGRITO}======================================================" && echo -e "${cor}${SEMCOR}";;
-bar) cor="${AZUL}${NEGRITO}========================================" && echo -e "${cor}${SEMCOR}";;
esac
}

# --- Función para obtener la dirección IP del servidor ---
fun_ip () {
MIP=$(ip addr | grep 'inet' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -o -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1)
MIP2=$(wget -qO- ipv4.icanhazip.com)
[[ "$MIP" != "$MIP2" ]] && IP="$MIP2" || IP="$MIP"
}

# --- Función para instalar componentes adicionales ---
inst_components () {
msg -ama "Instalando componentes adicionales..."
# nano: Editor de texto simple
[[ $(dpkg --get-selections|grep -w "nano"|head -1) ]] || apt-get install nano -y &>/dev/null
# bc: Calculadora de línea de comandos (precisión arbitraria)
[[ $(dpkg --get-selections|grep -w "bc"|head -1) ]] || apt-get install bc -y &>/dev/null
# screen: Para gestionar sesiones de terminal
[[ $(dpkg --get-selections|grep -w "screen"|head -1) ]] || apt-get install screen -y &>/dev/null
# python / python3: Para scripts que puedan requerir Python
[[ $(dpkg --get-selections|grep -w "python"|head -1) ]] || apt-get install python -y &>/dev/null
[[ $(dpkg --get-selections|grep -w "python3"|head -1) ]] || apt-get install python3 -y &>/dev/null
# curl: Herramienta para transferir datos con sintaxis URL
[[ $(dpkg --get-selections|grep -w "curl"|head -1) ]] || apt-get install curl -y &>/dev/null
# ufw: Firewall no complicado
[[ $(dpkg --get-selections|grep -w "ufw"|head -1) ]] || apt-get install ufw -y &>/dev/null
# unzip / zip: Para comprimir y descomprimir archivos
[[ $(dpkg --get-selections|grep -w "unzip"|head -1) ]] || apt-get install unzip -y &>/dev/null
[[ $(dpkg --get-selections|grep -w "zip"|head -1) ]] || apt-get install zip -y &>/dev/null
# apache2: Servidor web, si se necesita para alguna función (ej. panel web)
[[ $(dpkg --get-selections|grep -w "apache2"|head -1) ]] || {
 apt-get install apache2 -y &>/dev/null
 # Cambia el puerto predeterminado de Apache de 80 a 81 para evitar conflictos
 sed -i "s;Listen 80;Listen 81;g" /etc/apache2/ports.conf
 service apache2 restart > /dev/null 2>&1 &
}
msg -verd "Componentes instalados."
}

# --- Función para seleccionar el idioma de la interfaz ---
funcao_idioma () {
msg -bar2
msg -azu "Seleccione el idioma para LatamSRC ADM VPS:"
declare -A idioma=( [1]="en English" [2]="fr French" [3]="de German" [4]="it Italian" [5]="pl Polish" [6]="pt Portuguese" [7]="es Spanish" [8]="tr Turkish" )

for ((i=1; i<=12; i++)); do
valor1="$(echo "${idioma[$i]}"|cut -d' ' -f2)"
[[ -z "$valor1" ]] && break
valor1="\033[1;32m[$i] > \033[1;33m$valor1"
    while [[ ${#valor1} -lt 37 ]]; do
       valor1="${valor1} "
    done
echo -ne "$valor1"
let i++
valor2="$(echo "${idioma[$i]}"|cut -d' ' -f2)"
[[ -z "$valor2" ]] && {
   echo -e " "
   break
   }
valor2="\033[1;32m[$i] > \033[1;33m$valor2"
     while [[ ${#valor2} -lt 37 ]]; do
        valor2="${valor2} "
     done
echo -ne "$valor2"
let i++
valor3="$(echo "${idioma[$i]}"|cut -d' ' -f2)"
[[ -z "$valor3" ]] && {
   echo -e " "
   break
   }
valor3="\033[1;32m[$i] > \033[1;33m$valor3"
     while [[ ${#valor3} -lt 37 ]]; do
        valor3="${valor3} "
     done
echo -e "$valor3"
done
msg -bar2
unset selection
while [[ ! "$selection" =~ ^[1-8]$ ]]; do
echo -ne "\033[1;37mIngrese el número de su idioma: \033[0m" && read selection
tput cuu1 && tput dl1
done
pv="$(echo "${idioma[$selection]}"|cut -d' ' -f1)"
[[ ${#id} -gt 2 ]] && id="pt" || id="$pv" # Si $id ya tiene un valor de más de 2 caracteres (ej. "es"), lo mantiene, sino usa el seleccionado.
byinst="true" # Flag para indicar que la instalación es interactiva
}

# --- Mensaje de finalización de la instalación ---
install_fim () {
msg -ama "$(source trans -b pt:${id} "Instalacion Completa, Utilize los Comandos"|sed -e 's/[^a-z -]//ig')" && msg -bar2
echo -e " Para acceder al panel de LatamSRC ADM VPS, use los comandos:"
echo -e "  ${VERDE}menu${SEMCOR}"
echo -e "  ${VERDE}adm${SEMCOR}"
msg -verm "$(source trans -b pt:${id} "Reinicie su servidor para concluir la instalacion"|sed -e 's/[^a-z -]//ig')"
msg -bar2
}

# --- Función de ofuscación (simple) ---
# Esta función parece ser una ofuscación/deofuscación simple usada para la clave.
ofus () {
unset txtofus
number=$(expr length "$1")
for((i=1; i<number+1; i++)); do
txt[$i]=$(echo "$1" | cut -b "$i")
case "${txt[$i]}" in
".") txt[$i]="+";;
"+") txt[$i]=".";;
"1") txt[$i]="@";;
"@") txt[$i]="1";;
"2") txt[$i]="?";;
"?") txt[$i]="2";;
"3") txt[$i]="%";;
"%") txt[$i]="3";;
"/") txt[$i]="K";;
"K") txt[$i]="/";;
esac
txtofus+="${txt[$i]}"
done
echo "$txtofus" | rev # Invierte la cadena
}

# --- Función para mover y dar permisos a archivos de instalación ---
verificar_arq () {
[[ ! -d ${SCPdir} ]] && mkdir -p ${SCPdir}
[[ ! -d ${SCPusr} ]] && mkdir -p ${SCPusr}
[[ ! -d ${SCPfrm} ]] && mkdir -p ${SCPfrm}
[[ ! -d ${SCPinst} ]] && mkdir -p ${SCPinst}

case "$1" in
"menu"|"message.txt") ARQ="${SCPdir}/";; # Archivos del menú
"usercodes") ARQ="${SCPusr}/";; # Archivos de códigos de usuario
"openssh.sh"|"squid.sh"|"dropbear.sh"|"openvpn.sh"|"ssl.sh"|"shadowsocks.sh"|"sockspy.sh"|"PDirect.py"|"PPub.py"|"PPriv.py"|"POpen.py"|"PGet.py") ARQ="${SCPinst}/";; # Scripts de instalación de servicios
*) ARQ="${SCPfrm}/";; # Herramientas generales
esac
mv -f "${SCPinstal}/$1" "${ARQ}/$1"
chmod +x "${ARQ}/$1"
}

# --- Inicio del Script Principal ---
fun_ip # Obtiene la IP del servidor

# Descarga el script de traducción 'trans' (el que analizamos antes)
# Nota: La URL de Dropbox podría no ser permanente.
msg -bar2
wget -O /usr/bin/trans "https://www.dropbox.com/s/l6iqf5xjtjmpdx5/trans?dl=0" &> /dev/null
chmod +x /usr/bin/trans # Da permisos de ejecución al script 'trans'
msg -verd "Herramienta de traducción (trans) instalada."

msg -bar2
msg -ama "[ LATAMSRC ADM VPS - INSTALADOR ]" # Nuevo título
[[ -z "$1" ]] && funcao_idioma || { # Si no se pasa un argumento, pide el idioma, si sí, lo usa como ID de idioma.
[[ ${#1} -gt 2 ]] && funcao_idiado || id="$1"
 }

# --- Funciones de manejo de errores de clave ---
error_fun () {
msg -bar2
msg -verm "$(source trans -b pt:${id} "Esta Chave Era de Outro Servidor Portanto Foi Excluida"|sed -e 's/[^a-z -]//ig') " # Mensaje traducido
msg -verm "La clave proporcionada pertenece a otro servidor y ha sido invalidada." # Mensaje claro
msg -bar2
[[ -d ${SCPinstal} ]] && rm -rf ${SCPinstal} # Limpia el directorio de instalación temporal
exit 1
}

invalid_key () {
msg -bar2
msg -verm "¡Clave Fallida! La clave ingresada es inválida o ha expirado." # Mensaje de clave inválida
msg -bar2
[[ -e "$HOME/lista-arq" ]] && rm "$HOME/lista-arq" # Elimina el archivo de la lista de archivos si existe
exit 1
}

# --- Proceso de verificación de clave ---
while [[ -z "$Key" ]]; do
msg -ne "Ingrese su clave de acceso para LatamSRC ADM VPS: " && read Key
tput cuu1 && tput dl1
done

msg -ne "Verificando clave..."
cd "$HOME"
# Intenta descargar la lista de archivos usando la clave ofuscada y la IP
wget -O "$HOME/lista-arq" "$(ofus "$Key")/$IP" > /dev/null 2>&1 && echo -e "\033[1;32m [Verificado]" || {
   echo -e "\033[1;31m [Fallo]"
   invalid_key # Llama a la función de clave inválida si falla la descarga
   exit
}

# Obtiene la IP del servidor de la clave ofuscada y la guarda
IP=$(ofus "$Key" | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -o -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}') && echo "$IP" > /usr/bin/vendor_code
sleep 1s

# --- Proceso de descarga e instalación de archivos ---
updatedb # Actualiza la base de datos de 'locate'
if [[ -e "$HOME/lista-arq" ]] && [[ ! $(cat "$HOME/lista-arq"|grep "KEY INVALIDA!") ]]; then
   msg -bar2
   msg -verd "¡BIENVENIDO A LATAMSRC ADM VPS!" # Nuevo mensaje de bienvenida
   msg -ama "Gracias por utilizar nuestros servicios."
   REQUEST=$(ofus "$Key"|cut -d'/' -f2) # Extrae el 'request' de la clave ofuscada
   
   [[ ! -d ${SCPinstal} ]] && mkdir -p ${SCPinstal} # Crea el directorio temporal si no existe
   
   pontos="."
   stopping="$(source trans -b pt:${id} "Verificando Atualizacoes"|sed -e 's/[^a-z -]//ig')" # Mensaje traducido
   msg -azu "Iniciando descarga de componentes..."
   
   for arqx in $(cat "$HOME/lista-arq"); do
   msg -verm "${stopping}${pontos}" # Muestra "Verificando Actualizaciones..." con puntos
   wget -O "${SCPinstal}/${arqx}" "${IP}:81/${REQUEST}/${arqx}" > /dev/null 2>&1 && verificar_arq "${arqx}" || error_fun
   tput cuu1 && tput dl1
   pontos+="."
   done
   
   sleep 1s
   msg -bar2
   
   listaarqs="$(locate "lista-arq"|head -1)" && [[ -e "${listaarqs}" ]] && rm "$listaarqs" # Limpia el archivo lista-arq
   
   # Configura el TMOUT (timeout) para la sesión de shell
   cat /etc/bash.bashrc|grep -v '[[ $UID != 0 ]] && TMOUT=15 && export TMOUT' > /etc/bash.bashrc.2
   echo -e '[[ $UID != 0 ]] && TMOUT=15 && export TMOUT' >> /etc/bash.bashrc.2
   mv -f /etc/bash.bashrc.2 /etc/bash.bashrc
   
   # Crea los comandos 'menu' y 'adm'
   echo "${SCPdir}/menu" > /usr/bin/menu && chmod +x /usr/bin/menu
   echo "${SCPdir}/menu" > /usr/bin/adm && chmod +x /usr/bin/adm
   
   inst_components # Llama a la función para instalar componentes adicionales
   echo "$Key" > "${SCPdir}/key.txt" # Guarda la clave en el directorio del script
   
   [[ -d ${SCPinstal} ]] && rm -rf ${SCPinstal} # Limpia el directorio de instalación temporal
   
   [[ ${byinst} = "true" ]] && install_fim # Muestra el mensaje de finalización si fue una instalación interactiva
else
invalid_key # Llama a la función de clave inválida si el archivo lista-arq está mal
fi
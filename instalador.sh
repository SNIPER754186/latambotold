#!/bin/bash

# Nos movemos al directorio HOME del usuario.
cd "$HOME"

# --- Variables de Directorios y Archivos ---
SCPdir="/etc/newadm"       # Directorio principal de la administración.
SCPinstal="$HOME/install"  # Directorio temporal para la instalación.
SCPidioma="${SCPdir}/idioma" # Archivo para guardar la configuración de idioma.
SCPusr="${SCPdir}/ger-user" # Directorio para la gestión de usuarios.
SCPfrm="/etc/ger-frm"      # Directorio para los scripts de funciones/herramientas.
SCPinst="/etc/ger-inst"    # Directorio para los scripts de instalación de servicios.

# --- Instalación de Dependencias Básicas ---
# Asegura que 'gawk' y 'mlocate' estén instalados.
[[ $(dpkg --get-selections|grep -w "gawk"|head -1) ]] || apt-get install gawk -y &>/dev/null
[[ $(dpkg --get-selections|grep -w "mlocate"|head -1) ]] || apt-get install mlocate -y &>/dev/null

# Elimina el propio script después de ejecutarlo (uso cauteloso).
# Esto es común en instaladores para auto-limpieza.
rm "$0" &> /dev/null

# --- Colores para Mensajes ---
# Redefinición de los colores para este script específico.
BRAN='\033[1;37m' && VERMELHO='\e[31m' && VERDE='\e[32m' && AMARELO='\e[33m'
AZUL='\e[34m' && MAGENTA='\e[35m' && MAG='\033[1;36m' &&NEGRITO='\e[1m' && SEMCOR='\e[0m'

# --- Función para Mostrar Mensajes Coloreados ---
# `$1`: Tipo de mensaje (bandera), `$2`: Contenido del mensaje.
msg () {
 case $1 in
  -ne)cor="${VERMELHO}${NEGRITO}" && echo -ne "${cor}${2}${SEMCOR}";;
  -ama)cor="${AMARELO}${NEGRITO}" && echo -e "${cor}${2}${SEMCOR}";;
  -verm)cor="${AMARELO}${NEGRITO}[!] ${VERMELHO}" && echo -e "${cor}${2}${SEMCOR}";;
  -azu)cor="${MAG}${NEGRITO}" && echo -e "${cor}${2}${SEMCOR}";;
  -verd)cor="${VERDE}${NEGRITO}" && echo -e "${cor}${2}${SEMCOR}";;
  -bra)cor="${BRAN}${NEGRITO}" && echo -ne "${cor}${2}${SEMCOR}";;
  -bar2)cor="${AZUL}${NEGRITO}======================================================" && echo -e "${cor}${SEMCOR}";;
  -bar)cor="${AZUL}${NEGRITO}========================================" && echo -e "${cor}${SEMCOR}";;
 esac
}

# --- Función para Obtener la Dirección IP del Servidor ---
fun_ip () {
# Intenta obtener la IP local y la IP pública para una mayor fiabilidad.
MIP=$(ip addr | grep 'inet' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -o -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1)
MIP2=$(wget -qO- ipv4.icanhazip.com)
[[ "$MIP" != "$MIP2" ]] && IP="$MIP2" || IP="$MIP" # Usa la IP pública si es diferente de la local.
}

# --- Función para Instalar Componentes Adicionales ---
inst_components () {
# Instala herramientas y servicios comunes si no están ya presentes.
msg -ama "$(fun_trans "Instalando componentes necesarios...")" # Traducido.
msg -bar
[[ $(dpkg --get-selections|grep -w "nano"|head -1) ]] || apt-get install nano -y &>/dev/null
[[ $(dpkg --get-selections|grep -w "bc"|head -1) ]] || apt-get install bc -y &>/dev/null
[[ $(dpkg --get-selections|grep -w "screen"|head -1) ]] || apt-get install screen -y &>/dev/null
[[ $(dpkg --get-selections|grep -w "python"|head -1) ]] || apt-get install python -y &>/dev/null
[[ $(dpkg --get-selections|grep -w "python3"|head -1) ]] || apt-get install python3 -y &>/dev/null
[[ $(dpkg --get-selections|grep -w "curl"|head -1) ]] || apt-get install curl -y &>/dev/null
[[ $(dpkg --get-selections|grep -w "ufw"|head -1) ]] || apt-get install ufw -y &>/dev/null
[[ $(dpkg --get-selections|grep -w "unzip"|head -1) ]] || apt-get install unzip -y &>/dev/null
[[ $(dpkg --get-selections|grep -w "zip"|head -1) ]] || apt-get install zip -y &>/dev/null
[[ $(dpkg --get-selections|grep -w "apache2"|head -1) ]] || { # Instala Apache2 si no está.
 apt-get install apache2 -y &>/dev/null
 sed -i "s;Listen 80;Listen 81;g" /etc/apache2/ports.conf # Cambia el puerto de escucha de Apache2 a 81.
 service apache2 restart > /dev/null 2>&1 & # Reinicia el servicio.
 }
msg -bar
msg -verd "$(fun_trans "Componentes instalados.")" # Traducido.
}

# --- Función de Selección de Idioma ---
funcao_idioma () {
msg -bar2
declare -A idioma=( [1]="en English" [2]="fr French" [3]="de German" [4]="it Italian" [5]="pl Polish" [6]="pt Portuguese" [7]="es Spanish" [8]="tr Turkish" ) # Corregida la entrada 'Franch'.
for ((i=1; i<=12; i++)); do # El bucle puede ir hasta 8 ya que solo hay 8 idiomas.
valor1="$(echo ${idioma[$i]}|cut -d' ' -f2)"
[[ -z $valor1 ]] && break
valor1="\033[1;32m[$i] > \033[1;33m$valor1"
    while [[ ${#valor1} -lt 37 ]]; do
       valor1=$valor1" "
    done
echo -ne "$valor1"
let i++
valor2="$(echo ${idioma[$i]}|cut -d' ' -f2)"
[[ -z $valor2 ]] && {
   echo -e " "
   break
   }
valor2="\033[1;32m[$i] > \033[1;33m$valor2"
     while [[ ${#valor2} -lt 37 ]]; do
        valor2=$valor2" "
     done
echo -ne "$valor2"
let i++
valor3="$(echo ${idioma[$i]}|cut -d' ' -f2)"
[[ -z $valor3 ]] && {
   echo -e " "
   break
   }
valor3="\033[1;32m[$i] > \033[1;33m$valor3"
     while [[ ${#valor3} -lt 37 ]]; do
        valor3=$valor3" "
     done
echo -e "$valor3"
done
msg -bar2
unset selection
while [[ ${selection} != @([1-8]) ]]; do # Valida la entrada.
echo -ne "\033[1;37mSELECCIONE: ${SEMCOR}" && read selection # Traducido.
tput cuu1 && tput dl1
done
echo ${idioma[$selection]}|cut -d' ' -f1 # Imprime el código de idioma (ej. "es").
pv="$(echo ${idioma[$selection]}|cut -d' ' -f1)" # Guarda el código de idioma.
[[ ${#id} -gt 2 ]] && id="pt" || id="$pv" # Usa 'pt' si el ID es muy largo, si no, el seleccionado.
byinst="true" # Bandera para indicar que la instalación es por el propio instalador.
}

# --- Función de Finalización de Instalación ---
install_fim () {
msg -ama "$(fun_trans "Instalación Completa, Utilice los Comandos")" && msg -bar2 # Traducido.
echo -e " menu / adm" # Comandos para iniciar el menú.
msg -verm "$(fun_trans "Reinicie su servidor para concluir la instalación.")${SEMCOR}" # Traducido.
msg -bar2
}

# --- Función de Ofuscación (Inversa Simple) ---
# Esta función es para ofuscar/desofuscar cadenas de texto mediante sustitución de caracteres y reverso.
ofus () {
unset txtofus
number=$(expr length "$1")
for((i=1; i<$number+1; i++)); do
txt[$i]=$(echo "$1" | cut -b $i)
case ${txt[$i]} in
".")txt[$i]="+";;
"+")txt[$i]=".";;
"1")txt[$i]="@";;
"@")txt[$i]="1";;
"2")txt[$i]="?";;
"?")txt[$i]="2";;
"3")txt[$i]="%";;
"%")txt[$i]="3";;
"/")txt[$i]="K";;
"K")txt[$i]="/";;
esac
txtofus+="${txt[$i]}"
done
echo "$txtofus" | rev # Revierte la cadena final.
}

# --- Función para Verificar y Mover Archivos ---
# Mueve los scripts descargados a sus directorios finales.
# `$1`: Nombre del archivo a mover.
verificar_arq () {
[[ ! -d ${SCPdir} ]] && mkdir ${SCPdir} # Crea el directorio principal si no existe.
[[ ! -d ${SCPusr} ]] && mkdir ${SCPusr} # Crea el directorio de usuarios.
[[ ! -d ${SCPfrm} ]] && mkdir ${SCPfrm} # Crea el directorio de funciones/herramientas.
[[ ! -d ${SCPinst} ]] && mkdir ${SCPinst} # Crea el directorio de scripts de instalación.

case "$1" in
"menu"|"message.txt")ARQ="${SCPdir}/";; # Archivos para el directorio principal.
"usercodes")ARQ="${SCPusr}/";; # Archivos de gestión de usuarios.
"openssh.sh"|"squid.sh"|"dropbear.sh"|"openvpn.sh"|"ssl.sh"|"shadowsocks.sh")ARQ="${SCPinst}/";; # Scripts de instalación de servicios.
"sockspy.sh"|"PDirect.py"|"PPub.py"|"PPriv.py"|"POpen.py"|"PGet.py")ARQ="${SCPinst}/";; # Scripts relacionados con Sockspy.
*)ARQ="${SCPfrm}/";; # Otros archivos (herramientas).
esac
mv -f "${SCPinstal}/$1" "${ARQ}/$1" # Mueve el archivo.
chmod +x "${ARQ}/$1" # Da permisos de ejecución.
}

# --- INICIO DEL SCRIPT PRINCIPAL ---

fun_ip # Obtiene la IP del servidor al inicio.

# Descarga el script de traducción 'trans'.
wget -O /usr/bin/trans https://raw.githubusercontent.com/SNIPER754186/latambotold/refs/heads/LaTamSRC/dropbox/trans &> /dev/null

msg -bar2
msg -ama "[ LATAMSRC ADM VPS - INSTALADOR ]${SEMCOR}" # Branding del instalador.

# Llama a la función de selección de idioma si no se proporciona un idioma como argumento.
[[ $1 = "" ]] && funcao_idioma || {
[[ ${#1} -gt 2 ]] && funcao_idioma || id="$1" # Si el argumento es un código de idioma válido.
 }

# Función para manejar una clave inválida (aquí es una salida simple, pero podría ser más elaborada).
invalid_key () {
msg -verm "Clave de verificación inválida o error al conectar con el repositorio. Saliendo...${SEMCOR}" # Traducido.
exit 1
}

# Simula una verificación de clave o descarga de lista de archivos.
msg -ne "Verificando clave..." # Traducido.
# Descarga la lista de archivos a instalar desde el repositorio de GitHub.
wget -O "$HOME/lista-arq" https://raw.githubusercontent.com/SNIPER754186/latambotold/refs/heads/LaTamSRC/gerador/GERADOR > /dev/null 2>&1 && echo -e "\033[1;32m Verificado${SEMCOR}" || {
   echo -e "\033[1;31m Falló la verificación.${SEMCOR}" # Traducido.
   exit 1 # Sale si la descarga falla.
   }
sleep 1s
updatedb # Actualiza la base de datos de 'locate'.

if [[ -e "$HOME/lista-arq" ]]; then # Si la lista de archivos se descargó correctamente.
   msg -bar2
   msg -ama "$(fun_trans "BIENVENIDO, GRACIAS POR UTILIZAR") (LatamSRC ADM VPS)${SEMCOR}" # Mensaje de bienvenida con branding.
   [[ ! -d ${SCPinstal} ]] && mkdir ${SCPinstal} # Crea el directorio temporal de instalación.
   pontos="." # Para la animación de la barra de progreso.
   stopping="$(fun_trans "Verificando Actualizaciones")" # Mensaje de progreso.
   for arqx in $(cat "$HOME/lista-arq"); do # Itera sobre cada archivo en la lista.
   msg -verm "${stopping}${pontos}" # Muestra el progreso.
   # Descarga el archivo desde GitHub y lo verifica/mueve.
   wget -O "${SCPinstal}/${arqx}" "https://raw.githubusercontent.com/SNIPER754186/latambotold/refs/heads/LaTamSRC/gerador/${arqx}" > /dev/null 2>&1 && verificar_arq "${arqx}" || {
   msg -verm "$(fun_trans "Fallo al descargar") ${arqx}" # Traducido.
   }
   tput cuu1 && tput dl1 # Limpia la línea de progreso.
   pontos+="."
   done
   sleep 1s
   msg -bar2
   listaarqs="$(locate "lista-arq"|head -1)" && [[ -e ${listaarqs} ]] && rm "$listaarqs" # Elimina la lista de archivos.
   # Modifica .bashrc para establecer un TMOUT (timeout de sesión) para usuarios no root.
   cat /etc/bash.bashrc|grep -v '[[ $UID != 0 ]] && TMOUT=15 && export TMOUT' > /etc/bash.bashrc.2
   echo -e '[[ $UID != 0 ]] && TMOUT=15 && export TMOUT' >> /etc/bash.bashrc.2
   mv -f /etc/bash.bashrc.2 /etc/bash.bashrc
   # Crea enlaces simbólicos para los comandos 'menu' y 'adm'.
   echo "${SCPdir}/menu" > /usr/bin/menu && chmod +x /usr/bin/menu
   echo "${SCPdir}/menu" > /usr/bin/adm && chmod +x /usr/bin/adm
   Key="Echo Por LatamSRC" # La clave está hardcodeada en el script.4nth0nySLT
   echo "$Key" > "${SCPdir}/key.txt" # Guarda la clave en un archivo.
   inst_components # Llama a la función para instalar componentes adicionales.
   [[ -d ${SCPinstal} ]] && rm -rf ${SCPinstal} # Limpia el directorio temporal de instalación.
   [[ ${#id} -gt 2 ]] && echo "pt" > ${SCPidioma} || echo "${id}" > ${SCPidioma} # Guarda el idioma seleccionado.
   [[ ${byinst} = "true" ]] && install_fim # Muestra el mensaje de finalización si fue una instalación completa.
else
invalid_key # Si la lista de archivos no se descargó, llama a la función de clave inválida.
fi
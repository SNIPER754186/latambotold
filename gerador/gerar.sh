#!/bin/bash

# --- Configuración Inicial ---
clear # Limpia la pantalla al inicio.

# Define los archivos básicos que se instalarán por defecto.
# Si existe /etc/newadm-instalacao, lee la lista de ahí; de lo contrario, usa una lista predefinida.
[[ -e /etc/newadm-instalacao ]] && BASICINST="$(cat /etc/newadm-instalacao)" || BASICINST="menu PGet.py ports.sh ADMbot.sh message.txt usercodes sockspy.sh POpen.py PPriv.py PPub.py PDirect.py speedtest.py speed.sh utils.sh dropbear.sh apacheon.sh openvpn.sh shadowsocks.sh ssl.sh squid.sh"

IVAR="/etc/http-instas" # Archivo para almacenar información de instalaciones.

# --- Estilos de Interfaz ---
BARRA="\033[1;36m====================================================================\033[0m" # Barra separadora.

# --- Banner de Bienvenida ---
# Muestra un banner con el nuevo branding y la información de instalaciones.
echo -e "$BARRA"
cat << EOF

             LatamSRC ADM VPS - Generador de Claves
             INSTALACIONES PREVIAS: $(cat "$IVAR" 2>/dev/null || echo "N/A")

EOF
# Nota: La línea "$(cat $IVAR)" puede fallar si el archivo no existe.
# Se añade '2>/dev/null || echo "N/A"' para evitar errores si el archivo IVAR no está presente.

SCPT_DIR="/etc/SCRIPT" # Directorio donde se almacenan los scripts para distribuir.
[[ ! -e ${SCPT_DIR} ]] && mkdir -p ${SCPT_DIR} # Crea el directorio si no existe.

INSTA_ARQUIVOS="ADMVPS.zip" # Nombre de un archivo ZIP de instalación (no parece usado directamente en este script).
DIR="/etc/http-shell"       # Directorio donde se gestionan las claves generadas y sus archivos asociados.
LIST="lista-arq"            # Nombre del archivo que contendrá la lista de archivos para una clave.

# --- Función para Obtener la IP Pública del Servidor ---
meu_ip () {
MIP=$(ip addr | grep 'inet' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -o -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1)
MIP2=$(wget -qO- ipv4.icanhazip.com)
[[ "$MIP" != "$MIP2" ]] && IP="$MIP2" || IP="$MIP"
}

# --- Función para Modificar Archivos de Instalación Base (BASICINST) ---
# Permite al usuario seleccionar qué scripts se incluirán en la instalación básica de la clave.
mudar_instacao () {
while [[ ${var[$value]} != 0 ]]; do
# Recarga la lista de BASICINST en cada iteración por si se modificó.
[[ -e /etc/newadm-instalacao ]] && BASICINST="$(cat /etc/newadm-instalacao)" || BASICINST="menu PGet.py ports.sh ADMbot.sh message.txt usercodes sockspy.sh POpen.py PPriv.py PPub.py PDirect.py speedtest.py speed.sh utils.sh dropbear.sh apacheon.sh openvpn.sh shadowsocks.sh ssl.sh squid.sh"
clear
echo -e "$BARRA"
echo -e "MENÚ DE SELECCIÓN DE INSTALACIÓN" # Traducido
echo -e "$BARRA"
echo "[0] - FINALIZAR PROCEDIMIENTO" # Traducido
i=1
for arqx in `ls "${SCPT_DIR}"`; do
[[ "$arqx" = @(gerar.sh|http-server.py) ]] && continue # Ignora estos archivos.
[[ $(echo "$BASICINST"|grep -w "$arqx") ]] && echo "[$i] - [X] - $arqx" || echo "[$i] - [ ] - $arqx" # Marca con [X] si está incluido.
var[$i]="$arqx"
let i++
done
echo -ne "Seleccione el Archivo [Añadir/Eliminar]: " # Traducido
read value
[[ -z "${var[$value]}" ]] && return # Si la selección es vacía, regresa.

# Añade o elimina el archivo de la lista BASICINST.
if [[ $(echo "$BASICINST"|grep -w "${var[$value]}") ]]; then
rm /etc/newadm-instalacao # Elimina el archivo para reescribirlo.
local BASIC=""
  for INSTS in $(echo "$BASICINST"); do
  [[ "$INSTS" = "${var[$value]}" ]] && continue # Si es el archivo seleccionado, lo omite.
  BASIC+="$INSTS " # Reconstruye la lista sin el archivo.
  done
echo "$BASIC" > /etc/newadm-instalacao
else
echo "$BASICINST ${var[$value]}" > /etc/newadm-instalacao # Añade el archivo a la lista.
fi
done
}

# --- Función para Gestionar la Lista de Archivos de una Clave ---
# Crea un directorio para una nueva clave y copia los archivos seleccionados a ella.
fun_list () {
rm ${SCPT_DIR}/*.x.c &> /dev/null # Limpia archivos temporales.
unset KEY
KEY="$1" # La clave generada se pasa como primer argumento.

# Crea el directorio para la nueva clave.
[[ ! -e ${DIR} ]] && mkdir -p ${DIR} # Asegura la creación de DIR si no existe.
[[ ! -e "${DIR}/${KEY}" ]] && mkdir -p "${DIR}/${KEY}"

# Lista archivos disponibles para ser "repasados" (copiados a la clave).
i=0
# VALUE contiene los archivos que siempre deben incluirse, si no están ya en SCP_DIR.
# Esto no es un simple grep, sino una concatenación.
VALUE+="gerar.sh instgerador.sh http-server.py $BASICINST" 
for arqx in `ls "${SCPT_DIR}"`; do
[[ $(echo "$VALUE"|grep -w "${arqx}") ]] && continue # Si el archivo ya está en la lista VALUE, lo ignora.
echo -e "[$i] -> ${arqx}"
arq_list[$i]="${arqx}" # Almacena los archivos en un array.
let i++
done
echo -e "[b] -> INSTALACIÓN ADM BÁSICA" # Opción para instalar el paquete básico. # Traducido
read -p "Elija los Archivos a Repasar (separados por espacio): " readvalue # Traducido.

# Pide el nombre del propietario de la clave.
read -p "Nombre del Usuario (propietario de la Clave): " nombrevalue # Traducido.
[[ -z "$nombrevalue" ]] && nombrevalue="unnamed" # Por defecto 'unnamed'.

# Copia los archivos seleccionados a la carpeta de la clave.
if [[ "$readvalue" = @(b|B) ]]; then
# Si se elige 'b' (Básico), copia todos los archivos de BASICINST.
 arqslist="$BASICINST"
 for arqx in `echo "${arqslist}"`; do
 [[ -e "${DIR}/${KEY}/$arqx" ]] && continue # Salta si el archivo ya existe en la clave.
 cp "${SCPT_DIR}/$arqx" "${DIR}/${KEY}/"
 echo "$arqx" >> "${DIR}/${KEY}/${LIST}" # Añade el archivo a la lista de la clave.
 done
else
# Si se seleccionan archivos específicos por número.
 for arqx in `echo "${readvalue}"`; do
 #UNE ARQ
 [[ -e "${DIR}/${KEY}/${arq_list[$arqx]}" ]] && continue # Salta si el archivo ya existe.
 rm ${SCPT_DIR}/*.x.c &> /dev/null # Limpia temporales.
 cp "${SCPT_DIR}/${arq_list[$arqx]}" "${DIR}/${KEY}/"
 echo "${arq_list[$arqx]}" >> "${DIR}/${KEY}/${LIST}"
 done
echo "TRUE" >> "${DIR}/${KEY}/FERRAMENTA" # Marca la clave como "herramienta" si no es básica.
fi
rm ${SCPT_DIR}/*.x.c &> /dev/null # Limpia temporales.
echo "$nombrevalue" > "${DIR}/${KEY}.name" # Guarda el nombre del propietario.
[[ ! -z $IPFIX ]] && echo "$IPFIX" > "${DIR}/${KEY}/keyfixa" # Guarda IP fija si está definida.

echo -e "$BARRA"
echo -e "¡Clave Activa y Esperando Instalación!" # Traducido
echo -e "$BARRA"
}

# --- Función de Ofuscación (duplicada, considerar eliminar la copia) ---
# Esta es una copia de la función 'ofus' que ya está definida al principio.
# Podría eliminarse esta duplicación.
ofus () {
unset txtofus
number=$(expr length "$1")
for((i=1; i<number+1; i++)); do
txt[$i]=$(echo "$1" | cut -b "$i")
case "${txt[$i]}" in
".")txt[$i]="+";; "+")txt[$i]=".";;
"1")txt[$i]="@";; "@")txt[$i]="1";;
"2")txt[$i]="?";; "?")txt[$i]="2";;
"3")txt[$i]="%";; "%")txt[$i]="3";;
"/")txt[$i]="K";; "K")txt[$i]="/";;
esac
txtofus+="${txt[$i]}"
done
echo "$txtofus" | rev
}

# --- Función para Generar una Clave Aleatoria ---
gerar_key () {
valuekey="$(date | md5sum | head -c10)" # Genera una parte aleatoria de la clave.
valuekey+="$(echo $((RANDOM*10))|head -c 5)" # Añade otra parte aleatoria.
fun_list "$valuekey" # Llama a fun_list para crear los archivos de la clave.
keyfinal=$(ofus "$IP:8888/$valuekey/$LIST") # Ofusca la URL final de la clave.
echo -e "CLAVE: $keyfinal\n¡Generada!" # Muestra la clave generada. # Traducido
echo -e "$BARRA"
read -p "Presione Enter para Finalizar" # Traducido
}

# --- Función para Actualizar Claves Existentes ---
att_gen_key () {
i=0
rm ${SCPT_DIR}/*.x.c &> /dev/null # Limpia temporales.
[[ -z $(ls "$DIR"|grep -v "ERROR-KEY"|grep -v ".name") ]] && { echo "No hay claves para actualizar."; return; } # Traducido.

echo "[$i] Regresar" # Traducido
keys="$keys retorno"
let i++
for arqs in `ls "$DIR"|grep -v "ERROR-KEY"|grep -v ".name"`; do
arqsx=$(ofus "$IP:8888/$arqs/$LIST") # Ofusca la URL de la clave.
if [[ $(cat "${DIR}/${arqs}.name"|grep "GENERADOR") ]]; then # Si es una clave de GENERADOR.
echo -e "\033[1;31m[$i] $arqsx ($(cat "${DIR}/${arqs}.name"))\033[1;32m ($(cat "${DIR}/${arqs}/keyfixa"))\033[0m"
keys="$keys $arqs"
let i++
fi
done
keys=($keys) # Convierte la cadena de claves en un array.
echo -e "$BARRA"
while [[ -z "${keys[$value]}" || -z "$value" ]]; do
read -p "Elija cuál actualizar [t=todos]: " -e -i 0 value # Traducido.
done

[[ "$value" = 0 ]] && return # Si elige 0, regresa.

if [[ "$value" = @(t|T) ]]; then # Si elige 't' (todos)...
i=0
[[ -z $(ls "$DIR"|grep -v "ERROR-KEY"|grep -v ".name") ]] && { echo "No hay claves para actualizar."; return; } # Traducido.
for arqs in `ls "$DIR"|grep -v "ERROR-KEY"|grep -v ".name"`; do
KEYDIR="$DIR/$arqs"
rm "$KEYDIR"/*.x.c &> /dev/null # Limpia temporales.
 if [[ $(cat "${DIR}/${arqs}.name"|grep "GENERADOR") ]]; then # Si es una clave de GENERADOR...
 rm "${KEYDIR}/${LIST}" # Elimina la lista de archivos existente.
   for arqx in `ls "$SCPT_DIR"`; do # Copia todos los archivos de SCP_DIR.
    cp "${SCPT_DIR}/$arqx" "${KEYDIR}/$arqx"
    echo "${arqx}" >> "${KEYDIR}/${LIST}" # Añade a la nueva lista.
    rm ${SCPT_DIR}/*.x.c &> /dev/null
    rm "$KEYDIR"/*.x.c &> /dev/null
   done
 arqsx=$(ofus "$IP:8888/$arqs/$LIST")
 echo -e "\033[1;33m[CLAVE]: $arqsx \033[1;32m(¡ACTUALIZADA!)\033[0m" # Mensaje de actualización. # Traducido
 fi
let i++
done
rm ${SCPT_DIR}/*.x.c &> /dev/null
echo -e "$BARRA"
echo -ne "\033[0m" && read -p "Presione Enter" # Traducido.
return 0
fi

# Si se actualiza una sola clave.
KEYDIR="$DIR/${keys[$value]}"
[[ -d "$KEYDIR" ]] && {
rm "$KEYDIR"/*.x.c &> /dev/null
rm "${KEYDIR}/${LIST}"
  for arqx in `ls "$SCPT_DIR"`; do
  cp "${SCPT_DIR}/$arqx" "${KEYDIR}/$arqx"
  echo "${arqx}" >> "${KEYDIR}/${LIST}"
  rm ${SCPT_DIR}/*.x.c &> /dev/null
  rm "$KEYDIR"/*.x.c &> /dev/null
  done
 arqsx=$(ofus "$IP:8888/${keys[$value]}/$LIST")
 echo -e "\033[1;33m[CLAVE]: $arqsx \033[1;32m(¡ACTUALIZADA!)\033[0m" # Mensaje de actualización. # Traducido
 read -p "Presione Enter" # Traducido.
 rm ${SCPT_DIR}/*.x.c &> /dev/null
}
}

# --- Función para Remover Claves ---
remover_key () {
i=0
[[ -z $(ls "$DIR"|grep -v "ERROR-KEY"|grep -v ".name") ]] && { echo "No hay claves para remover."; return; } # Traducido.
echo "[$i] Regresar" # Traducido
keys="$keys retorno"
let i++
for arqs in `ls "$DIR"|grep -v "ERROR-KEY"|grep -v ".name"`; do
arqsx=$(ofus "$IP:8888/$arqs/$LIST")
if [[ ! -e "${DIR}/${arqs}/used.date" ]]; then
echo -e "\033[1;32m[$i] $arqsx ($(cat "${DIR}/${arqs}.name"))\033[1;33m (¡ESPERANDO USO!)\033[0m" # Traducido
else
echo -e "\033[1;31m[$i] $arqsx ($(cat "${DIR}/${arqs}.name"))\033[1;33m (USADA: $(cat "${DIR}/${arqs}/used.date") IP: $(cat "${DIR}/${arqs}/used"))\033[0m" # Traducido
fi
keys="$keys $arqs"
let i++
done
keys=($keys)
echo -e "$BARRA"
while [[ -z "${keys[$value]}" || -z "$value" ]]; do
read -p "Elija cuál remover: " -e -i 0 value # Traducido
done
[[ -d "$DIR/${keys[$value]}" ]] && rm -rf "$DIR/${keys[$value]}"* || return # Elimina la clave y sus archivos.
}

# --- Función para Remover Claves Usadas (por fecha) ---
remover_key_usada () {
i=0
[[ -z $(ls "$DIR"|grep -v "ERROR-KEY"|grep -v ".name") ]] && { echo "No hay claves para limpiar."; return; } # Traducido.
for arqs in `ls "$DIR"|grep -v "ERROR-KEY"|grep -v ".name"`; do
arqsx=$(ofus "$IP:8888/$arqs/$LIST")
 if [[ -e "${DIR}/${arqs}/used.date" ]]; then # Si la clave ha sido usada...
  if [[ $(ls -l -c "${DIR}/${arqs}/used.date"|cut -d' ' -f7) != $(date|cut -d' ' -f3) ]]; then
  rm -rf "${DIR}/${arqs}"* # Si la fecha de uso es diferente a la actual, la elimina.
  echo -e "\033[1;31m[CLAVE]: $arqsx \033[1;32m(¡REMOVIDA!)\033[0m" # Traducido
  else
  echo -e "\033[1;32m[CLAVE]: $arqsx \033[1;32m(¡DENTRO DE LA VALIDEZ!)\033[0m" # Traducido
  fi
 else # Si la clave no ha sido usada.
 echo -e "\033[1;32m[CLAVE]: $arqsx \033[1;32m(¡DENTRO DE LA VALIDEZ!)\033[0m" # Traducido
 fi
let i++
done
echo -e "$BARRA"
echo -ne "\033[0m" && read -p "Presione Enter" # Traducido.
}

# --- Función para Iniciar/Detener el Generador de Claves (Servidor HTTP) ---
start_gen () {
PIDGEN=$(ps x|grep -v grep|grep "http-server.sh")
if [[ ! $PIDGEN ]]; then
screen -dmS generador /bin/http-server.sh -start # Inicia el servidor HTTP en una sesión screen.
# screen -dmS generador /bin/http-server-pass.sh -start # Línea comentada para otro tipo de servidor.
echo -e "\033[1;32mGenerador de Claves INICIADO.${SEMCOR}" # Traducido.
else
killall http-server.sh # Detiene el servidor HTTP.
# killall http-server-pass.sh # Detiene el otro servidor.
echo -e "\033[1;31mGenerador de Claves DETENIDO.${SEMCOR}" # Traducido.
fi
}

# --- Función para Cambiar el Mensaje de Bienvenida ---
message_gen () {
read -p "NUEVO MENSAJE: " MSGNEW # Pide el nuevo mensaje. # Traducido
echo "$MSGNEW" > "${SCPT_DIR}/message.txt" # Guarda el mensaje en el archivo.
echo -e "$BARRA"
echo -e "\033[1;32mMensaje actualizado correctamente.${SEMCOR}" # Traducido.
}

# --- Función para Actualizar la Lista de IPs de Servidores de Claves ---
# Esto parece ser para una lista de servidores de keys activos.
rmv_iplib () {
echo -e "¡SERVIDORES DE CLAVES ACTIVOS!" # Traducido
rm /var/www/html/newlib && touch /var/www/html/newlib # Crea/limpia el archivo newlib.
rm ${SCPT_DIR}/*.x.c &> /dev/null # Limpia temporales.
[[ -z $(ls "$DIR"|grep -v "ERROR-KEY"|grep -v ".name") ]] && { echo "No hay servidores de claves para listar."; return; } # Traducido.

for arqs in `ls "$DIR"|grep -v "ERROR-KEY"|grep -v ".name"`; do
if [[ $(cat "${DIR}/${arqs}.name"|grep "GENERADOR") ]]; then
var=$(cat "${DIR}/${arqs}.name")
ip=$(cat "${DIR}/${arqs}/keyfixa")
echo -ne "\033[1;31m[USUARIO]:(\033[1;32m${var%%[*}\033[1;31m) \033[1;33m[GENERADOR]:\033[1;32m ($ip)\033[0m" # Traducido.
echo "$ip" >> /var/www/html/newlib && echo -e " \033[1;36m[¡ACTUALIZADO!]" # Añade la IP a newlib. # Traducido
fi
done
echo "104.238.135.147" >> /var/www/html/newlib # Añade una IP fija a la lista.
echo -e "$BARRA"
read -p "Presione Enter" # Traducido.
}

# --- Ejecución del Menú Principal del Generador de Claves ---
meu_ip # Obtiene la IP del servidor.

unset PID_GEN
PID_GEN=$(ps x|grep -v grep|grep "http-server.sh") # Verifica si el servidor HTTP está corriendo.
[[ ! $PID_GEN ]] && PID_GEN="\033[1;31moffline" || PID_GEN="\033[1;32monline" # Estado del generador. # Traducido.

echo -e "$BARRA"
echo -e "Directorio de Archivos a Distribuir: \033[1;31m${SCPT_DIR}\033[0m" # Traducido.
echo -e "$BARRA"
echo -e "[1] = GENERAR UNA CLAVE ALEATORIA" # Traducido.
echo -e "[2] = VER/ELIMINAR CLAVES" # Traducido.
echo -e "[3] = LIMPIAR CLAVES USADAS (por fecha)" # Traducido.
echo -e "[4] = ALTERAR ARCHIVOS DE INSTALACIÓN BÁSICA" # Traducido.
echo -e "[5] = INICIAR/DETENER GENERADOR DE CLAVES ($PID_GEN)\033[0m" # Traducido.
echo -e "[6] = VER REGISTRO (LOG) DEL GENERADOR" # Traducido.
echo -e "[7] = CAMBIAR MENSAJE DE BIENVENIDA" # Traducido.
echo -e "[0] = SALIR" # Traducido.
echo -e "$BARRA"

while [[ ${varread} != @([0-8]) ]]; do # Bucle para validar la opción.
read -p "Opción: " varread # Traducido.
done
echo -e "$BARRA"

# Ejecuta la función según la opción seleccionada.
if [[ ${varread} = 0 ]]; then
exit
elif [[ ${varread} = 1 ]]; then
gerar_key
elif [[ ${varread} = 2 ]]; then
remover_key
elif [[ ${varread} = 3 ]]; then
remover_key_usada
elif [[ ${varread} = 4 ]]; then
mudar_instacao
elif [[ ${varread} = 5 ]]; then
start_gen
elif [[ ${varread} = 6 ]]; then
echo -ne "\033[1;36m"
cat /etc/gerar-sh-log 2>/dev/null || echo "No hay registro (log) en este momento." # Traducido.
echo -ne "\033[0m" && read -p "Presione Enter" # Traducido.
elif [[ ${varread} = 7 ]]; then
message_gen
fi

# Llama al propio script (o a un script 'gerar.sh' en /usr/bin) recursivamente.
# Esto hace que el menú se muestre de nuevo después de cada operación.
# Se asume que /usr/bin/gerar.sh es este mismo script o un menú principal.
/usr/bin/gerar.sh
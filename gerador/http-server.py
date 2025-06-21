#!/bin/bash

# --- Archivos de Configuración ---
IVAR="/etc/http-instas" # Archivo para contar las instalaciones realizadas.

# --- Función para Remover Claves Usadas (por Tarea Programada) ---
# Esta función limpia las claves que ya han sido usadas y cuya validez expiró (generalmente al día siguiente).
remover_key_usada () {
local DIR="/etc/http-shell" # Directorio donde se almacenan las claves generadas.
i=0
# Si no hay directorios de claves (ignorando errores y nombres específicos), la función regresa.
[[ -z $(ls "$DIR"|grep -v "ERROR-KEY"|grep -v ".name") ]] && return

for arqs in `ls "$DIR"|grep -v "ERROR-KEY"|grep -v ".name"`; do
 if [[ -e "${DIR}/${arqs}/used.date" ]]; then # Si la clave tiene un archivo 'used.date' (indicando que fue usada)...
  # Compara la fecha de uso con la fecha actual del día.
  if [[ $(ls -l -c "${DIR}/${arqs}/used.date"|cut -d' ' -f7) != $(date|cut -d' ' -f3) ]]; then
  rm -rf "${DIR}/${arqs}"* # Si la fecha es diferente (es un día posterior), elimina la clave.
  fi
 fi
let i++
done
}

# --- Función para Determinar la IP Pública del Servidor ---
# Obtiene la IP pública del servidor. Si ya está guardada en /etc/MEU_IP, la lee de ahí;
# de lo contrario, la detecta y la guarda.
fun_ip () {
if [[ ! -e /etc/MEU_IP ]]; then
local MIP=$(ip addr | grep 'inet' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -o -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1)
local MIP2=$(wget -qO- ipv4.icanhazip.com)
[[ "$MIP" != "$MIP2" ]] && IP="$MIP2" || IP="$MIP"
echo "$IP" > /etc/MEU_IP # Guarda la IP detectada.
echo "$IP"
else
echo "$(cat /etc/MEU_IP)" # Lee la IP del archivo.
fi
}

# --- Función para Escuchar Conexiones (Modo Servidor) ---
# Este es el bucle principal del servidor. Escucha en el puerto 8888.
listen_fun () {
local PORTA="8888" # Puerto en el que el servidor HTTP escuchará.
local PROGRAMA="/bin/http-server.sh" # Este mismo script se ejecuta como manejador.
# Bucle infinito que escucha conexiones en el puerto 8888 y las redirige a server_fun.
# nc.traditional: Netcat en modo escucha (-l) en el puerto (-p) y ejecuta un programa (-e) para cada conexión.
# Esto no es un servidor HTTP robusto, es un servidor simple para servir archivos.
while true; do nc.traditional -l -p "$PORTA" -e "$PROGRAMA"; done
}

# --- Función Principal del Servidor HTTP ---
# Procesa las peticiones HTTP entrantes, verifica la clave y sirve los archivos.
server_fun () {
DIR="/etc/http-shell" # Directorio base donde se almacenan las claves generadas y sus archivos.
if [[ ! -d "$DIR" ]]; then mkdir -p "$DIR"; fi # Crea el directorio si no existe.

read URL # Lee la primera línea de la petición HTTP (que contiene la URL solicitada).
# Extrae la KEY, el ARQ (nombre de la lista de archivos), la IP del usuario (USRIP) y el REQ de la URL.
# Se usa 'cut' para parsear la URL.
KEY=$(echo "$URL"|cut -d' ' -f2|cut -d'/' -f2) && [[ -z "$KEY" ]] && KEY="ERRO" # La clave identificadora.
ARQ=$(echo "$URL"|cut -d' ' -f2|cut -d'/' -f3)  && [[ -z "$ARQ" ]] && ARQ="ERRO" # El nombre de la lista de archivos (ej. 'lista-arq').
USRIP=$(echo "$URL"|cut -d' ' -f2|cut -d'/' -f4) && [[ -z "$USRIP" ]] && USRIP="ERRO" # La IP del usuario que hace la petición.
REQ=$(echo "$URL"|cut -d' ' -f2|cut -d'/' -f5) && [[ -z "$REQ" ]] && REQ="ERRO" # Otro componente de la URL, quizás un request ID.

# Muestra información de depuración en STDERR (visible si no se redirige la salida).
echo "KEY: $KEY" >&2
echo "LISTA: $ARQ" >&2
echo "IP USUARIO: $USRIP" >&2 # Traducido.
echo "REQ: $REQ" >&2

DIRETORIOKEY="$DIR/$KEY" # Ruta completa al directorio de la clave específica.
LISTADEARQUIVOS="$DIRETORIOKEY/$ARQ" # Ruta completa al archivo de lista de archivos dentro de la clave.

# --- Lógica de Verificación de Clave y Archivos ---
STATUS_NUMBER="404" # Código de estado HTTP por defecto (No Encontrado).
STATUS_NAME="Not Found" # Nombre de estado HTTP por defecto.
ENV_ARQ="False" # Bandera para indicar si se debe enviar el archivo.
FILE="${DIR}/ERROR-KEY" # Archivo por defecto para el contenido de error.
echo "CLAVE INVÁLIDA O NO ENCONTRADA" > "${FILE}" # Mensaje de error por defecto. # Traducido.

if [[ -d "$DIRETORIOKEY" ]]; then # Paso 1: Verifica si el directorio de la clave existe.
  if [[ -e "$LISTADEARQUIVOS" ]]; then # Paso 2: Verifica si el archivo de lista de archivos existe dentro de la clave.
    # Si la clave y la lista existen, la clave es potencialmente válida.
    FILE="$LISTADEARQUIVOS" # El archivo a enviar es la lista de archivos.
    STATUS_NUMBER="200"     # Código HTTP: OK.
    STATUS_NAME="Found"     # Nombre de estado: Encontrado.
    ENV_ARQ="True"          # Se debe enviar el archivo.
  fi

  if [[ -e "$DIRETORIOKEY/FERRAMENTA" ]]; then # Paso 3: Verifica si es una clave de "HERRAMIENTA".
    if [[ "$USRIP" != "ERRO" ]]; then # Si es una clave de HERRAMIENTA, el IP del usuario NO debe ser enviado.
      # Si el IP se envía con una clave de HERRAMIENTA, es un uso incorrecto.
      FILE="${DIR}/ERROR-KEY"
      echo "¡CLAVE DE HERRAMIENTA! IP DE USUARIO NO PERMITIDO." > "${FILE}" # Traducido.
      ENV_ARQ="False" # No se envía el archivo real.
    fi
  else # Si no es una clave de HERRAMIENTA, entonces se asume que es una clave de INSTALACIÓN.
    if [[ "$USRIP" = "ERRO" ]]; then # Si es una clave de INSTALACIÓN, el IP del usuario DEBE ser enviado.
      # Si el IP no se envía con una clave de INSTALACIÓN, es un uso incorrecto.
      FILE="${DIR}/ERROR-KEY"
      echo "¡CLAVE DE INSTALACIÓN! IP DE USUARIO REQUERIDO." > "${FILE}" # Traducido.
      ENV_ARQ="False" # No se envía el archivo real.
    fi
  fi
else
# Si el directorio de la clave no existe (KEY INVALIDA).
  FILE="${DIR}/ERROR-KEY"
  echo "¡CLAVE INVÁLIDA O NO ENCONTRADA!" > "${FILE}" # Mensaje de error general. # Traducido.
  STATUS_NUMBER="404" # Se mantiene el 404.
  STATUS_NAME="Not Found"
  ENV_ARQ="False"
fi

# --- Envío de la Respuesta HTTP al Cliente ---
# Se construye la cabecera HTTP y se concatena el contenido del archivo FILE.
cat << EOF
HTTP/1.1 $STATUS_NUMBER - $STATUS_NAME
Date: $(date)
Server: LatamSRC-HTTP-Server # Nuevo branding del servidor.
Content-Length: $(wc --bytes "$FILE" | cut -d " " -f1)
Connection: close
Content-Type: text/html; charset=utf-8

$(cat "$FILE")
EOF

# --- Lógica Post-Envío (Registro y Limpieza) ---
if [[ "$ENV_ARQ" != "True" ]]; then exit 0; fi # Si no se envió un archivo válido, finaliza la petición.

# Registra el uso de la clave si aún no ha sido usada.
if [[ -z $(cat "$DIRETORIOKEY/used" 2>/dev/null) ]]; then
# at now + 1440 min <<< "rm -rf ${DIRETORIOKEY}*" # Línea para agendar eliminación, comentada en el original.
echo "$USRIP" > "$DIRETORIOKEY/used" # Registra la IP del usuario.
echo "USADA: $(date |cut -d' ' -f3,4)" > "$DIRETORIOKEY/used.date" # Registra la fecha de uso. # Traducido.
fi

# Verifica si la clave fija está siendo usada por la IP correcta (si aplica).
if [[ -e "$DIRETORIOKEY/keyfixa" ]] && [[ "$(cat "$DIRETORIOKEY/keyfixa")" != "$USRIP" ]]; then
  # IP inválida, bloquea la instalación.
  log="/etc/gerar-sh-log"
  echo "USUARIO: $(cat "$DIRETORIOKEY.name") IP FIJA: $(cat "$DIRETORIOKEY/keyfixa") USÓ IP: $USRIP" >> "$log" # Traducido.
  echo "¡SU CLAVE FIJA HA SIDO BLOQUEADA!" >> "$log" # Traducido.
  echo "--------------------------------------------------------------------" >> "$log"
  rm -rf "${DIRETORIOKEY}"* # Elimina la clave y sus archivos.
  exit 0 # CLAVE INVÁLIDA, finaliza la petición.
fi

# --- Proceso de Distribución de Archivos ---
# Copia los archivos de la clave al directorio web (/var/www/html).
# Este proceso se ejecuta en segundo plano.
(
# Asegura la existencia de los directorios de servicio web.
mkdir -p /var/www/"$KEY"
mkdir -p /var/www/html/"$KEY"

TIME="20+" # Tiempo base para el sleep (20 segundos).
  for arqs in `cat "$FILE"`; do
  cp "$DIRETORIOKEY/$arqs" /var/www/html/"$KEY"/
  cp "$DIRETORIOKEY/$arqs" /var/www/"$KEY"/
  TIME+="1+" # Añade 1 segundo por cada archivo copiado.
  done
TIME=$(echo "${TIME}0"|bc) # Calcula el tiempo total de espera.
sleep "${TIME}s" # Espera un tiempo antes de limpiar.

# Limpia los archivos copiados del directorio web después de un tiempo.
if [[ -d /var/www/"$KEY" ]]; then rm -rf /var/www/"$KEY"; fi
if [[ -d /var/www/html/"$KEY" ]]; then rm -rf /var/www/html/"$KEY"; fi

# Incrementa el contador de instalaciones realizadas.
num=$(cat "$IVAR" 2>/dev/null) # Lee el contador.
if [[ -z "$num" ]]; then num=0; fi # Si el archivo está vacío, inicializa en 0.
let num++ # Incrementa el contador.
echo "$num" > "$IVAR" # Guarda el nuevo contador.

# Llama a la función para limpiar las claves usadas.
remover_key_usada
) & > /dev/null # Ejecuta todo el bloque en segundo plano y redirige su salida.
}

# --- Punto de Entrada del Script ---
# El script se ejecuta en modo "servidor" o "cliente" dependiendo de los argumentos.
# Si se pasan argumentos como '-start', '-s', '-iniciar', etc., el script actúa como servidor.
# De lo contrario, actúa como cliente (procesa una única petición).
[[ "$1" = @(-[Ss]tart|-[Ss]|-[Ii]niciar) ]] && listen_fun && exit 0
[[ "$1" = @(-[Ii]stall|-[Ii]|-[Ii]stalar) ]] && listen_fun && exit 0

# Si no se pasan argumentos de inicio de servidor, se asume que está procesando una petición.
server_fun
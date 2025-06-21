#!/bin/bash

# --- Variables de Directorio ---
IVAR="/etc/http-instas" # Archivo para almacenar la clave o información de instalación
SCPT_DIR="/etc/SCRIPT"   # Directorio para almacenar scripts generales

# --- Eliminación del propio script (auto-destrucción) ---
# Esto es común en scripts de instalación/actualización.
rm "$(pwd)/$0"

# --- Función de Ofuscación/Deofuscación ---
# Esta función realiza una simple sustitución de caracteres y luego invierte la cadena.
# Se usa para codificar/decodificar la clave de actualización.
ofus () {
    unset txtofus
    number=$(expr length "$1") # Obtiene la longitud de la cadena de entrada
    for((i=1; i<number+1; i++)); do
        txt[$i]=$(echo "$1" | cut -b "$i") # Extrae cada carácter
        case "${txt[$i]}" in
            ".")txt[$i]="+";; "+")txt[$i]=".";;
            "1")txt[$i]="@";; "@")txt[$i]="1";;
            "2")txt[$i]="?";; "?")txt[$i]="2";;
            "3")txt[$i]="%";; "%")txt[$i]="3";;
            "/")txt[$i]="K";; "K")txt[$i]="/";;
        esac
        txtofus+="${txt[$i]}" # Concatena el carácter modificado
    done
    echo "$txtofus" | rev # Invierte la cadena resultante
}

# --- Función para Verificar y Mover Archivos Descargados ---
# Mueve los archivos descargados a sus ubicaciones finales y les da permisos de ejecución.
veryfy_fun () {
    # Crea los directorios si no existen
    [[ ! -d ${IVAR} ]] && touch ${IVAR} # En este contexto, IVAR parece ser un archivo, no un directorio.
                                     # Si realmente es un directorio, debería ser 'mkdir -p ${IVAR}'
                                     # Si es un archivo, 'touch' es correcto.
    [[ ! -d ${SCPT_DIR} ]] && mkdir -p ${SCPT_DIR} # Crea el directorio de scripts

    unset ARQ # Limpia la variable de directorio de destino

    # Determina el directorio de destino basado en el nombre del archivo
    case "$1" in
        "gerar.sh")ARQ="/usr/bin/";; # El script 'gerar.sh' va a /usr/bin
        "http-server.py")ARQ="/bin/";; # El servidor HTTP va a /bin
        *)ARQ="${SCPT_DIR}/";; # Otros scripts van al directorio de scripts general
    esac

    # Mueve el archivo y le da permisos de ejecución
    mv -f "$HOME/$1" "${ARQ}/$1"
    chmod +x "${ARQ}/$1"
}

# --- Banner de Bienvenida y Solicitud de Clave ---
echo -e "\033[1;31m--------------------------------------------------------------------\033[0m"
echo -e "\033[1;31m------------------\033[0m \033[1;33mLatamSRC ADM VPS - ACTUALIZADOR\033[0m \033[1;31m------------\033[0m" # Nuevo branding
echo -e "\033[1;31m--------------------------------------------------------------------\033[0m"
read -p "INTRODUZCA SU CLAVE DE ACTUALIZACIÓN: " Key # Pide la clave de actualización
echo -e "\033[1;31m--------------------------------------------------------------------\033[0m"

# Verifica si la clave fue ingresada
[[ -z "$Key" ]] && { # Usamos -z para verificar si la variable está vacía
    echo -e "\033[1;31m--------------------------------------------------------------------\033[0m"
    echo -e "\033[1;33m¡Clave inválida o no proporcionada!" # Mensaje más claro
    echo -e "\033[1;31m--------------------------------------------------------------------\033[0m"
    exit 1 # Sale del script
}

# --- Función para Obtener la IP Pública ---
meu_ip () {
    MIP=$(ip addr | grep 'inet' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -o -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1)
    MIP2=$(wget -qO- ipv4.icanhazip.com) # Método más fiable para obtener IP externa
    [[ "$MIP" != "$MIP2" ]] && IP="$MIP2" || IP="$MIP"
    echo "$IP" > /usr/bin/vendor_code # Guarda la IP en un archivo
}

# Ejecuta la función para obtener la IP
meu_ip

echo -e "\033[1;33mVerificando clave y lista de archivos... "
cd "$HOME"

# Intenta descargar la lista de archivos desde el servidor de claves
# La URL se construye ofuscando la clave, añadiendo la IP del servidor.
# Ejemplo: http://<IP_Servidor_Keygen>:81/<request_de_key>/<IP_Cliente>
wget -O "$HOME/lista-arq" "$(ofus "$Key")/$IP" > /dev/null 2>&1

# Extrae la IP del servidor de la clave ofuscada nuevamente
# Esto parece redundante ya que 'meu_ip' ya la obtuvo, pero se mantiene por la estructura original.
IP=$(ofus "$Key" | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -o -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')

sleep 1s # Pequeña pausa

# --- Lógica de Actualización ---
# Verifica si la descarga de 'lista-arq' fue exitosa y no contiene el mensaje "KEY INVALIDA!"
if [[ -e "$HOME/lista-arq" ]] && [[ ! $(cat "$HOME/lista-arq" | grep "KEY INVALIDA!") ]]; then
    REQUEST=$(ofus "$Key" |cut -d'/' -f2) # Extrae el 'request' (parte de la ruta) de la clave

    # Itera a través de cada archivo listado en 'lista-arq' y lo descarga
    for arqx in $(cat "$HOME/lista-arq"); do
        echo -ne "\033[1;33mDescargando archivo: \033[1;36m[$arqx] " # Mensaje de descarga con branding
        # Descarga el archivo: ${IP}:81/${REQUEST}/${arqx}
        # Ejemplo: http://<IP_Servidor_Archivos>:81/<request_de_key>/<nombre_archivo>
        wget -O "$HOME/$arqx" "${IP}:81/${REQUEST}/${arqx}" > /dev/null 2>&1 && \
        echo -e "\033[1;32m- Recibido con éxito!" || \
        echo -e "\033[1;31m- ¡Falla (no recibido!)"
        
        # Si el archivo se descargó, llama a 'veryfy_fun' para moverlo y darle permisos
        [[ -e "$HOME/$arqx" ]] && veryfy_fun "$arqx"
    done

    # --- Post-descarga y configuración ---
    # Descarga e instala el script 'trans' (traductor) si no existe
    [[ ! -e /usr/bin/trans ]] && wget -O /usr/bin/trans https://raw.githubusercontent.com/SNIPER754186/latambotold/refs/heads/LaTamSRC/dropbox/trans &> /dev/null
    chmod +x /usr/bin/trans # Asegura que sea ejecutable

    # Renombra 'http-server.py' a 'http-server.sh' y le da permisos (si se descargó)
    mv -f /bin/http-server.py /bin/http-server.sh &> /dev/null
    chmod +x /bin/http-server.sh &> /dev/null

    # Instala o asegura la instalación de herramientas adicionales
    apt-get install bc -y &>/dev/null
    apt-get install screen -y &>/dev/null
    apt-get install nano -y &>/dev/null
    apt-get install curl -y &>/dev/null
    apt-get install netcat -y &>/dev/null
    
    # Configuración de Apache2 (si se instaló)
    apt-get install apache2 -y &>/dev/null # Asegura que Apache2 esté instalado
    sed -i "s;Listen 80;Listen 81;g" /etc/apache2/ports.conf # Cambia el puerto de Apache a 81
    service apache2 restart > /dev/null 2>&1 & # Reinicia Apache

    # Guarda la clave en /etc/key-gerador
    IVAR2="/etc/key-gerador"
    echo "$Key" > "$IVAR2"

    # Elimina el archivo temporal de la lista de archivos descargados
    rm "$HOME/lista-arq"

else
    # --- Clave Inválida ---
    echo -e "\033[1;31m--------------------------------------------------------------------\033[0m"
    echo -e "\033[1;33m¡Clave Invalida o no se pudo acceder a la lista de archivos!${NOCOLOR}" # Mensaje de error de clave
    echo -e "\033[1;31m--------------------------------------------------------------------\033[0m"
fi

# --- Mensaje de Finalización ---
echo -e "\033[1;31m--------------------------------------------------------------------\033[0m"
echo -e "\033[1;31m-------------------\033[0m \033[1;33mACTUALIZACIÓN DE LatamSRC ADM VPS FINALIZADA\033[0m \033[1;31m-------------------------\033[0m" # Nuevo branding
echo -e "\033[1;31m--------------------------------------------------------------------\033[0m"
sleep 3
exit 0 # Salida exitosa
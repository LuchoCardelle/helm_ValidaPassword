#!/bin/bash
set -e


###########################################################
#       --HELP

# Función para mostrar ayuda
show_help() {
  echo "Uso: helm ValidaPassword [solo path del archivo values.yaml]"
  echo "ejemplo : helm ValidaPassword /chart/"
  echo
  echo "Opciones:"
  echo "  --help        Muestra esta ayuda"
  echo "  --version     Muestra la versión del plugin"
  echo
  # Añade aquí más opciones según sea necesario
}

# Comprobar si se ha pasado el argumento --help
if [[ "$1" == "--help" ]]; then
  show_help
  exit 0
fi

# Comprobar si se ha pasado el argumento --version
if [[ "$1" == "--version" ]]; then
  echo "ValidaPassword versión 0.1.0"
  echo
  exit 0
fi

###########################################################
#       START

# Verifica que se haya proporcionado un archivo de Helm Chart
if [ "$#" -ne 1 ]; then
    echo "Usage: ValidaPassword <chart-path>"
    exit 1
fi

CHART_PATH=$1

validate() {
  min_length=8
  if [[ $(echo $COUNT) -lt $min_length ]]; then
    echo "a. Longitud mínima del password: 8 caracteres. [chequear] $KEY"
    exit 1
  fi

  if ! [[ $VALUE =~ [A-Z] ]]; then
    echo "b. Al menos una letra en mayúscula. [chequear] $KEY"
    exit 1
  fi

  if ! [[ $VALUE =~ [a-z] ]]; then
    echo "c. Al menos una letra en minúscula. [chequear] $KEY"
    exit 1
  fi

  if ! [[ $VALUE =~ [0-9] ]]; then
    echo "d. Al menos un dígito. [chequear] $KEY"
    exit 1
  fi

  if ! [[ $VALUE =~ [\@\#\$\%\^\&\*\(\)\_\+\-\=\{\}\[\]\|\:\;\"\'\<\>\,\.\?\/] ]]; then
    echo "e. Al menos un caracter especial. [chequear] $KEY"
    echo "opcoines : [\@\#\$\%\^\&\*\(\)\_\+\-\=\{\}\[\]\|\:\;\"\'\<\>\,\.\?\/]"
    exit 1
  fi
}

# Obtener el archivo values.yaml del chart
VALUES_FILE() {
	helm show values ws/ch5 | yq | grep -oP '^[^:]+:.*' | grep -Eo '.*:(.*)'
}

# Función para validar contraseñas
validate_passwords() {
  local values_file=$1
  local invalid=false

  # Buscar claves que contengan passwords, pwd, pass, o credentials
  VALUES_FILE | while IFS= read -r line; do
    KEY=$(echo "$line" | awk -F':' '{print $1}' | xargs)
    VALUE=$(echo "$line" | awk -F':' '{print $2}' | xargs)
    COUNT=$(echo $VALUE | sed 's/ //g' | wc -m)

    if [[ $KEY =~ passwords|pwd|pass|credentials ]]; then
	validate
        echo "Error: El valor para $key no cumple con los requisitos de seguridad."
        invalid=true
	exit 1
    fi
  done

  if $invalid; then
    exit 1
  fi
}

# Validar el archivo values.yaml
validate_passwords "$VALUES_FILE"

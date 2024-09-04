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

# Define la expresión regular para validar passwords
PASSWORD_REGEX='^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$'

# Obtener el archivo values.yaml del chart
VALUES_FILE="$1/values.yaml"

# Función para validar contraseñas
validate_passwords() {
  local values_file=$1
  local invalid=false

  # Buscar claves que contengan passwords, pwd, pass, o credentials
  grep -oP '^[^:]+:.*' "$values_file" | grep -Eo '.*:(.*)' | while IFS= read -r line; do
    key=$(echo "$line" | awk -F':' '{print $1}' | xargs)
    value=$(echo "$line" | awk -F':' '{print $2}' | xargs)

    if [[ $key =~ passwords|pwd|pass|credentials ]]; then
      if [[ ! $value =~ $PASSWORD_REGEX ]]; then
        echo "Error: El valor para $key no cumple con los requisitos de seguridad."
        invalid=true
      fi
    fi
  done

  if $invalid; then
    exit 1
  fi
}

# Validar el archivo values.yaml
validate_passwords "$VALUES_FILE"

echo "Validación completada con éxito."

# (Opcional) Aquí se puede agregar lógica para migrar configuraciones a secrets

#!/bin/bash
while true; do
  echo "1. Calcular mínimo"
  echo "2. Calcular máximo"
  echo "3. Calcular media"
  echo "4. Calcular mediana"
  echo "5. Calcular varianza"
  echo "6. Calcular moda"
  echo "7. Calcular desviación estándar"
  echo "8. Salir"
  read -p "Seleccione una opción: " op
  case $op in
    1) qemu-aarch64 ./minimo ;;
    2) qemu-aarch64 ./maximo ;;
    3) qemu-aarch64 ./mean ;;
    4) qemu-aarch64 ./mediana ;;
    5) qemu-aarch64 ./varianza ;;
    6) qemu-aarch64 ./moda ;;
    7) qemu-aarch64 ./desviacion ;;
    8) exit 0 ;;
    *) echo "Opción inválida" ;;
  esac
done
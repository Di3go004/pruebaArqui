#!/bin/bash
echo "Compilando proyecto Segunda con lector de archivos real..."

# Compilar archivos individualmente
aarch64-linux-gnu-as -o main.o main.s
if [ $? -ne 0 ]; then
    echo "Error compilando main.s"
    exit 1
fi

aarch64-linux-gnu-as -o atoi.o atoi.s  
if [ $? -ne 0 ]; then
    echo "Error compilando atoi.s"
    exit 1
fi

aarch64-linux-gnu-as -o atoi_partial.o atoi_partial.s
if [ $? -ne 0 ]; then
    echo "Error compilando atoi_partial.s"
    exit 1
fi

aarch64-linux-gnu-as -o count_partial.o count_partial.s
if [ $? -ne 0 ]; then
    echo "Error compilando count_partial.s"
    exit 1
fi

aarch64-linux-gnu-as -o file_reader.o file_reader.s
if [ $? -ne 0 ]; then
    echo "Error compilando file_reader.s"
    exit 1
fi

aarch64-linux-gnu-as -o statistics.o statistics.s
if [ $? -ne 0 ]; then
    echo "Error compilando statistics.s"
    exit 1
fi

echo "Archivos compilados exitosamente"
echo "Creando ejecutable..."

# Enlazar
aarch64-linux-gnu-ld -o tui main.o atoi.o atoi_partial.o count_partial.o file_reader.o statistics.o
if [ $? -ne 0 ]; then
    echo "Error en el enlazado"
    exit 1
fi

echo "¡Compilación exitosa!"
echo "Ejecutar con: qemu-aarch64 ./tui"
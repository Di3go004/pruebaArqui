#!/bin/sh

aarch64-linux-gnu-as -o mean.o mean.s && aarch64-linux-gnu-ld -o mean mean.o

aarch64-linux-gnu-as -o minimo.o minimo.s && aarch64-linux-gnu-ld -o minimo minimo.o

aarch64-linux-gnu-as -o maximo.o maximo.s && aarch64-linux-gnu-ld -o maximo maximo.o

aarch64-linux-gnu-as -o mediana.o mediana.s && aarch64-linux-gnu-ld -o mediana mediana.o

aarch64-linux-gnu-as -o moda.o moda.s && aarch64-linux-gnu-ld -o moda moda.o

aarch64-linux-gnu-as -o varianza.o varianza.s && aarch64-linux-gnu-ld -o varianza varianza.o

aarch64-linux-gnu-as -o menu_principal.o menu_principal.s && aarch64-linux-gnu-ld -o menu menu_principal.o 
.section .data
menu_msg:   .asciz "1. Calcular mínimo\n2. Calcular máximo\n3. Calcular media\n4. Calcular mediana\n5. Calcular varianza\n6. Calcular moda\n7. Calcular desviación estándar\n8. Salir\nSeleccione una opción: "
opcion:     .space 2
min_path:   .asciz "./minimo"
max_path:   .asciz "./maximo"
mean_path:  .asciz "./mean"
mediana_path: .asciz "./mediana"
varianza_path: .asciz "./varianza"
moda_path:   .asciz "./moda"
desviacion_path: .asciz "./desviacion"
null_ptr:   .quad 0
argv_min:      .quad min_path, 0
argv_max:      .quad max_path, 0
argv_mean:     .quad mean_path, 0
argv_mediana:  .quad mediana_path, 0
argv_varianza: .quad varianza_path, 0
argv_moda:   .quad moda_path, 0
argv_desviacion: .quad desviacion_path, 0

.section .text
.global _start

_start:
menu_loop:
    // Mostrar menú
    ldr x0, =menu_msg
    bl print_string

    // Leer opción del usuario
    ldr x0, =opcion
    mov x1, #2
    bl read_input

    // Verificar opción
    ldr x3, =opcion
    ldrb w2, [x3]
    cmp w2, #'1'
    beq exec_min
    cmp w2, #'2'
    beq exec_max
    cmp w2, #'3'
    beq exec_mean
    cmp w2, #'4'
    beq exec_mediana
    cmp w2, #'5'
    beq exec_varianza
    cmp w2, #'6'
    beq exec_moda
    cmp w2, #'7'
    beq exec_desviacion
    cmp w2, #'8'
    beq salir
    b menu_loop

exec_min:
    ldr x0, =min_path
    ldr x1, =argv_min
    ldr x2, =null_ptr
    mov x8, #221        // syscall: execve
    svc #0
    b menu_loop

exec_max:
    ldr x0, =max_path
    ldr x1, =argv_max
    ldr x2, =null_ptr
    mov x8, #221
    svc #0
    b menu_loop

exec_mean:
    ldr x0, =mean_path
    ldr x1, =argv_mean
    ldr x2, =null_ptr
    mov x8, #221
    svc #0
    b menu_loop

exec_mediana:
    ldr x0, =mediana_path
    ldr x1, =argv_mediana
    ldr x2, =null_ptr
    mov x8, #221
    svc #0
    b menu_loop

exec_varianza:
    ldr x0, =varianza_path
    ldr x1, =argv_varianza
    ldr x2, =null_ptr
    mov x8, #221
    svc #0
    b menu_loop

exec_moda:
    ldr x0, =moda_path
    ldr x1, =argv_moda
    ldr x2, =null_ptr
    mov x8, #221
    svc #0
    b menu_loop

exec_desviacion:
    ldr x0, =desviacion_path
    ldr x1, =argv_desviacion
    ldr x2, =null_ptr
    mov x8, #221
    svc #0
    b menu_loop

salir:
    mov x8, #93
    mov x0, #0
    svc #0

// Función para imprimir string (print_string)
// x0 = dirección del string
print_string:
    mov x1, x0
    mov x2, #0
print_strlen:
    ldrb w3, [x1, x2]
    cbz w3, print_write
    add x2, x2, #1
    b print_strlen
print_write:
    mov x8, #64         // syscall: write
    mov x1, x0          // dirección del string
    mov x0, #1          // stdout
    svc #0
    ret

// Función para leer input (read_input)
// x0 = buffer destino, x1 = cantidad de bytes
read_input:
    mov x8, #63         // syscall: read
    mov x2, x1          // cantidad de bytes
    mov x1, x0          // buffer
    mov x0, #0          // stdin
    svc #0
    ret 
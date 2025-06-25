.section .data
input_file:     .asciz "datos.txt"    // Nombre del archivo de entrada
output_file:    .asciz "moda.txt"   // Nombre del archivo de salida
buffer:         .space 2048                 // Buffer para leer datos
numbers:        .space 4096                 // Espacio para hasta 1024 enteros
counts:         .space 4096                 // Espacio para contar repeticiones
error_msg:      .asciz "Error: No hay suficientes números para encontrar la moda.\n"
newline:        .asciz "\n"

.section .text
.global _start

_start:
    // Abrir archivo de entrada para lectura
    mov x0, #-100
    ldr x1, =input_file
    mov x2, #0
    mov x8, #56
    svc #0
    mov x9, x0
    cmp x9, #0
    b.lt error

    // Leer del archivo
    mov x0, x9
    ldr x1, =buffer
    mov x2, #2048
    mov x8, #63
    svc #0
    mov x19, x0
    cmp x19, #0
    b.le error

    // Parsear números (separados por salto de línea, termina con '$')
    ldr x22, =numbers
    mov x21, #0
    ldr x1, =buffer
parse_loop:
    mov x0, x1
    bl atoi_nl_dollar
    cmp x0, #-1
    beq parse_end
    str w0, [x22], #4
    add x21, x21, #1
    // Avanzar x1 hasta después del salto de línea
advance_nl:
    ldrb w2, [x1], #1
    cmp w2, #10         // '\n'
    b.ne advance_nl
    b parse_loop
parse_end:
    mov x23, x21 // x23 = cantidad de números
    cmp x23, #1
    b.le not_enough_numbers

    // Calcular la moda
    ldr x22, =numbers
    ldr x24, =counts
    mov x25, #0 // índice externo
find_mode_outer:
    cmp x25, x23
    b.ge find_mode_done
    ldr w0, [x22, x25, lsl #2]
    mov x26, #0 // contador de repeticiones
    mov x27, #0 // índice interno
find_mode_inner:
    cmp x27, x23
    b.ge store_count
    ldr w1, [x22, x27, lsl #2]
    cmp w0, w1
    cinc x26, x26, eq
    add x27, x27, #1
    b find_mode_inner
store_count:
    str w26, [x24, x25, lsl #2]
    add x25, x25, #1
    b find_mode_outer
find_mode_done:
    // Buscar el máximo en counts
    mov x25, #0
    mov x28, #0 // moda
    mov x29, #0 // max_count
find_max_count:
    cmp x25, x23
    b.ge found_mode
    ldr w0, [x24, x25, lsl #2]
    cmp w0, w29
    csel w29, w0, w29, gt
    csel w28, w25, w28, gt
    add x25, x25, #1
    b find_max_count
found_mode:
    // Obtener el número correspondiente a la moda
    ldr x22, =numbers
    ldr w0, [x22, x28, lsl #2]
    ldr x1, =buffer
    bl itoa

    // Abrir archivo de salida para escritura
    mov x0, #-100
    ldr x1, =output_file
    mov x2, #577
    mov x3, #0644
    mov x8, #56
    svc #0
    mov x10, x0
    cmp x10, #0
    b.lt error

    // Escribir la moda en el archivo
    mov x0, x10
    ldr x1, =buffer
    bl write_string

    // Mostrar resultado en consola
    mov x0, #1                  // stdout
    ldr x1, =buffer
    bl write_string
    b close_and_exit

not_enough_numbers:
    mov x0, #-100
    ldr x1, =output_file
    mov x2, #577
    mov x3, #0644
    mov x8, #56
    svc #0
    mov x10, x0
    cmp x10, #0
    b.lt error
    mov x0, x10
    ldr x1, =error_msg
    bl write_string
    b close_and_exit

error:
    mov x0, #1
    ldr x1, =error_msg
    mov x2, #58
    mov x8, #64
    svc #0

close_and_exit:
    mov x0, x9
    mov x8, #57
    svc #0
    mov x0, x10
    mov x8, #57
    svc #0
    mov x0, #0
    mov x8, #93
    svc #0

// atoi_nl_dollar: Convierte string a número, termina en salto de línea o '$'. Si encuentra '$', retorna -1
atoi_nl_dollar:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    mov x2, #0
atoi_nl_loop:
    ldrb w3, [x0], #1
    cmp w3, #'$'
    b.eq atoi_nl_dollar_end_of_data
    cmp w3, #10 // '\n'
    b.eq atoi_nl_dollar_end
    cmp w3, #0
    b.eq atoi_nl_dollar_end
    sub w3, w3, #'0'
    cmp w3, #9
    b.hi atoi_nl_dollar_end
    mov x4, #10
    mul x2, x2, x4
    add x2, x2, x3
    b atoi_nl_loop
atoi_nl_dollar_end:
    mov x0, x2
    ldp x29, x30, [sp], #16
    ret
atoi_nl_dollar_end_of_data:
    mov x0, #-1
    ldp x29, x30, [sp], #16
    ret

// itoa y write_string igual que en otros archivos
itoa:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    mov x2, #10
    mov x3, x1
    mov x4, x0
itoa_loop:
    udiv x0, x4, x2
    msub x5, x0, x2, x4
    add x5, x5, #'0'
    strb w5, [x3], #1
    mov x4, x0
    cbz x0, itoa_end
    b itoa_loop
itoa_end:
    strb wzr, [x3]
    sub x3, x3, #1
    mov x4, x1
    mov x5, x3
itoa_reverse:
    ldrb w6, [x4]
    ldrb w7, [x5]
    strb w7, [x4]
    strb w6, [x5]
    add x4, x4, #1
    sub x5, x5, #1
    cmp x4, x5
    b.lo itoa_reverse
    ldp x29, x30, [sp], #16
    ret

write_string:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    mov x2, #0
strlen_loop:
    ldrb w3, [x1, x2]
    cbz w3, strlen_done
    add x2, x2, #1
    b strlen_loop
strlen_done:
    mov x8, #64
    svc #0
    ldp x29, x30, [sp], #16
    ret 
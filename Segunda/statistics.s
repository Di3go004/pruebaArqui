/*
    statistics.s - Módulo de cálculos estadísticos
    Version simplificada sin dependencia de print
*/

.global calc_mean_real

.extern data_array
.extern data_array_size

.section .text

// Función para calcular la media real usando datos del array
calc_mean_real:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    
    // Verificar que hay datos
    adr x0, data_array
    ldr x1, [x0]               // x1 = dirección del array
    cbz x1, error_exit
    
    adr x0, data_array_size
    ldr x2, [x0]               // x2 = número de elementos
    cbz x2, error_exit
    
    // Calcular suma usando el mismo algoritmo que tu mean.s original
    mov x20, #0                // sum = 0
    mov x21, x2                // count = número de elementos
    mov x22, #0                // índice = 0
    
sum_loop:
    cmp x22, x21               // comparar índice con count
    b.ge calculate_mean        // si índice >= count, calcular media
    
    ldr x3, [x1, x22, lsl #3]  // cargar elemento (8 bytes por elemento)
    add x20, x20, x3           // sum += elemento
    add x22, x22, #1           // índice++
    b sum_loop
    
calculate_mean:
    // Calcular media: sum / count (usando misma lógica que mean.s)
    udiv x22, x20, x21         // x22 = sum / count
    
    // Convertir resultado a string usando método de tu mean.s
    mov x0, x22                // resultado
    adr x1, result_buffer      // buffer para el string
    bl convert_to_decimal_original
    
    // Crear archivo mean.txt como en tu versión original
    bl create_mean_file
    
    // Mostrar resultado en pantalla
    mov x0, #1                 // stdout
    adr x1, mean_prefix
    mov x2, #13
    mov x8, #64
    svc #0
    
    mov x0, #1
    adr x1, result_buffer
    mov x2, #10
    mov x8, #64
    svc #0
    
    mov x0, #1
    adr x1, newline_str
    mov x2, #1
    mov x8, #64
    svc #0
    
    ldp x29, x30, [sp], #16
    ret

error_exit:
    mov x0, #1
    adr x1, error_msg
    mov x2, #27
    mov x8, #64
    svc #0
    ldp x29, x30, [sp], #16
    ret

// Función para crear archivo mean.txt (como en tu mean.s original)
create_mean_file:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    
    // Crear archivo mean.txt
    mov x0, #-100              // AT_FDCWD
    adr x1, mean_filename      // "mean.txt"
    mov x2, #577               // O_CREAT | O_WRONLY | O_TRUNC
    mov x3, #420               // 0644 permissions
    mov x8, #56                // openat syscall
    svc #0
    
    cmp x0, #0
    b.lt create_file_error
    mov x21, x0                // file descriptor
    
    // Escribir resultado al archivo
    mov x0, x21
    adr x1, result_buffer
    mov x2, #10                // longitud
    mov x8, #64                // write syscall
    svc #0
    
    // Cerrar archivo
    mov x0, x21
    mov x8, #57                // close syscall
    svc #0
    
    ldp x29, x30, [sp], #16
    ret

create_file_error:
    ldp x29, x30, [sp], #16
    ret

// Conversión decimal usando el método de tu mean.s original
convert_to_decimal_original:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    
    mov w4, w0                  // number
    mov x3, x1                  // buffer
    
    // Integer part: number / 100
    mov w5, #100
    udiv w6, w4, w5             // w6 = integer part
    
    // Convert integer to string
    mov x0, x6
    mov x1, x3
    bl simple_itoa_original
    
    // Find end of integer part
    mov x2, #0
find_end:
    ldrb w8, [x3, x2]
    cbz w8, found_end
    add x2, x2, #1
    b find_end
found_end:
    add x3, x3, x2
    
    // Add decimal point
    mov w8, #'.'
    strb w8, [x3]
    add x3, x3, #1
    
    // Decimal part: number % 100
    mov w5, #100
    udiv w7, w4, w5
    mul w8, w7, w5
    sub w7, w4, w8              // w7 = decimal part
    
    // First decimal digit
    mov w5, #10
    udiv w8, w7, w5
    add w8, w8, #'0'
    strb w8, [x3]
    add x3, x3, #1
    
    // Second decimal digit
    mul w9, w8, w5
    sub w8, w8, #'0'            // convert back to number
    mul w9, w8, w5
    sub w7, w7, w9
    add w7, w7, #'0'
    strb w7, [x3]
    add x3, x3, #1
    
    // Null terminate
    strb wzr, [x3]
    
    ldp x29, x30, [sp], #16
    ret

// Simple itoa (como en tu mean.s)
simple_itoa_original:
    cbz x0, zero_case
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    
    mov x2, x1                  // save start
    mov x3, #10
    
convert_loop:
    udiv x4, x0, x3
    msub x5, x4, x3, x0
    add x5, x5, #'0'
    strb w5, [x1], #1
    mov x0, x4
    cbnz x0, convert_loop
    
    strb wzr, [x1]
    sub x1, x1, #1
    
reverse_loop:
    cmp x2, x1
    b.ge reverse_done
    ldrb w4, [x2]
    ldrb w5, [x1]
    strb w5, [x2]
    strb w4, [x1]
    add x2, x2, #1
    sub x1, x1, #1
    b reverse_loop
reverse_done:
    ldp x29, x30, [sp], #16
    ret

zero_case:
    mov w3, #'0'
    strb w3, [x1]
    strb wzr, [x1, #1]
    ret

// Función itoa_decimal simplificada
itoa_decimal:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    
    mov w4, w0                  // w4 = number
    mov x3, x1                  // x3 = buffer pointer
    
    // Get integer part: number / 100
    mov w5, #100
    udiv w6, w4, w5             // w6 = integer part
    
    // Convert integer part to simple string
    cmp w6, #0
    bne convert_integer
    
    // If integer part is 0, just write '0'
    mov w8, #'0'
    strb w8, [x3]
    add x3, x3, #1
    b add_decimal_point
    
convert_integer:
    // Simple conversion for small numbers
    mov w7, #10
    udiv w8, w6, w7             // tens digit
    cbnz w8, write_tens
    b write_ones
    
write_tens:
    add w8, w8, #'0'
    strb w8, [x3]
    add x3, x3, #1
    
write_ones:
    mov w7, #10
    udiv w9, w6, w7             // get tens digit again for calculation
    mul w10, w9, w7             // tens * 10
    sub w8, w6, w10             // ones digit = total - (tens * 10)
    add w8, w8, #'0'
    strb w8, [x3]
    add x3, x3, #1
    
add_decimal_point:
    // Add decimal point
    mov w8, #'.'
    strb w8, [x3]
    add x3, x3, #1
    
    // Get decimal part: number % 100
    mov w5, #100
    udiv w7, w4, w5
    mul w8, w7, w5
    sub w7, w4, w8              // w7 = decimal part
    
    // Add two decimal digits
    mov w5, #10
    udiv w8, w7, w5             // first digit
    add w8, w8, #'0'
    strb w8, [x3]
    add x3, x3, #1
    
    mul w9, w8, w5              // first_digit * 10
    sub w8, w8, #'0'            // convert back to number
    mul w9, w8, w5              // correct calculation 
    sub w7, w7, w9              // second digit = remainder
    add w7, w7, #'0'
    strb w7, [x3]
    add x3, x3, #1
    
    // Null terminate
    strb wzr, [x3]
    
    ldp x29, x30, [sp], #16
    ret

// Simple itoa function
simple_itoa:
    cbz x0, zero_case
    stp x29, x30, [sp, #-16]!  // Save registers
    mov x29, sp
    
    mov x2, x1                  // save start
    mov x3, #10
    
convert_loop:
    udiv x4, x0, x3
    msub x5, x4, x3, x0
    add x5, x5, #'0'
    strb w5, [x1], #1
    mov x0, x4
    cbnz x0, convert_loop
    
    strb wzr, [x1]              // null terminate
    sub x1, x1, #1
    
    // Reverse string
reverse_loop:
    cmp x2, x1
    b.ge reverse_done
    ldrb w4, [x2]
    ldrb w5, [x1]
    strb w5, [x2]
    strb w4, [x1]
    add x2, x2, #1
    sub x1, x1, #1
    b reverse_loop
reverse_done:
    ldp x29, x30, [sp], #16     // Restore registers
    ret

zero_case:
    mov w3, #'0'
    strb w3, [x1]
    strb wzr, [x1, #1]
    ret

.section .data
mean_prefix:
    .ascii "Mean result: "
error_msg:
    .ascii "Error: No data available!\n"
newline_str:
    .ascii "\n"
mean_filename:
    .ascii "mean.txt"

.section .bss
result_buffer:
    .space 32
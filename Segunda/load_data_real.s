/*
    load_data_real.s - Carga real de datos desde archivo
    Reemplaza load_data_simple.s para leer archivos reales
*/

.global load_data

.section .text

load_data:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    
    // x0 contiene la dirección del nombre del archivo
    mov x20, x0                // guardar nombre del archivo
    
    // Limpiar newline del final del nombre
    mov x1, x0
find_newline_loop:
    ldrb w2, [x1], #1
    cmp w2, #10                // newline
    b.eq replace_with_null
    cmp w2, #0                 // null terminator
    b.eq open_file
    b find_newline_loop

replace_with_null:
    sub x1, x1, #1
    strb wzr, [x1]             // reemplazar newline con null

open_file:
    // Abrir archivo
    mov x0, #-100              // AT_FDCWD
    mov x1, x20                // nombre del archivo
    mov x2, #0                 // O_RDONLY
    mov x8, #56                // openat syscall
    svc #0
    
    cmp x0, #0
    b.lt file_error            // si es negativo, error
    mov x21, x0                // guardar file descriptor
    
    // Leer contenido del archivo
    mov x0, x21                // file descriptor
    adr x1, file_buffer        // buffer
    mov x2, #4096              // tamaño máximo
    mov x8, #63                // read syscall
    svc #0
    
    cmp x0, #0
    b.le read_error            // si es <= 0, error
    mov x22, x0                // guardar bytes leídos
    
    // Cerrar archivo
    mov x0, x21
    mov x8, #57                // close syscall
    svc #0
    
    // Procesar datos del buffer
    adr x0, file_buffer
    mov x1, x22                // número de bytes
    bl parse_numbers
    
    // Mensaje de éxito
    mov x0, #1                 // stdout
    adr x1, success_message
    mov x2, #26                // longitud
    mov x8, #64                // write syscall
    svc #0
    
    ldp x29, x30, [sp], #16
    b while

file_error:
    mov x0, #1
    adr x1, file_error_msg
    mov x2, #30
    mov x8, #64
    svc #0
    ldp x29, x30, [sp], #16
    b while

read_error:
    mov x0, x21
    mov x8, #57                // close file
    svc #0
    mov x0, #1
    adr x1, read_error_msg
    mov x2, #25
    mov x8, #64
    svc #0
    ldp x29, x30, [sp], #16
    b while

// Función para parsear números del buffer
parse_numbers:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    
    mov x20, x0                // buffer
    mov x21, x1                // size
    mov x22, #0                // índice en buffer
    mov x23, #0                // contador de números
    
    // Reservar espacio para hasta 100 números
    adr x0, data_array
    adr x1, parsed_data
    str x1, [x0]
    
parse_loop:
    cmp x22, x21
    b.ge parse_done
    
    // Saltar espacios y newlines
    ldrb w0, [x20, x22]
    cmp w0, #' '
    b.eq skip_char
    cmp w0, #'\n'
    b.eq skip_char
    cmp w0, #'\r' 
    b.eq skip_char
    cmp w0, #'\t'
    b.eq skip_char
    
    // Comenzar a leer número
    add x0, x20, x22           // dirección actual
    bl parse_decimal
    
    // Guardar número en array
    adr x1, parsed_data
    str x0, [x1, x23, lsl #3]  // guardar en posición x23 * 8
    add x23, x23, #1           // incrementar contador
    
    // Avanzar al siguiente número
find_next:
    cmp x22, x21
    b.ge parse_done
    ldrb w0, [x20, x22]
    add x22, x22, #1
    cmp w0, #' '
    b.eq parse_loop
    cmp w0, #'\n'
    b.eq parse_loop
    cmp w0, #'\t'
    b.eq parse_loop
    b find_next

skip_char:
    add x22, x22, #1
    b parse_loop

parse_done:
    // Guardar cantidad de números
    adr x0, data_array_size
    str x23, [x0]
    
    ldp x29, x30, [sp], #16
    ret

// Función para parsear un número decimal desde string
parse_decimal:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    
    mov x1, #0                 // resultado
    mov x2, #0                 // parte decimal
    mov x3, #0                 // flag decimal encontrado
    
parse_digit_loop:
    ldrb w4, [x0], #1
    
    // Check if end of number
    cmp w4, #' '
    b.eq decimal_done
    cmp w4, #'\n'
    b.eq decimal_done
    cmp w4, #'\t'
    b.eq decimal_done
    cmp w4, #0
    b.eq decimal_done
    
    // Check if decimal point
    cmp w4, #'.'
    b.eq found_decimal
    
    // Check if digit
    cmp w4, #'0'
    b.lt decimal_done
    cmp w4, #'9'
    b.gt decimal_done
    
    // Process digit
    sub w4, w4, #'0'
    cmp x3, #0
    b.eq integer_part
    
    // Decimal part
    mov x5, #10
    mul x2, x2, x5
    add x2, x2, x4
    b parse_digit_loop
    
integer_part:
    mov x5, #10
    mul x1, x1, x5
    add x1, x1, x4
    b parse_digit_loop
    
found_decimal:
    mov x3, #1                 // set decimal flag
    b parse_digit_loop
    
decimal_done:
    // Convert to integer representation (* 100)
    mov x5, #100
    mul x1, x1, x5
    add x0, x1, x2             // resultado = integer*100 + decimal
    
    ldp x29, x30, [sp], #16
    ret

.section .data
success_message:
    .ascii "Data loaded successfully!\n"
file_error_msg:
    .ascii "Error: Could not open file!\n"
read_error_msg:
    .ascii "Error: Could not read file!\n"

.section .bss
file_buffer:
    .space 4096                // Buffer para leer archivo
parsed_data:
    .space 800                 // Espacio para 100 números (8 bytes cada uno)

.extern while
.extern data_array
.extern data_array_size
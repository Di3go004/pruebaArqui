/*
    file_reader.s - Lector de archivos simplificado para TUI
    Lee números decimales desde archivo de texto
*/

.global load_data

.section .text

load_data:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    
    // x0 contiene buffer con nombre del archivo
    mov x20, x0                // guardar dirección del buffer
    
    // Limpiar newline del final si existe
    mov x1, x0
clean_filename:
    ldrb w2, [x1]
    cbz w2, open_file          // si es null, abrir archivo
    cmp w2, #10                // newline
    b.eq replace_newline
    cmp w2, #13                // carriage return
    b.eq replace_newline
    add x1, x1, #1
    b clean_filename

replace_newline:
    strb wzr, [x1]             // reemplazar con null terminator

open_file:
    // Abrir archivo usando openat
    mov x0, #-100              // AT_FDCWD
    mov x1, x20                // nombre del archivo
    mov x2, #0                 // O_RDONLY
    mov x3, #0                 // mode
    mov x8, #56                // sys_openat
    svc #0
    
    cmp x0, #0
    b.lt file_error            // si es negativo, error
    mov x21, x0                // guardar file descriptor
    
    // Leer contenido completo
    mov x0, x21                // file descriptor
    adr x1, file_buffer        // buffer
    mov x2, #2048              // tamaño máximo
    mov x8, #63                // sys_read
    svc #0
    
    mov x22, x0                // guardar bytes leídos
    
    // Cerrar archivo
    mov x0, x21
    mov x8, #57                // sys_close
    svc #0
    
    // Verificar si se leyó algo
    cmp x22, #0
    b.le read_error
    
    // Procesar los datos leídos
    adr x0, file_buffer
    mov x1, x22
    bl parse_file_data
    
    // Mostrar mensaje de éxito
    mov x0, #1                 // stdout
    adr x1, success_msg
    mov x2, #26
    mov x8, #64                // sys_write
    svc #0
    
    ldp x29, x30, [sp], #16
    b while

file_error:
    mov x0, #1
    adr x1, error_msg
    mov x2, #25
    mov x8, #64
    svc #0
    ldp x29, x30, [sp], #16
    b while

read_error:
    mov x0, #1
    adr x1, read_err_msg
    mov x2, #20
    mov x8, #64
    svc #0
    ldp x29, x30, [sp], #16
    b while

// Función para procesar datos del archivo
parse_file_data:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    
    mov x20, x0                // buffer
    mov x21, x1                // tamaño
    mov x22, #0                // índice en buffer
    mov x23, #0                // contador de números
    
    // Establecer puntero al array de datos
    adr x0, data_array
    adr x1, number_array
    str x1, [x0]

parse_numbers:
    cmp x22, x21
    b.ge parsing_done
    
    // Saltar caracteres no numéricos
    ldrb w0, [x20, x22]
    
    // Si es $, terminar parsing
    cmp w0, #'$'
    b.eq parsing_done
    
    // Si es dígito o punto decimal, parsear número
    cmp w0, #'0'
    b.lt skip_char
    cmp w0, #'9'
    b.le parse_number
    cmp w0, #'.'
    b.eq parse_number
    
skip_char:
    add x22, x22, #1
    b parse_numbers

parse_number:
    // Parsear número decimal desde posición actual
    add x0, x20, x22           // dirección actual en buffer
    bl simple_parse_decimal
    
    // Guardar número en array
    adr x1, number_array
    str x0, [x1, x23, lsl #3]  // guardar en posición x23 * 8
    add x23, x23, #1
    
    // Avanzar al siguiente número
find_next_number:
    cmp x22, x21
    b.ge parsing_done
    ldrb w0, [x20, x22]
    add x22, x22, #1
    
    // Si encontramos newline o espacio, buscar siguiente número
    cmp w0, #10                // newline
    b.eq parse_numbers
    cmp w0, #' '               // espacio
    b.eq parse_numbers
    cmp w0, #13                // carriage return
    b.eq parse_numbers
    
    b find_next_number

parsing_done:
    // Guardar cantidad de números encontrados
    adr x0, data_array_size
    str x23, [x0]
    
    ldp x29, x30, [sp], #16
    ret

// Función simple para parsear decimal
simple_parse_decimal:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    
    mov x1, #0                 // parte entera
    mov x2, #0                 // parte decimal
    mov x3, #0                 // flag: encontró punto decimal
    mov x4, #0                 // contador dígitos decimales
    
decimal_parse_loop:
    ldrb w5, [x0], #1
    
    // Verificar fin de número
    cmp w5, #'0'
    b.lt decimal_finish
    cmp w5, #'9'
    b.gt decimal_finish
    
    cmp w5, #'.'
    b.eq found_decimal_point
    
    // Procesar dígito
    sub w5, w5, #'0'
    
    cmp x3, #0
    b.eq process_integer_digit
    
    // Dígito decimal
    mov x6, #10
    mul x2, x2, x6
    add x2, x2, x5
    add x4, x4, #1
    cmp x4, #2                 // máximo 2 dígitos decimales
    b.eq decimal_finish
    b decimal_parse_loop
    
process_integer_digit:
    mov x6, #10
    mul x1, x1, x6
    add x1, x1, x5
    b decimal_parse_loop
    
found_decimal_point:
    mov x3, #1
    b decimal_parse_loop
    
decimal_finish:
    // Convertir a formato entero (* 100)
    // Ajustar parte decimal según número de dígitos
    cmp x4, #1
    b.eq one_decimal_digit
    cmp x4, #2
    b.eq two_decimal_digits
    
    // Sin decimales
    mov x6, #100
    mul x0, x1, x6
    ldp x29, x30, [sp], #16
    ret
    
one_decimal_digit:
    mov x6, #10
    mul x2, x2, x6             // multiplicar por 10 para completar 2 dígitos
    
two_decimal_digits:
    mov x6, #100
    mul x1, x1, x6
    add x0, x1, x2             // resultado final
    
    ldp x29, x30, [sp], #16
    ret

.section .data
success_msg:
    .ascii "Data loaded successfully!\n"
error_msg:
    .ascii "Error: Cannot open file!\n"
read_err_msg:
    .ascii "Error: Cannot read!\n"

.section .bss
file_buffer:
    .space 2048                // Buffer para archivo
number_array:
    .space 800                 // Espacio para 100 números máximo

.extern while
.extern data_array
.extern data_array_size
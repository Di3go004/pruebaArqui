.section .data
input_file:     .asciz "datos.txt"   // Input file name
output_file:    .asciz "mean.txt"     // Output file name
buffer:         .space 256            // Buffer space (256 bytes)
newline:        .asciz "\n"           // Newline string

.section .text
.global _start

_start:
    // Align stack to 16 bytes
    mov x29, sp
    and sp, x29, #~15
    sub sp, sp, #16

    // Open datos.txt for reading
    mov x0, #-100               // AT_FDCWD (current directory)
    ldr x1, =input_file         // File name address
    mov x2, #0                  // O_RDONLY (read-only mode)
    mov x8, #56                 // syscall: openat
    svc #0                      // System call
    cmp x0, #0
    b.lt error                  // If x0 is negative, jump to error
    mov x19, x0                 // Save file descriptor in x19

    // Read from file
    mov x0, x19                 // File descriptor in x0
    ldr x1, =buffer             // Buffer address in x1
    mov x2, #256                // Buffer size in x2
    mov x8, #63                 // syscall: read
    svc #0                      // System call
    cmp x0, #0
    b.le error                  // If x0 is zero or negative, jump to error

    // Parse numbers (one per line, end with $)
    ldr x1, =buffer
    mov x20, #0                 // sum
    mov x21, #0                 // count
parse_loop:
    bl read_decimal_clean       // Use clean function
    cmp x0, #-1
    beq parse_end
    add x20, x20, x0            // sum += number * 100 (already converted)
    add x21, x21, #1            // count++
    b parse_loop                // Continue with next number
parse_end:
    cmp x21, #0
    b.eq error                  // Avoid division by zero
    sdiv x22, x20, x21          // x22 = sum / count (treat as if it's *100)

    // Open mean.txt for writing
    mov x0, #-100               // AT_FDCWD (current directory)
    ldr x1, =output_file        // File name address
    mov x2, #577                // O_WRONLY | O_CREAT | O_TRUNC
    mov x3, #0644               // File permissions
    mov x8, #56                 // syscall: openat
    svc #0                      // System call
    cmp x0, #0
    b.lt error                  // If x0 is negative, jump to error
    mov x23, x0                 // Save file descriptor in x23

    // Convert result to string with decimals and write to file
    mov x0, x22                 // Pass result to x0 (mean * 100)
    ldr x1, =buffer             // Use buffer for output
    bl itoa_decimal             // Convert integer to string with decimals
    mov x0, x23                 // File descriptor in x0
    ldr x1, =buffer             // String to write
    bl write_string             // Call write_string function

    // Mostrar resultado en consola
    mov x0, #1                  // stdout
    ldr x1, =buffer             // String to print
    bl write_string             // Call write_string function
    mov x0, #1                  // stdout
    ldr x1, =newline            // Imprimir salto de línea
    bl write_string             // Call write_string function

    // Write newline to file
    mov x0, x23                 // File descriptor in x0
    ldr x1, =newline            // Newline string
    bl write_string             // Call write_string function

    // Close files
    mov x0, x19                 // input file descriptor in x0
    mov x8, #57                 // syscall: close
    svc #0                      // System call

    mov x0, x23                 // output file descriptor in x0
    mov x8, #57                 // syscall: close
    svc #0                      // System call

    // Exit program
    mov x0, #0                  // Exit code in x0
    mov x8, #93                 // syscall: exit
    svc #0                      // System call

error:
    // Handle error and exit
    mov x0, #1                  // Error exit code in x0
    mov x8, #93                 // syscall: exit
    svc #0                      // System call

// read_decimal_clean - VERSION QUE FUNCIONA CORRECTAMENTE
read_decimal_clean:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    mov x2, #0                  // result
    
    // Skip whitespace
skip_ws:
    ldrb w6, [x1]
    cmp w6, #10                 // '\n'
    b.eq skip_ws_char
    cmp w6, #13                 // '\r'
    b.eq skip_ws_char
    cmp w6, #32                 // space
    b.eq skip_ws_char
    cmp w6, #'$'
    b.eq read_decimal_end_data
    cmp w6, #0
    b.eq read_decimal_end_data
    b read_integer

skip_ws_char:
    add x1, x1, #1
    b skip_ws

read_integer:
    ldrb w6, [x1], #1
    cmp w6, #'.'
    b.eq read_decimal_part
    cmp w6, #'$'
    b.eq read_decimal_end_data
    cmp w6, #10                 // '\n'
    b.eq read_decimal_end
    cmp w6, #0
    b.eq read_decimal_end
    cmp w6, #'0'
    b.lt read_decimal_end
    cmp w6, #'9'
    b.gt read_decimal_end
    sub w6, w6, #'0'
    mov x7, #10
    mul x2, x2, x7
    add x2, x2, x6
    b read_integer

read_decimal_part:
    mov x7, #100
    mul x2, x2, x7              // integer * 100
    
    // First decimal
    ldrb w6, [x1], #1
    cmp w6, #'$'
    b.eq read_decimal_end_data
    cmp w6, #10
    b.eq read_decimal_end
    cmp w6, #0
    b.eq read_decimal_end
    cmp w6, #'0'
    b.lt read_decimal_end
    cmp w6, #'9'
    b.gt read_decimal_end
    sub w6, w6, #'0'
    mov x7, #10
    mul x7, x6, x7              // first decimal * 10
    add x2, x2, x7
    
    // Second decimal
    ldrb w6, [x1], #1
    cmp w6, #'$'
    b.eq read_decimal_end_data
    cmp w6, #10
    b.eq read_decimal_end
    cmp w6, #0
    b.eq read_decimal_end
    cmp w6, #'0'
    b.lt read_decimal_end
    cmp w6, #'9'
    b.gt read_decimal_end
    sub w6, w6, #'0'
    add x2, x2, x6              // second decimal

read_decimal_end:
    mov x0, x2
    ldp x29, x30, [sp], #16
    ret

read_decimal_end_data:
    mov x0, #-1
    ldp x29, x30, [sp], #16
    ret

// Function itoa_decimal - VERSION CORREGIDA PARA MULTIPLES DIGITOS
itoa_decimal:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    mov w4, w0                  // w4 = number
    mov x3, x1                  // x3 = buffer pointer
    
    // Get integer part: number / 100
    mov w5, #100
    udiv w6, w4, w5             // w6 = integer part
    
    // Convert integer part to string using itoa
    mov x0, x6                  // integer part
    mov x1, x3                  // buffer
    bl itoa
    
    // Find end of integer part
    mov x2, #0
find_end:
    ldrb w8, [x3, x2]
    cbz w8, found_end
    add x2, x2, #1
    b find_end
found_end:
    
    // Add decimal point
    mov w8, #'.'
    strb w8, [x3, x2]
    add x2, x2, #1
    
    // Get decimal part: number % 100
    mov w5, #100
    udiv w7, w4, w5             // w7 = integer part again
    mul w8, w7, w5              // w8 = integer_part * 100
    sub w7, w4, w8              // w7 = decimal part
    
    // First decimal digit: decimal_part / 10
    mov w5, #10
    udiv w8, w7, w5             // w8 = first decimal digit
    add w8, w8, #'0'            // convert to ASCII
    strb w8, [x3, x2]
    add x2, x2, #1
    
    // Second decimal digit: decimal_part % 10
    mov w5, #10
    udiv w9, w7, w5             // w9 = first decimal digit again
    mul w10, w9, w5             // w10 = first_decimal * 10
    sub w7, w7, w10             // w7 = second decimal digit
    add w7, w7, #'0'            // convert to ASCII
    strb w7, [x3, x2]
    add x2, x2, #1
    
    // Null terminate
    strb wzr, [x3, x2]
    
    ldp x29, x30, [sp], #16
    ret

// Function itoa (convert number to string)
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

// Function write_string (write string)
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
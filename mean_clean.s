.section .data
input_file:     .asciz "datos.txt"
output_file:    .asciz "mean.txt"
buffer:         .space 256
newline:        .asciz "\n"

.section .text
.global _start

_start:
    mov x29, sp
    and sp, x29, #~15
    sub sp, sp, #16

    // Open file
    mov x0, #-100
    ldr x1, =input_file
    mov x2, #0
    mov x8, #56
    svc #0
    cmp x0, #0
    b.lt error
    mov x19, x0

    // Read file
    mov x0, x19
    ldr x1, =buffer
    mov x2, #256
    mov x8, #63
    svc #0
    cmp x0, #0
    b.le error

    // Parse numbers
    ldr x1, =buffer
    mov x20, #0                 // sum
    mov x21, #0                 // count

parse_loop:
    bl read_decimal
    cmp x0, #-1
    beq parse_end
    add x20, x20, x0            // sum += number * 100
    add x21, x21, #1            // count++
    b parse_loop

parse_end:
    cmp x21, #0
    b.eq error
    sdiv x22, x20, x21          // mean = sum / count

    // Open output file
    mov x0, #-100
    ldr x1, =output_file
    mov x2, #577
    mov x3, #0644
    mov x8, #56
    svc #0
    cmp x0, #0
    b.lt error
    mov x23, x0

    // Write result
    mov x0, x22
    ldr x1, =buffer
    bl format_decimal
    mov x0, x23
    ldr x1, =buffer
    bl write_string

    // Print to console
    mov x0, #1
    ldr x1, =buffer
    bl write_string
    mov x0, #1
    ldr x1, =newline
    bl write_string

    // Write newline to file
    mov x0, x23
    ldr x1, =newline
    bl write_string

    // Close files
    mov x0, x19
    mov x8, #57
    svc #0
    mov x0, x23
    mov x8, #57
    svc #0

    // Exit
    mov x0, #0
    mov x8, #93
    svc #0

error:
    mov x0, #1
    mov x8, #93
    svc #0

// Simple decimal reader - CLEAN VERSION
read_decimal:
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

// Format decimal number
format_decimal:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    mov w4, w0                  // number
    mov x3, x1                  // buffer
    
    // Integer part
    mov w5, #100
    udiv w6, w4, w5
    mov x0, x6
    mov x1, x3
    bl itoa
    
    // Find end
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
    
    // Decimal part
    mov w5, #100
    udiv w7, w4, w5
    mul w8, w7, w5
    sub w7, w4, w8              // decimal part
    
    // First decimal digit
    mov w5, #10
    udiv w8, w7, w5
    add w8, w8, #'0'
    strb w8, [x3, x2]
    add x2, x2, #1
    
    // Second decimal digit
    mov w5, #10
    udiv w9, w7, w5
    mul w10, w9, w5
    sub w7, w7, w10
    add w7, w7, #'0'
    strb w7, [x3, x2]
    add x2, x2, #1
    
    // Null terminate
    strb wzr, [x3, x2]
    
    ldp x29, x30, [sp], #16
    ret

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
.section .data
input_file:     .asciz "datos.txt"
debug_msg:      .asciz "Numero leido: "
newline:        .asciz "\n"
buffer:         .space 256

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

    // Parse and debug each number
    ldr x1, =buffer
    mov x20, #0                 // sum
    mov x21, #0                 // count

parse_loop:
    mov x0, x1
    bl atoi_nl_dollar
    cmp x0, #-1
    beq parse_end
    
    // Print debug message
    mov x22, x0                 // save number
    mov x0, #1
    ldr x1, =debug_msg
    mov x2, #14
    mov x8, #64
    svc #0
    
    // Print number with decimals
    mov x0, x22
    ldr x1, =buffer
    bl itoa_decimal
    mov x0, #1
    ldr x1, =buffer
    bl write_string
    mov x0, #1
    ldr x1, =newline
    mov x2, #1
    mov x8, #64
    svc #0
    
    add x20, x20, x22           // sum += number
    add x21, x21, #1            // count++
    
advance_nl:
    ldrb w2, [x1], #1
    cmp w2, #10
    b.ne advance_nl
    b parse_loop

parse_end:
    // Calculate and show mean
    sdiv x22, x20, x21
    mov x0, #1
    ldr x1, =debug_msg
    mov x2, #14
    mov x8, #64
    svc #0
    
    mov x0, x22
    ldr x1, =buffer
    bl itoa_decimal
    mov x0, #1
    ldr x1, =buffer
    bl write_string
    
    mov x0, #0
    mov x8, #93
    svc #0

error:
    mov x0, #1
    mov x8, #93
    svc #0

// Include the same atoi_nl_dollar and itoa_decimal functions from mean.s
atoi_nl_dollar:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    mov x2, #0                  // integer part
    mov x3, #0                  // decimal part
    mov x4, #0                  // decimal places counter
    
    // Read integer part
integer_loop:
    ldrb w5, [x0], #1
    cmp w5, #'.'
    b.eq decimal_part
    cmp w5, #'$'
    b.eq atoi_nl_dollar_end_of_data
    cmp w5, #10                 // '\n'
    b.eq atoi_nl_dollar_end
    cmp w5, #0
    b.eq atoi_nl_dollar_end
    sub w5, w5, #'0'
    mov x6, #10
    mul x2, x2, x6
    add x2, x2, x5
    b integer_loop
    
decimal_part:
    cmp x4, #2                  // max 2 decimal places
    b.ge atoi_nl_dollar_end
    ldrb w5, [x0], #1
    cmp w5, #'$'
    b.eq atoi_nl_dollar_end_of_data
    cmp w5, #10                 // '\n'
    b.eq atoi_nl_dollar_end
    cmp w5, #0
    b.eq atoi_nl_dollar_end
    sub w5, w5, #'0'
    mov x6, #10
    mul x3, x3, x6
    add x3, x3, x5
    add x4, x4, #1
    b decimal_part
    
atoi_nl_dollar_end:
    // Convert to number*100
    mov x6, #100
    mul x2, x2, x6              // integer part * 100
    
    // Adjust decimal part based on places read
    cmp x4, #1
    b.eq one_decimal
    cmp x4, #2
    b.eq two_decimals
    b combine_parts             // no decimals
    
one_decimal:
    mov x6, #10
    mul x3, x3, x6              // scale up to 2 decimal places
    b combine_parts
    
two_decimals:
    // already scaled correctly
    
combine_parts:
    add x0, x2, x3              // result = (integer*100) + decimal_part
    ldp x29, x30, [sp], #16
    ret
    
atoi_nl_dollar_end_of_data:
    mov x0, #-1
    ldp x29, x30, [sp], #16
    ret

itoa_decimal:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    mov w4, w0                  // w4 = number * 100 (use 32-bit)
    mov x3, x1                  // x3 = buffer pointer
    
    // Get integer part (divide by 100)
    mov w5, #100
    udiv w6, w4, w5             // w6 = integer part
    mul w8, w6, w5              // w8 = w6 * 100
    sub w7, w4, w8              // w7 = decimal part (remainder)
    
    // Convert integer part to string
    mov x0, x6                  // extend w6 to x0
    mov x1, x3
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
    
    // Add decimal digits (always 2 digits)
    mov w5, #10
    udiv w9, w7, w5             // First decimal digit (w7 / 10)
    add w9, w9, #'0'
    strb w9, [x3, x2]
    add x2, x2, #1
    
    mul w8, w9, w5              // Remove the already added '0' first
    sub w9, w9, #'0'            // Get back to number
    mul w8, w9, w5              // w8 = (first digit) * 10
    sub w7, w7, w8              // Second decimal digit = w7 - w8
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
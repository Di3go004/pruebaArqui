.section .data
input_file:     .asciz "datos.txt"
debug_msg:      .asciz "Numero: "
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

    // Parse and debug each decimal number
    ldr x1, =buffer
    mov x20, #0                 // sum
    mov x21, #0                 // count

parse_loop:
    bl atoi_nl_dollar_advance
    cmp x0, #-1
    beq parse_end
    
    // Print debug message
    mov x22, x0                 // save number
    mov x0, #1
    ldr x1, =debug_msg
    mov x2, #8
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
    b parse_loop

parse_end:
    mov x0, #0
    mov x8, #93
    svc #0

error:
    mov x0, #1
    mov x8, #93
    svc #0

// Same functions from mean.s
atoi_nl_dollar_advance:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    mov x2, #0                  // result
    
    // Read integer part
integer_loop_adv:
    ldrb w6, [x1], #1          // read and advance x1 globally
    cmp w6, #'.'
    b.eq decimal_part_adv
    cmp w6, #'$'
    b.eq atoi_nl_dollar_end_of_data_adv
    cmp w6, #10                 // '\n'
    b.eq atoi_nl_dollar_end_adv
    cmp w6, #0
    b.eq atoi_nl_dollar_end_adv
    cmp w6, #'0'               // check if it's a digit
    b.lt atoi_nl_dollar_end_adv
    cmp w6, #'9'
    b.gt atoi_nl_dollar_end_adv
    sub w6, w6, #'0'
    mov x7, #10
    mul x2, x2, x7
    add x2, x2, x6
    b integer_loop_adv
    
decimal_part_adv:
    // Multiply integer part by 100 first
    mov x7, #100
    mul x2, x2, x7
    
    // Read first decimal digit
    ldrb w6, [x1], #1          // advance x1 globally
    cmp w6, #'$'
    b.eq atoi_nl_dollar_end_of_data_adv
    cmp w6, #10                 // '\n'
    b.eq atoi_nl_dollar_end_adv
    cmp w6, #0
    b.eq atoi_nl_dollar_end_adv
    cmp w6, #'0'
    b.lt atoi_nl_dollar_end_adv
    cmp w6, #'9'
    b.gt atoi_nl_dollar_end_adv
    sub w6, w6, #'0'
    mov x7, #10
    mul x6, x6, x7              // first decimal * 10
    add x2, x2, x6
    
    // Read second decimal digit
    ldrb w6, [x1], #1          // advance x1 globally
    cmp w6, #'$'
    b.eq atoi_nl_dollar_end_of_data_adv
    cmp w6, #10                 // '\n'
    b.eq atoi_nl_dollar_end_adv
    cmp w6, #0
    b.eq atoi_nl_dollar_end_adv
    cmp w6, #'0'
    b.lt atoi_nl_dollar_end_adv
    cmp w6, #'9'
    b.gt atoi_nl_dollar_end_adv
    sub w6, w6, #'0'
    add x2, x2, x6              // add second decimal digit
    
atoi_nl_dollar_end_adv:
    // Skip any trailing whitespace/newlines to get to next number
skip_whitespace:
    ldrb w6, [x1]               // peek at next character (don't advance yet)
    cmp w6, #10                 // '\n'
    b.eq skip_char
    cmp w6, #13                 // '\r'
    b.eq skip_char
    cmp w6, #32                 // space
    b.eq skip_char
    b return_result             // not whitespace, return result

skip_char:
    add x1, x1, #1              // advance past whitespace
    b skip_whitespace

return_result:
    mov x0, x2
    ldp x29, x30, [sp], #16
    ret
    
atoi_nl_dollar_end_of_data_adv:
    mov x0, #-1
    ldp x29, x30, [sp], #16
    ret

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
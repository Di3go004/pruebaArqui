.section .data
buffer:         .space 256
newline:        .asciz "\n"

.section .text
.global _start

_start:
    mov x29, sp
    and sp, x29, #~15
    sub sp, sp, #16

    // Test itoa_decimal with 325
    mov x0, #325
    ldr x1, =buffer
    bl itoa_decimal
    
    // Print result
    mov x0, #1
    ldr x1, =buffer
    bl write_string
    mov x0, #1
    ldr x1, =newline
    mov x2, #1
    mov x8, #64
    svc #0

    mov x0, #0
    mov x8, #93
    svc #0

// Function itoa_decimal - VERSION MANUAL SIMPLE
itoa_decimal:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    mov w4, w0                  // w4 = 325
    mov x3, x1                  // x3 = buffer pointer
    
    // Manual conversion for 325
    // Integer part: 325 / 100 = 3
    mov w5, #100
    udiv w6, w4, w5             // w6 = 3
    
    // Convert integer part manually
    add w6, w6, #'0'            // '3'
    strb w6, [x3], #1
    
    // Add decimal point
    mov w8, #'.'
    strb w8, [x3], #1
    
    // Decimal part: 325 % 100 = 25
    mov w5, #100
    udiv w7, w4, w5             // w7 = 3
    mul w8, w7, w5              // w8 = 300
    sub w7, w4, w8              // w7 = 325 - 300 = 25
    
    // First decimal: 25 / 10 = 2
    mov w5, #10
    udiv w8, w7, w5             // w8 = 2
    add w8, w8, #'0'            // '2'
    strb w8, [x3], #1
    
    // Second decimal: 25 % 10 = 5
    mov w5, #10
    udiv w9, w7, w5             // w9 = 2
    mul w10, w9, w5             // w10 = 20
    sub w7, w7, w10             // w7 = 25 - 20 = 5
    add w7, w7, #'0'            // '5'
    strb w7, [x3], #1
    
    // Null terminate
    strb wzr, [x3]
    
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
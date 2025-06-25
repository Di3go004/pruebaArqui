.section .data
input_file:     .asciz "test.txt"
debug_count:    .asciz "Count: "
debug_sum:      .asciz "Sum: "
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

    // Parse numbers
    ldr x1, =buffer
    mov x20, #0                 // sum
    mov x21, #0                 // count

parse_loop:
    bl atoi_simple_advance
    cmp x0, #-1
    beq parse_end
    add x20, x20, x0            // sum += number
    add x21, x21, #1            // count++
    b parse_loop

parse_end:
    // Show count
    mov x0, #1
    ldr x1, =debug_count
    mov x2, #7
    mov x8, #64
    svc #0
    
    mov x0, x21
    ldr x1, =buffer
    bl itoa
    mov x0, #1
    ldr x1, =buffer
    bl write_string
    mov x0, #1
    ldr x1, =newline
    mov x2, #1
    mov x8, #64
    svc #0
    
    // Show sum
    mov x0, #1
    ldr x1, =debug_sum
    mov x2, #5
    mov x8, #64
    svc #0
    
    mov x0, x20
    ldr x1, =buffer
    bl itoa
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

error:
    mov x0, #1
    mov x8, #93
    svc #0

// Same functions as in mean.s
atoi_simple_advance:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    mov x2, #0                  // result
    
    // Skip any leading whitespace
skip_leading:
    ldrb w6, [x1]               // peek at character
    cmp w6, #10                 // '\n'
    b.eq skip_leading_char
    cmp w6, #13                 // '\r'
    b.eq skip_leading_char
    cmp w6, #32                 // space
    b.eq skip_leading_char
    b read_digits               // start reading digits

skip_leading_char:
    add x1, x1, #1              // skip whitespace
    b skip_leading

read_digits:
    ldrb w6, [x1], #1          // read and advance x1 globally
    cmp w6, #'$'
    b.eq atoi_simple_end_of_data
    cmp w6, #10                 // '\n'
    b.eq atoi_simple_end
    cmp w6, #0
    b.eq atoi_simple_end
    cmp w6, #'0'               // check if it's a digit
    b.lt atoi_simple_end
    cmp w6, #'9'
    b.gt atoi_simple_end
    sub w6, w6, #'0'
    mov x7, #10
    mul x2, x2, x7
    add x2, x2, x6
    b read_digits
    
atoi_simple_end:
    mov x0, x2
    ldp x29, x30, [sp], #16
    ret
    
atoi_simple_end_of_data:
    mov x0, #-1
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
.section .data
input_file:     .asciz "datos.txt"
buffer:         .space 256
char_msg:       .asciz "Char: "
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

    // Show first 50 characters from buffer
    ldr x1, =buffer
    mov x20, #0                 // counter

show_chars:
    cmp x20, #50               // show first 50 chars
    b.ge end_debug
    
    ldrb w2, [x1, x20]         // read character
    cmp w2, #0                 // check for null
    b.eq end_debug
    
    // Print "Char: "
    mov x0, #1
    ldr x1, =char_msg
    mov x2, #6
    mov x8, #64
    svc #0
    
    // Print the character
    mov x0, #1
    ldr x1, =buffer
    add x1, x1, x20            // point to current char
    mov x2, #1
    mov x8, #64
    svc #0
    
    // Print ASCII value
    mov x0, #1
    ldr x1, =buffer
    add w3, w2, #'0'           // simple conversion for small numbers
    strb w3, [x1]
    strb wzr, [x1, #1]
    mov x2, #1
    mov x8, #64
    svc #0
    
    // Print newline
    mov x0, #1
    ldr x1, =newline
    mov x2, #1
    mov x8, #64
    svc #0
    
    add x20, x20, #1
    b show_chars

end_debug:
    mov x0, #0
    mov x8, #93
    svc #0

error:
    mov x0, #1
    mov x8, #93
    svc #0
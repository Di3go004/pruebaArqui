.section .data
input_file:     .asciz "datos.txt"    // Input file name
output_file:    .asciz "maximo.txt"   // Output file name
buffer:         .space 256            // Buffer space (256 bytes)
output_buffer:  .space 256            // Output buffer space
comma:          .asciz ","            // Comma string
newline:        .asciz "\n"           // Newline string

.section .text
.global _start

_start:
    // Align stack to 16 bytes
    mov x29, sp
    and sp, x29, #~15
    sub sp, sp, #16

    // Open input.txt for reading
    mov x0, #-100               // AT_FDCWD (current directory)
    ldr x1, =input_file         // File name address
    mov x2, #0                  // O_RDONLY (read-only mode)
    mov x8, #56                 // syscall: openat
    svc #0                      // System call
    cmp x0, #0
    b.lt error                  // If x0 is negative, jump to error
    mov x9, x0                  // Save file descriptor in x9

    // Read from file
    mov x0, x9                  // File descriptor in x0
    ldr x1, =buffer             // Buffer address in x1
    mov x2, #256                // Buffer size in x2
    mov x8, #63                 // syscall: read
    svc #0                      // System call
    cmp x0, #0
    b.le error                  // If x0 is zero or negative, jump to error
    mov x19, x0                 // Save number of bytes read in x19

    // Parse numbers and find maximum (line by line format with $ at end)
    mov x20, #0x8000000000000000 // Initialize to minimum possible value
    ldr x1, =buffer             // Buffer address in x1
    mov x21, #0                 // Flag to track if we found any number

parse_loop:
    mov x0, x1                  // Pass buffer address to x0
    bl atoi_nl_dollar           // Convert string to number using new format
    cmp x0, #-1                 // Check if end of data ($)
    beq parse_end               // If end marker found, finish

    cmp x21, #0                 // Check if this is the first number
    b.ne compare_max            // If not first, compare normally
    mov x20, x0                 // If first number, set as maximum
    mov x21, #1                 // Mark that we found a number
    b advance_nl

compare_max:
    cmp x0, x20                 // Compare with current maximum
    csel x20, x0, x20, gt       // Update maximum if new number is greater
    
    // Advance to next line
advance_nl:
    ldrb w2, [x1], #1           // Read a byte from buffer and advance
    cmp w2, #10                 // Compare with '\n'
    b.ne advance_nl             // Continue until newline found
    b parse_loop                // Process next number
    
    // End of parsing
parse_end:

parse_end:
    // Convert maximum to string
    mov x0, x20                 // Pass maximum to x0
    ldr x1, =output_buffer      // Output buffer address in x1
    bl itoa                     // Call itoa function

    // Open output.txt for writing
    mov x0, #-100               // AT_FDCWD (current directory)
    ldr x1, =output_file        // File name address
    mov x2, #577                // O_WRONLY | O_CREAT | O_TRUNC
    mov x3, #0644               // File permissions
    mov x8, #56                 // syscall: openat
    svc #0                      // System call
    cmp x0, #0
    b.lt error                  // If x0 is negative, jump to error
    mov x10, x0                 // Save file descriptor in x10

    // Write result to file
    mov x0, x10                 // File descriptor in x0
    ldr x1, =output_buffer      // Buffer address in x1
    bl write_string             // Call write_string function

    // Mostrar resultado en consola
    mov x0, #1                  // stdout
    ldr x1, =output_buffer      // Buffer address in x1
    bl write_string             // Call write_string function

    // Write newline to file
    mov x0, x10                 // File descriptor in x0
    ldr x1, =newline            // Newline address in x1
    bl write_string             // Call write_string function

    // Close files
    mov x0, x9                  // input.txt descriptor in x0
    mov x8, #57                 // syscall: close
    svc #0                      // System call

    mov x0, x10                 // output.txt descriptor in x0
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

// Function atoi_nl_dollar (convert string to number, line by line format)
atoi_nl_dollar:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    mov x2, #0                  // result = 0
    mov x4, #0                  // sign flag (0 = positive, 1 = negative)

    // Check for negative sign
    ldrb w5, [x0]
    cmp w5, #'-'
    b.ne atoi_nl_loop
    mov x4, #1                  // set negative flag
    add x0, x0, #1              // skip the minus sign

atoi_nl_loop:
    ldrb w3, [x0], #1
    cmp w3, #'$'
    b.eq atoi_nl_dollar_end_of_data
    cmp w3, #10                 // '\n'
    b.eq atoi_nl_dollar_end
    cmp w3, #0
    b.eq atoi_nl_dollar_end
    sub w3, w3, #'0'
    cmp w3, #9
    b.hi atoi_nl_dollar_end
    mov x5, #10
    mul x2, x2, x5
    add x2, x2, x3
    b atoi_nl_loop

atoi_nl_dollar_end:
    // Apply sign
    cmp x4, #1
    b.ne atoi_nl_positive
    neg x2, x2                  // make negative

atoi_nl_positive:
    mov x0, x2
    ldp x29, x30, [sp], #16
    ret

atoi_nl_dollar_end_of_data:
    mov x0, #-1
    ldp x29, x30, [sp], #16
    ret

// Function itoa (convert number to string)
itoa:
    // Save return registers
    stp x29, x30, [sp, #-16]!   // Save x29 and x30 on stack
    mov x29, sp                 // Update stack frame pointer

    // Initialization
    mov x2, #10                 // base = 10
    mov x3, x1                  // Buffer start pointer
    mov x4, x0                  // Original number

itoa_loop:
    udiv x0, x4, x2             // x0 = x4 / 10
    msub x5, x0, x2, x4         // x5 = x4 - x0 * 10 (remainder)
    add x5, x5, #'0'            // Convert digit to character
    strb w5, [x3], #1           // Write character to buffer
    mov x4, x0                  // x4 = x0 (divided by 10)
    cbz x0, itoa_end            // If x0 is 0, end

    b itoa_loop                 // Repeat cycle

itoa_end:
    strb wzr, [x3]              // Terminate string with '\0'

    // Reverse string in buffer
    sub x3, x3, #1
    mov x4, x1                  // Pointer to buffer start
    mov x5, x3                  // Pointer to buffer end
itoa_reverse:
    ldrb w6, [x4]               // Read character from start
    ldrb w7, [x5]               // Read character from end
    strb w7, [x4]               // Write end character to start
    strb w6, [x5]               // Write start character to end
    add x4, x4, #1              // Move forward
    sub x5, x5, #1              // Move backward
    cmp x4, x5                  // Compare pointers
    b.lo itoa_reverse           // Repeat if not crossed

    // Restore return registers
    ldp x29, x30, [sp], #16     // Restore x29 and x30 from stack
    ret                         // Return from function

// Function write_string (write string)
write_string:
    // Save return registers
    stp x29, x30, [sp, #-16]!   // Save x29 and x30 on stack
    mov x29, sp                 // Update stack frame pointer

    // Calculate string length
    mov x2, #0
strlen_loop:
    ldrb w3, [x1, x2]           // Read byte from x1 plus offset x2
    cbz w3, strlen_done         // If byte is zero (end of string), end
    add x2, x2, #1              // Increment length
    b strlen_loop               // Repeat cycle

strlen_done:
    // Write string
    mov x8, #64                 // syscall: write
    svc #0                      // System call

    // Restore return registers
    ldp x29, x30, [sp], #16     // Restore x29 and x30 from stack
    ret                         // Return from function
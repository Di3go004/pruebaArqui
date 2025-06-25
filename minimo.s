.section .data
input_file:     .asciz "datos.txt"    // Input file name
output_file:    .asciz "minimo.txt"    // Output file name
buffer:         .space 1024           // Increased buffer size
error_msg:      .asciz "Error: No hay suficientes números para encontrar el mínimo.\n"
newline:        .asciz "\n"           // Newline string
numbers:        .space 4096           // Space for up to 1024 integers
count:          .quad 0               // Count of numbers

.section .text
.global _start

_start:
    // Open input file for reading
    mov x0, #-100               // AT_FDCWD (current directory)
    ldr x1, =input_file         // File name address
    mov x2, #0                  // O_RDONLY (read-only mode)
    mov x8, #56                 // syscall: openat
    svc #0                      // System call
    mov x9, x0                  // Save file descriptor in x9
    cmp x9, #0
    b.lt error                  // If x9 is negative, jump to error

    // Read from file
    mov x0, x9                  // File descriptor in x0
    ldr x1, =buffer             // Buffer address in x1
    mov x2, #1024               // Increased buffer size
    mov x8, #63                 // syscall: read
    svc #0                      // System call
    mov x19, x0                 // Save number of bytes read in x19
    cmp x19, #0
    b.le error                  // If x19 is 0 or negative, jump to error

    // Parse numbers and find minimum
    ldr x22, =numbers           // Load address of numbers array
    mov x21, #0                 // Initialize count to zero
    ldr x1, =buffer             // Reset buffer pointer
    mov x20, #0x7FFFFFFF        // Initialize minimum with max 32-bit int
parse_loop:
    mov x0, x1
    bl atoi_nl_dollar
    cmp x0, #-1
    beq parse_end
    str w0, [x22], #4           // Store number in array and advance pointer
    add x21, x21, #1            // Increment count
    cmp w0, w20                 // Compare with current minimum
    csel w20, w0, w20, lt       // Update minimum if necessary
    // Avanzar x1 hasta después del salto de línea
advance_nl:
    ldrb w2, [x1], #1
    cmp w2, #10         // '\n'
    b.ne advance_nl
    b parse_loop
parse_end:
    ldr x25, =count
    str x21, [x25]              // Store final count

    // Check if we have enough numbers
    cmp x21, #1
    b.le not_enough_numbers

    // Convert the smallest number to string
    mov x0, x20                 // Pass smallest number to x0
    ldr x1, =buffer             // Buffer address in x1
    bl itoa                     // Call itoa function

    // Open output file for writing
    mov x0, #-100               // AT_FDCWD (current directory)
    ldr x1, =output_file        // File name address
    mov x2, #577                // O_WRONLY | O_CREAT | O_TRUNC
    mov x3, #0644               // File permissions
    mov x8, #56                 // syscall: openat
    svc #0                      // System call
    mov x10, x0                 // Save file descriptor in x10
    cmp x10, #0
    b.lt error                  // If x10 is negative, jump to error

    // Write the smallest number to the file
    mov x0, x10                 // File descriptor in x0
    ldr x1, =buffer             // Buffer address in x1
    bl write_string             // Call write_string function

    // Mostrar resultado en consola
    mov x0, #1                  // stdout
    ldr x1, =buffer             // Buffer address in x1
    bl write_string             // Call write_string function

    b close_and_exit

not_enough_numbers:
    // Open output file for writing
    mov x0, #-100               // AT_FDCWD (current directory)
    ldr x1, =output_file        // File name address
    mov x2, #577                // O_WRONLY | O_CREAT | O_TRUNC
    mov x3, #0644               // File permissions
    mov x8, #56                 // syscall: openat
    svc #0                      // System call
    mov x10, x0                 // Save file descriptor in x10
    cmp x10, #0
    b.lt error                  // If x10 is negative, jump to error

    // Write error message to file
    mov x0, x10                 // File descriptor in x0
    ldr x1, =error_msg          // Error message address in x1
    bl write_string             // Call write_string function

    b close_and_exit

error:
    // Handle error and exit
    mov x0, #1                  // Write to stdout
    ldr x1, =error_msg          // Error message address
    mov x2, #58                 // Length of error message
    mov x8, #64                 // syscall: write
    svc #0

close_and_exit:
    // Close files
    mov x0, x9                  // input file descriptor in x0
    mov x8, #57                 // syscall: close
    svc #0                      // System call

    mov x0, x10                 // output file descriptor in x0
    mov x8, #57                 // syscall: close
    svc #0                      // System call

    // Exit program
    mov x0, #0                  // Exit code in x0
    mov x8, #93                 // syscall: exit
    svc #0                      // System call

// Function atoi (convert string to number)
atoi_nl_dollar:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    mov x2, #0
atoi_nl_loop:
    ldrb w3, [x0], #1
    cmp w3, #'$'
    b.eq atoi_nl_dollar_end_of_data
    cmp w3, #10 // '\n'
    b.eq atoi_nl_dollar_end
    cmp w3, #0
    b.eq atoi_nl_dollar_end
    sub w3, w3, #'0'
    cmp w3, #9
    b.hi atoi_nl_dollar_end
    mov x4, #10
    mul x2, x2, x4
    add x2, x2, x3
    b atoi_nl_loop
atoi_nl_dollar_end:
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

    // Handle negative numbers
    cmp x4, #0
    b.ge positive
    neg x4, x4                  // Make number positive
    mov w5, #'-'
    strb w5, [x3], #1           // Store '-' and advance pointer

positive:
    // Convert digits
    mov x5, x3                  // Remember start of digits

itoa_loop:
    udiv x6, x4, x2             // Divide by base
    msub x7, x6, x2, x4         // Get remainder
    add w7, w7, #'0'            // Convert to ASCII
    strb w7, [x3], #1           // Store digit and advance pointer
    mov x4, x6                  // Update number
    cbnz x4, itoa_loop          // If number is not zero, continue

    // Null-terminate the string
    mov w7, #0
    strb w7, [x3]

    // Reverse the digits
    sub x3, x3, #1              // Point to last digit
reverse_loop:
    cmp x5, x3
    b.ge itoa_end
    ldrb w6, [x5]
    ldrb w7, [x3]
    strb w7, [x5], #1
    strb w6, [x3], #-1
    b reverse_loop

itoa_end:
    // Restore return registers
    ldp x29, x30, [sp], #16     // Restore x29 and x30 from stack
    ret                         // Return from function

// Function write_string (write null-terminated string to file)
write_string:
    // Save return registers
    stp x29, x30, [sp, #-16]!   // Save x29 and x30 on stack
    mov x29, sp                 // Update stack frame pointer

    // Calculate string length
    mov x2, #0                  // Initialize length to 0
length_loop:
    ldrb w3, [x1, x2]           // Load byte from string
    cbz w3, write               // If null terminator, exit loop
    add x2, x2, #1              // Increment length
    b length_loop

write:
    mov x8, #64                 // syscall: write
    svc #0                      // System call

    // Restore return registers
    ldp x29, x30, [sp], #16     // Restore x29 and x30 from stack
    ret                         // Return from function
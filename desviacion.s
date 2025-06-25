.section .data
input_file:     .asciz "datos.txt"    // Input file name
mean_file:      .asciz "mean.txt"     // Mean file name
output_file:    .asciz "desviacion.txt"   // Output file name
buffer:         .space 256            // Buffer space (256 bytes)
newline:        .asciz "\n"           // Newline string

.section .text
.global _start

_start:
    // Align stack to 16 bytes
    mov x29, sp
    and sp, x29, #~15
    sub sp, sp, #16

    // Open mean.txt for reading
    mov x0, #-100               // AT_FDCWD (current directory)
    ldr x1, =mean_file          // File name address
    mov x2, #0                  // O_RDONLY (read-only mode)
    mov x8, #56                 // syscall: openat
    svc #0                      // System call
    cmp x0, #0
    b.lt error                  // If x0 is negative, jump to error
    mov x9, x0                  // Save file descriptor in x9

    // Read from mean.txt
    mov x0, x9                  // File descriptor in x0
    ldr x1, =buffer             // Buffer address in x1
    mov x2, #256                // Buffer size in x2
    mov x8, #63                 // syscall: read
    svc #0                      // System call
    cmp x0, #0
    b.le error                  // If x0 is zero or negative, jump to error

    // Convert mean from string to number
    ldr x0, =buffer
    bl atoi
    mov x20, x0                 // Save mean value in x20

    // Close mean.txt file
    mov x0, x9
    mov x8, #57                 // syscall: close
    svc #0                      // System call

    // Open datos.txt for reading
    mov x0, #-100               // AT_FDCWD (current directory)
    ldr x1, =input_file         // File name address
    mov x2, #0                  // O_RDONLY (read-only mode)
    mov x8, #56                 // syscall: openat
    svc #0                      // System call
    cmp x0, #0
    b.lt error                  // If x0 is negative, jump to error
    mov x9, x0                  // Save file descriptor in x9

    // Read from datos.txt
    mov x0, x9                  // File descriptor in x0
    ldr x1, =buffer             // Buffer address in x1
    mov x2, #256                // Buffer size in x2
    mov x8, #63                 // syscall: read
    svc #0                      // System call
    cmp x0, #0
    b.le error                  // If x0 is zero or negative, jump to error
    mov x19, x0                 // Save number of bytes read in x19

    // Calculate (xi - mean)^2 and sum them (line by line format)
    mov x21, #0                 // Initialize count to zero
    mov x22, #0                 // Initialize sum to zero
    ldr x1, =buffer             // Buffer address in x1

parse_loop:
    mov x0, x1                  // Pass buffer address to x0
    bl atoi_nl_dollar           // Convert string to number
    cmp x0, #-1                 // Check if end of data ($)
    beq parse_end               // If end marker found, finish

    sub x0, x0, x20             // xi - mean
    mul x0, x0, x0              // (xi - mean)^2

    add x22, x22, x0            // Add to total
    add x21, x21, #1            // Increment count
    
    // Advance to next line
advance_nl:
    ldrb w2, [x1], #1           // Read a byte from buffer and advance
    cmp w2, #10                 // Compare with '\n'
    b.ne advance_nl             // Continue until newline found
    b parse_loop                // Process next number
    
    // End of parsing
    b parse_end

parse_end:
    cmp x21, #0
    b.eq error                  // Avoid division by zero
    
    // Calculate variance: sum_of_squares / count
    sdiv x22, x22, x21          // variance = sum_of_squares / count
    
    // Calculate standard deviation (approximation using integer arithmetic)
    // For simplicity, we'll use a basic square root approximation
    mov x0, x22                 // Pass variance to square root function
    bl integer_sqrt             // Calculate approximate square root
    mov x23, x0                 // Save standard deviation result

    // Open desviacion.txt for writing
    mov x0, #-100               // AT_FDCWD (current directory)
    ldr x1, =output_file        // File name address
    mov x2, #577                // O_WRONLY | O_CREAT | O_TRUNC
    mov x3, #0644               // File permissions
    mov x8, #56                 // syscall: openat
    svc #0                      // System call
    cmp x0, #0
    b.lt error                  // If x0 is negative, jump to error
    mov x10, x0                 // Save file descriptor in x10

    // Convert result to string and write to file
    mov x0, x23                 // Pass standard deviation to x0
    ldr x1, =buffer             // Use buffer for output
    bl itoa                     // Convert integer to string
    mov x0, x10                 // File descriptor in x0
    ldr x1, =buffer             // String to write
    bl write_string             // Call write_string function

    // Mostrar resultado en consola
    mov x0, #1                  // stdout
    ldr x1, =buffer             // String to print
    bl write_string             // Call write_string function

    // Write newline to file
    mov x0, x10                 // File descriptor in x0
    ldr x1, =newline            // Newline string
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

// Function atoi_nl_dollar (convert string to number)
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

// Function integer_sqrt (calculate integer square root using Newton's method)
integer_sqrt:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    
    cmp x0, #0
    b.eq sqrt_zero
    cmp x0, #1
    b.eq sqrt_one
    
    // Initial guess: x/2
    lsr x1, x0, #1              // x1 = n/2 (initial guess)
    mov x2, x0                  // x2 = n (original number)
    mov x5, #10                 // Maximum iterations to prevent infinite loop
    
sqrt_loop:
    // Newton's method: x_new = (x_old + n/x_old) / 2
    udiv x3, x2, x1             // x3 = n / x_old
    add x3, x3, x1              // x3 = x_old + n/x_old
    lsr x3, x3, #1              // x3 = (x_old + n/x_old) / 2
    
    // Check if converged (difference <= 1)
    subs x4, x1, x3             // x4 = x_old - x_new
    cmp x4, #1
    b.le sqrt_done
    cmp x4, #0
    b.eq sqrt_done
    
    mov x1, x3                  // Update guess
    subs x5, x5, #1             // Decrement iteration counter
    cbnz x5, sqrt_loop          // Continue if iterations remain
    
sqrt_done:
    mov x0, x3                  // Return result
    b sqrt_end
    
sqrt_zero:
    mov x0, #0
    b sqrt_end
    
sqrt_one:
    mov x0, #1
    
sqrt_end:
    ldp x29, x30, [sp], #16
    ret

// Function atoi (convert string to number)
atoi:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    mov x2, #0
atoi_simple_loop:
    ldrb w3, [x0], #1
    cmp w3, #0
    b.eq atoi_simple_end
    cmp w3, #10 // '\n'
    b.eq atoi_simple_end
    sub w3, w3, #'0'
    cmp w3, #9
    b.hi atoi_simple_end
    mov x4, #10
    mul x2, x2, x4
    add x2, x2, x3
    b atoi_simple_loop
atoi_simple_end:
    mov x0, x2
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

// Function strlen (calculate string length)
strlen:
    mov x2, x0                  // Save start of string
strlen_loop2:                   // Changed from strlen_loop to strlen_loop2
    ldrb w1, [x0], #1           // Load byte and increment pointer
    cbnz w1, strlen_loop2       // Continue until null byte found
    sub x0, x0, x2              // Calculate length
    sub x0, x0, #1              // Adjust for null terminator
    ret

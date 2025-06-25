.section .data
input_file:     .asciz "datos.txt"   // Input file name
mean_file:      .asciz "mean.txt"    // Mean file name
output_file:    .asciz "varianza.txt"     // Output file name
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

    // Convert mean from string to number (multiply by 100 for fixed point)
    ldr x0, =buffer
    bl atoi_decimal_input       // Convert decimal string to number*100
    mov x20, x0                 // Save mean value * 100 in x20

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
    mov x19, x0                 // Save file descriptor in x19

    // Read from datos.txt
    mov x0, x19                 // File descriptor in x0
    ldr x1, =buffer             // Buffer address in x1
    mov x2, #256                // Buffer size in x2
    mov x8, #63                 // syscall: read
    svc #0                      // System call
    cmp x0, #0
    b.le error                  // If x0 is zero or negative, jump to error

    // Calculate variance: Σ(xi - μ)² / n
    mov x21, #0                 // Initialize count to zero
    mov x22, #0                 // Initialize sum of squares to zero
    ldr x1, =buffer             // Buffer address in x1

parse_loop:
    mov x0, x1                  // Pass buffer address to x0
    bl atoi_nl_dollar           // Convert string to number
    cmp x0, #-1                 // Check if end of data ($)
    beq parse_end               // If end marker found, finish

    mov x2, #100                // Multiply by 100 for fixed point
    mul x0, x0, x2              // Convert to fixed point (x100)
    sub x0, x0, x20             // (xi * 100) - (mean * 100)
    mul x0, x0, x0              // (xi - mean)^2 * 10000
    add x22, x22, x0            // Add to sum of squares
    add x21, x21, #1            // Increment count

    // Advance to next line
advance_nl:
    ldrb w2, [x1], #1           // Read a byte from buffer and advance
    cmp w2, #10                 // Compare with '\n'
    b.ne advance_nl             // Continue until newline found
    b parse_loop                // Process next number

parse_end:
    cmp x21, #0
    b.eq error                  // Avoid division by zero
    sdiv x23, x22, x21          // variance = sum_of_squares / count

    // Open varianza.txt for writing
    mov x0, #-100               // AT_FDCWD (current directory)
    ldr x1, =output_file        // File name address
    mov x2, #577                // O_WRONLY | O_CREAT | O_TRUNC
    mov x3, #0644               // File permissions
    mov x8, #56                 // syscall: openat
    svc #0                      // System call
    cmp x0, #0
    b.lt error                  // If x0 is negative, jump to error
    mov x24, x0                 // Save file descriptor in x24

    // Convert result to string and write to file
    mov x0, x23                 // Pass result to x0
    ldr x1, =buffer             // Use buffer for output
    bl itoa                     // Convert integer to string
    mov x0, x24                 // File descriptor in x0
    ldr x1, =buffer             // String to write
    bl write_string             // Call write_string function

    // Mostrar resultado en consola
    mov x0, #1                  // stdout
    ldr x1, =buffer             // String to print
    bl write_string             // Call write_string function

    // Write newline to file
    mov x0, x24                 // File descriptor in x0
    ldr x1, =newline            // Newline string
    bl write_string             // Call write_string function

    // Close files
    mov x0, x19                 // input file descriptor in x0
    mov x8, #57                 // syscall: close
    svc #0                      // System call

    mov x0, x24                 // output file descriptor in x0
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

// Function atoi_decimal_input (convert decimal string like "11.50" to number*100)
atoi_decimal_input:
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
    cmp w5, #0
    b.eq atoi_decimal_input_end
    cmp w5, #10                 // newline
    b.eq atoi_decimal_input_end
    sub w5, w5, #'0'
    mov x6, #10
    mul x2, x2, x6
    add x2, x2, x5
    b integer_loop
    
decimal_part:
    cmp x4, #2                  // max 2 decimal places
    b.ge atoi_decimal_input_end
    ldrb w5, [x0], #1
    cmp w5, #0
    b.eq atoi_decimal_input_end
    cmp w5, #10                 // newline
    b.eq atoi_decimal_input_end
    sub w5, w5, #'0'
    mov x6, #10
    mul x3, x3, x6
    add x3, x3, x5
    add x4, x4, #1
    b decimal_part
    
atoi_decimal_input_end:
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

// Function atoi (convert string to number)
atoi:
    // Save return registers
    stp x29, x30, [sp, #-16]!   // Save x29 and x30 on stack
    mov x29, sp                 // Update stack frame pointer

    // Initialization
    mov x2, #0                  // result = 0

atoi_loop:
    ldrb w3, [x0], #1           // Read a byte from x0 and post-increment
    cmp w3, #','                // Compare with ','
    b.eq atoi_end               // If ',', end conversion
    cmp w3, #0                  // Compare with '\0'
    b.eq atoi_end               // If '\0', end conversion
    sub w3, w3, #'0'            // Convert character to digit
    cmp w3, #9                  // Check if digit is in range 0-9
    b.hi atoi_end               // If not in range, end conversion
    mov x4, #10
    mul x2, x2, x4              // result *= 10
    add x2, x2, x3              // result += digit
    b atoi_loop                 // Repeat cycle

atoi_end:
    mov x0, x2                  // Put result in x0

    // Restore return registers
    ldp x29, x30, [sp], #16     // Restore x29 and x30 from stack
    ret                         // Return from function

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
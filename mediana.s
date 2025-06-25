.section .data
input_file:     .asciz "datos.txt"    // Input file name
output_file:    .asciz "mediana.txt"   // Output file name
buffer:         .space 256            // Buffer space (256 bytes)
output_buffer:  .space 256            // Output buffer space
newline:        .asciz "\n"           // Newline string
numbers:        .space 1024           // Array para almacenar hasta 256 números (4 bytes cada uno)

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

    // Parse numbers and store in array
    mov x21, #0                 // Initialize count to zero
    ldr x1, =buffer             // Buffer address in x1
    ldr x22, =numbers           // Base address of numbers array

parse_loop:
    mov x0, x1                  // Pass buffer address to x0
    bl atoi_nl_dollar           // Convert string to number using line format
    cmp x0, #-1                 // Check if end of data ($)
    beq parse_end               // If end marker found, finish

    mov x2, #100                // Multiply by 100 for 2 decimal places
    mul x0, x0, x2              // Convert to fixed point (x100)
    str w0, [x22, x21, lsl #2]  // Store number * 100 in array
    add x21, x21, #1            // Increment count
    
    // Advance to next line
advance_nl:
    ldrb w2, [x1], #1           // Read a byte from buffer and advance
    cmp w2, #10                 // Compare with '\n'
    b.ne advance_nl             // Continue until newline found
    b parse_loop                // Process next number
parse_end:
    // Sort numbers
    bl bubble_sort

    // Calculate median
    bl calculate_median
    mov x23, x0                 // Save median in x23

    // Convert median to string with decimals
    mov x0, x23                 // Pass median to x0
    ldr x1, =output_buffer      // Output buffer address in x1
    bl itoa_decimal             // Call itoa_decimal function

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

    // Write median to file
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

// Function itoa_decimal (convert number*100 to string with 2 decimals)
itoa_decimal:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    mov x4, x0                  // x4 = number * 100
    mov x3, x1                  // x3 = buffer pointer
    
    // Get integer part (divide by 100)
    mov x5, #100
    udiv x6, x4, x5             // x6 = integer part
    msub x7, x6, x5, x4         // x7 = decimal part (remainder)
    
    // Convert integer part to string
    mov x0, x6
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
    mov x5, #10
    udiv x8, x7, x5             // First decimal digit
    add w8, w8, #'0'
    strb w8, [x3, x2]
    add x2, x2, #1
    
    msub x7, x8, x5, x7         // Second decimal digit
    add w7, w7, #'0'
    strb w7, [x3, x2]
    add x2, x2, #1
    
    // Null terminate
    strb wzr, [x3, x2]
    
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

// Function to sort numbers (bubble sort)
bubble_sort:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    // Check if we have at least 2 numbers to sort
    cmp x21, #2
    b.lt bubble_sort_end
    
    sub x1, x21, #1             // n-1 (x21 is count)
    
outer_loop:
    mov x6, #0                  // swapped flag
    mov x2, #0                  // i = 0
    
inner_loop:
    ldr w3, [x22, x2, lsl #2]   // numbers[i]
    add x4, x2, #1
    cmp x4, x21                 // Check bounds
    b.ge inner_loop_end
    ldr w4, [x22, x4, lsl #2]   // numbers[i+1]
    cmp w3, w4
    b.le no_swap
    
    // Swap numbers[i] and numbers[i+1]
    str w4, [x22, x2, lsl #2]   
    str w3, [x22, x4, lsl #2]
    mov x6, #1                  // Set swapped flag
    
no_swap:
    add x2, x2, #1              // i++
    cmp x2, x1                  // i < n-1
    b.lt inner_loop
    
inner_loop_end:
    sub x1, x1, #1              // Reduce range for next pass
    cmp x6, #0                  // Check if any swaps occurred
    b.ne outer_loop             // Continue if swaps occurred
    cmp x1, #0                  // Also check if range > 0
    b.gt outer_loop

bubble_sort_end:
    ldp x29, x30, [sp], #16
    ret

// Function to calculate median
calculate_median:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    // Check for edge cases
    cmp x21, #0
    b.eq median_error
    cmp x21, #1
    b.eq single_element

    lsr x0, x21, #1             // x0 = count / 2
    tst x21, #1                 // Check if count is odd
    b.ne odd_count

    // Even count: median = (numbers[count/2 - 1] + numbers[count/2]) / 2
    sub x1, x0, #1              // x1 = count/2 - 1
    ldr w2, [x22, x1, lsl #2]   // Load numbers[count/2 - 1]
    ldr w3, [x22, x0, lsl #2]   // Load numbers[count/2]
    add w0, w2, w3              // Sum both middle elements
    lsr w0, w0, #1              // Divide by 2
    b median_end

odd_count:
    // Odd count: median = numbers[count/2]
    ldr w0, [x22, x0, lsl #2]   // Load numbers[count/2]
    b median_end

single_element:
    // Only one element
    ldr w0, [x22]               // Load first (and only) element
    b median_end

median_error:
    // No elements - should not happen, but handle gracefully
    mov w0, #0

median_end:
    ldp x29, x30, [sp], #16
    ret
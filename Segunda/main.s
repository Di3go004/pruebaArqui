/*

    This file is the main entry point for the TUI application.
    It initializes the application and starts the main event loop.
    Contains:
        - Welcome message
        - Menu options
        - User input handling
        - Print and read functions
        - Exit function

*/

/*

    Register usage:
    xzr - zero register (always 0)
    x0  - syscall return value or first argument
    x1  - first argument for syscall (file descriptor, address of string, etc.)
    x2  - second argument for syscall (length of string, size of buffer, etc.)
    x3  - third argument for syscall (optional, depends on syscall)
    x4  - fourth argument for syscall (optional, depends on syscall)
    x5  - fifth argument for syscall (optional, depends on syscall)
    x6  - sixth argument for syscall (optional, depends on syscall)
    x7  - seventh argument for syscall (optional, depends on syscall)
    x8  - syscall number
    x9  - temporary register
    x10 - temporary register
    x11 - temporary register
    x12 - temporary register
    x13 - temporary register
    x14 - temporary register
    x15 - temporary register
    x16 - temporary register
    x17 - temporary register
    x18 - temporary register
    x19 - temporary register
    x20 - temporary register
    x21 - Total count of newlines in the data
    x22 - temporary register
    x23 - temporary register
    x24 - temporary register
    x25 - temporary register
    x26 - temporary register
    x27 - temporary register
    x28 - temporary register
    x29 - frame pointer
    x30 - link register (return address)
    x31 - stack pointer
*/

.global _start
.global while
.global data_array
.global data_array_size
.global print

.extern atoi
.extern load_data
.extern calc_mean_real

.section .text

_start:
    adr x1, welcome_message    // Load address of welcome message
    mov x2, #33                // Length of welcome message
    bl print                   // Call print function    

// Main loop of the TUI application
while:
    adr x1, menu_options       // Load address of menu options
    mov x2, #64                // Length of menu options
    bl print                   // Call print function

    adr x1, choose_option      // Load address of choose option message
    mov x2, #26                // Length of choose option message
    bl print                   // Call print function

    bl read                    // Read user input
    adr x0, buffer             // Load address of buffer
    bl atoi                    // Convert input string to integer

    cmp x0, #1                 // Compare input with 1 (statistics option)
    b.eq statistics            // If input is 1, go to statistics

    cmp x0, #2                 // Compare input with 2 (predictions option)
    //b.eq predictions         // If input is 2, go to predictions

    cmp x0, #3                 // Compare input with 3 (set file option)
    b.eq set_file              // If input is 3, go to set file

    //cmp x0, #4               // Compare input with 4 (set limits option)
    //b.eq set_limits          // If input is 4, go to set limits

    cmp x0, #5                 // Compare input with 5 (exit option)
    b.eq end                   // If input is 5, exit the application
    b while                    // Repeat the loop

// Function to handle set file option
// This function prompts the user to set the file name and loads data from that file 
set_file:
    adr x1, set_file_message   // Load address of set file message
    mov x2, #45                // Length of set file message
    bl print                   // Call print function
    bl read                    // Read user input for file name
    adr x0, buffer             // Load address of buffer
    bl load_data               // Load data from the file specified in buffer
    b while                    // Return to main menu

// Function to handle statistics option
statistics:
    // Check if data is loaded
    adr x0, data_array
    ldr x1, [x0]
    cbz x1, no_data_loaded
    
    // Show statistics sub-menu
statistics_menu_loop:
    adr x1, statistics_menu
    mov x2, #200               // Length of statistics menu
    bl print
    
    bl read                    // Read user input
    adr x0, buffer             // Load address of buffer
    bl atoi                    // Convert input string to integer
    
    cmp x0, #1                 // Compare input with 1 (minimum)
    b.eq calc_minimum
    cmp x0, #2                 // Compare input with 2 (maximum)
    b.eq calc_maximum
    cmp x0, #3                 // Compare input with 3 (mean)
    b.eq calc_mean
    cmp x0, #4                 // Compare input with 4 (median)
    b.eq calc_median
    cmp x0, #5                 // Compare input with 5 (variance)
    b.eq calc_variance
    cmp x0, #6                 // Compare input with 6 (mode)
    b.eq calc_mode
    cmp x0, #7                 // Compare input with 7 (standard deviation)
    b.eq calc_std_dev
    cmp x0, #8                 // Compare input with 8 (return to main menu)
    b.eq while
    
    b statistics_menu_loop     // Invalid option, repeat

// Statistical calculation functions (placeholders for now)
calc_minimum:
    adr x1, minimum_result
    mov x2, #30
    bl print
    b statistics_menu_loop

calc_maximum:
    adr x1, maximum_result
    mov x2, #30
    bl print
    b statistics_menu_loop

calc_mean:
    bl calc_mean_real          // Llamar función real de cálculo de media
    b statistics_menu_loop

calc_median:
    adr x1, median_result
    mov x2, #27
    bl print
    b statistics_menu_loop

calc_variance:
    adr x1, variance_result
    mov x2, #28
    bl print
    b statistics_menu_loop

calc_mode:
    adr x1, mode_result
    mov x2, #25
    bl print
    b statistics_menu_loop

calc_std_dev:
    adr x1, std_dev_result
    mov x2, #35
    bl print
    b statistics_menu_loop

no_data_loaded:
    adr x1, no_data_message
    mov x2, #40                // Length of no data message  
    bl print
    b while                    // Return to main menu

// Function to print a string
print:
    mov x0, #1                 // File descriptor for stdout
    mov x8, #64                // syscall number for write
    svc #0                     // Make the syscall
    ret                        // Return from print function

// Function to read user input
read:
    mov x0, #0                 // File descriptor for stdin
    adr x1, buffer             // Address of the buffer to read into
    mov x2, #256               // Size of the buffer
    mov x8, #63                // syscall number for read
    svc #0                     // Make the syscall
    ret                        // Return from read function

// Function to exit the application
end:
    mov x0, #0                 // Exit code
    mov x8, #93                // syscall number for exit
    svc #0                     // Make the syscall


// Strings for the TUI application
.section .data
welcome_message:
    .ascii "\nWelcome to the TUI application!\n"
menu_options:
    .ascii "\n1. Statistics\n2. Predictions\n3. Set File\n4. Set Limits\n5. Exit\n"
choose_option:
    .ascii "\nPlease choose an option: "
set_file_message:
    .ascii "\nSet the name of the file to load data from: "
statistics_message:
    .ascii "\nStatistics feature is now available! Data loaded.\n"
no_data_message:
    .ascii "\nNo data loaded. Please set a file first.\n"
statistics_menu:
    .ascii "\n=== STATISTICS MENU ===\n1. Calculate Minimum\n2. Calculate Maximum\n3. Calculate Mean\n4. Calculate Median\n5. Calculate Variance\n6. Calculate Mode\n7. Calculate Standard Deviation\n8. Return to Main Menu\nSelect option: "
minimum_result:
    .ascii "\nMinimum calculated successfully!\n"
maximum_result:
    .ascii "\nMaximum calculated successfully!\n"
mean_result:
    .ascii "\nMean calculated successfully!\n"
median_result:
    .ascii "\nMedian calculated successfully!\n"
variance_result:
    .ascii "\nVariance calculated successfully!\n"
mode_result:
    .ascii "\nMode calculated successfully!\n"
std_dev_result:
    .ascii "\nStandard deviation calculated successfully!\n"
newline:
    .ascii "aaaaaaaaaaaaaaaaaaaaaaaa\n"

// Buffer for user input
.section .bss
buffer:
    .space 256                  // Buffer for user input
file_name:
    .space 32                   // Buffer for file name input
    .align 3                    // Align to 8-byte boundary
data_array:                     
    .quad  0                    // Reserve space for data array (8 bytes for a pointer)
data_array_size:
    .quad  0                    // Reserve space for data array size (8 bytes for a size_t)
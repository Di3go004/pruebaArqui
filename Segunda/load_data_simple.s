.global load_data

.section .text

load_data:
    // Simple data loader - cargar datos de ejemplo
    // En lugar de leer archivo, cargar datos hardcodeados para prueba
    
    // Set data_array to point to sample data
    adr x0, data_array
    adr x1, sample_data
    str x1, [x0]
    
    // Set data_array_size to 6 (número de elementos de ejemplo)
    adr x0, data_array_size  
    mov x1, #6
    str x1, [x0]
    
    // Print success message
    adr x1, load_success_message
    mov x2, #25
    bl print
    
    b while

// Function to print a string (local copy since it's external)
print:
    mov x0, #1                 // File descriptor for stdout
    mov x8, #64                // syscall number for write
    svc #0                     // Make the syscall
    ret

.section .data
load_success_message:
    .ascii "Data loaded successfully!\n"
sample_data:
    // Datos de ejemplo multiplicados por 100 (formato correcto)
    // Si tus datos reales son: 8.50, 15.25, 12.75, 9.80, 11.40, 13.30
    // Media correcta: (8.50+15.25+12.75+9.80+11.40+13.30)/6 = 71.00/6 = 11.83
    .quad 850, 1525, 1275, 980, 1140, 1330
    
.extern while
.extern data_array
.extern data_array_size
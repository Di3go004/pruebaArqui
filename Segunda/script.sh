as -g -o main.o main.s
as -g -o atoi.o atoi.s
as -g -o atoi_partial.o atoi_partial.s
as -g -o load_data.o load_data.s
as -g -o count_partial.o count_partial.s
ld -o tui main.o atoi.o atoi_partial.o load_data.o count_partial.o
gdb ./tui
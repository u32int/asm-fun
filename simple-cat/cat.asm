%define STDIN 0
%define STDOUT 1
%define STDERR 2

%define BUFFERSIZE 64

section .data
    info_usage db "usage: cat [files]",10,0
    info_usage_len equ $-info_usage
    error_open db ": no such file or directory.",10,0
    error_open_len equ $-error_open
    newline db 10

section .bss
    buffer resb BUFFERSIZE 

section .text
global _start

strlen:
    mov rax, 0
strlenLoop:
    mov bl, [rdi]
    cmp bl, 0
    je strlenExit
    inc rdi
    inc rax
    jmp strlenLoop
strlenExit:
    ret

exitUsage:
    mov rax, 1
    mov rdi, STDERR
    mov rsi, info_usage 
    mov rdx, info_usage_len
    syscall

    mov rax, 60
    mov rdi, 1
    syscall

stdinLoop:
    mov rax, 0                  ; read stdin
    mov rdi, STDIN
    mov rsi, buffer
    mov rdx, BUFFERSIZE
    syscall

    mov r9, rax                 ; store read size

    mov rax, 1                  ; print buffer
    mov rdi, STDOUT
    mov rsi, buffer

    mov rdx, r9
    cmp r9, BUFFERSIZE
    jle stdinNoOverflow
    mov rdx, BUFFERSIZE
stdinNoOverflow:
    syscall

    jmp stdinLoop


_start:
    pop r8                      ; store argc into r8
    pop rbx                     ; store argv[0] (program name) into rbx

    cmp r8, 1
    je stdinLoop                ; if no arguments are supplied, read stdin

catLoop:
    dec r8 
    
    mov rax, 2                  ; sys_open
    pop rdi                     ; get file name from stack (argv)
    mov rsi, 0                  ; readonly
    mov rdx, 0644o              ; file permissions
    syscall

    mov r10, rax                ; store fd in r10
    cmp r10, 0
    jg printFile                ; file exists, print it

                                ; file doesn't exist, print an error and exit
    mov rsi, rdi                ; 1. file name
    call strlen
    mov rdx, rax
    mov rax, 1
    mov rdi, STDERR
    syscall

    mov rax, 1                  ; 2. rest of error
    mov rdi, STDERR
    mov rsi, error_open   
    mov rdx, error_open_len
    syscall

    mov rax, 60
    mov rdi, 1
    syscall

printFile:
    mov rax, 0                  ; read file
    mov rdi, r10
    mov rsi, buffer
    mov rdx, BUFFERSIZE
    syscall

    mov r9, rax                 ; store the number of bytes read in r9
    cmp r9, 0                   ; if it is 0, it means EOF. exit.
    je printExit

    mov rax, 1                  ; print buffer contents
    mov rdi, STDOUT
    mov rsi, buffer
    mov rdx, r9
    syscall

    jmp printFile

printExit:   
    cmp r8, 1
    jg catLoop                  ; still more files left, jump back

    mov rax, 60                 ; done, exit with 0
    mov rdi, 0
    syscall

%define MENU_SIGNATURE 0x10AD1700

org 0x7c00
bits 16
boot:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00

    cld

    ; detect if extended reads are possible
    mov ah, 0x41
    mov bx, 0x55aa
    int 0x13
    jc extended_reads_fail ; error if carry is set

    xor cx, cx
.load_loop:
    mov ah, 0x42
    lea si, [dap]
    int 0x13
    jc disk_read_error
    inc cx
    cmp cx, 3
    jne .load_loop

    ; 0x700 because we load to 0x500 BUT we load from the very first sector including the boot sector
    cmp dword [0x700], MENU_SIGNATURE
    jne signature_fail

    jmp 0x0:0x710

    jmp hang

print:
    push eax
    mov ah, 0x0e
.loop:
    lodsb ; load byte from si into al and increment si
    test al, al ; check if al is a null byte
    jz .return ; if it is return
    int 0x10 ; if not print
    jmp .loop ; then go back to loading another byte
.return:
    mov al, 0xa ; newline
    int 0x10
    mov al, 0xd ; carriage return
    int 0x10
    pop eax
    ret

hang:
    cli
    hlt
    jmp hang

extended_reads_fail:
    lea si, [msg.extended_reads_fail]
    call print
    jmp hang

disk_read_error:
    lea si, [msg.disk_read_error]
    call print
    jmp hang

signature_fail:
    lea si, [msg.signature_fail]
    call print
    jmp hang

msg:
.extended_reads_fail: db "Your PC does not support extended reads", 0
.disk_read_error: db "Disk read error", 0
.signature_fail: db "Stage two signature invalid", 0

dap:
    db 0x10 ; size of packet
    db 0
.sectors: dw 32
.buffer_address: dd 0x500
.start_sector: dq 0

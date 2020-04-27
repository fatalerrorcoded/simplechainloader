%define MENU_SIGNATURE 0x10AD1700

org 0x700
bits 16

dd MENU_SIGNATURE
align 16

stage_two_start:
    lea si, [msg.it_works]
    call print
    jmp $

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

msg:
.it_works: db "It works!", 0

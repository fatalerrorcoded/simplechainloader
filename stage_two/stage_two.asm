%define MENU_SIGNATURE 0x10AD1700

org 0x700
bits 16

dd MENU_SIGNATURE
align 16

stage_two_start:
    xor ax, ax
    mov si, 0x6BE ; first partition entry
    xor di, di
    mov cx, 4
get_next_partition_entry:
    ; check if partition type is 0x0 (unused)
    mov bl, byte [si + 0x4]
    test bl, bl
    jz .continue

    ; partition number
    mov byte [partitions + di], al
    ; partition type
    mov byte [partitions + 0x1 + di], bl
    ; partition lba
    mov ebx, dword [si + 0x8]
    mov dword [partitions + 0x2 + di], ebx
    ; partition status
    mov bl, byte [si]
    mov byte [partitions + 0x6 + di], bl
    add di, 8

.continue:
    inc ax
    dec cx
    jz .end
    add si, 0x10 ; next partition entry
    jmp get_next_partition_entry

.end:

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

; Layout:
; 0x0 - Partition Number (used for writing the active bit to the right place on disk)
; 0x1 - Partition Type
; 0x2 - Partition LBA
; 0x6 - Partition status
; 0x7 - Unused
partitions:
    times (8 * 4) db 0

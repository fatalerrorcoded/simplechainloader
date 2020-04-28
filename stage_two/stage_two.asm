%define MENU_SIGNATURE 0x10AD1700

section .text
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
    ; check if we found any partitions
    cmp di, 0
    je no_partition_found

    cmp di, 8
    je single_partition

    jmp hang

single_partition:
    lea si, [partitions]
    jmp jump_to_partition_bootsector

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

; SI - Partition to boot (from partitions table below)
jump_to_partition_bootsector:
    ; first, clear the screen
    ;push dx
    ;mov ax, 0x0700 ; clear entire window (by scrolling down)
    ;mov bh, 0x07 ; color used to write blank lines
    ;xor cx, cx ; row, column of window upper left corner
    ;mov dx, 0x184f ; row, column of window lower right corner
    ;int 0x10
    ;pop dx
    ; then, disable the active bit in all the partition entries
    push si
    mov si, 0x6BE ; first partition entry
    mov cx, 4
.disable_active_bit_loop:
    mov al, byte [si]
    and si, 0x7F ; disable active bit
    mov byte [si], al

._continue:
    dec cx
    jz ._end
    add si, 0x10 ; next partition entry
    jmp .disable_active_bit_loop

._end:
    pop si
    push si

    xor ax, ax
    mov al, byte [si]
    shl ax, 4 ; multiply by 16
    add ax, 0x6BE ; add entry offset
    mov si, ax
    ; get status and set active bit
    mov al, byte [si]
    or al, 0x80
    mov byte [si], al

; WRITE MBR TO DISK
    mov word [dap.sectors], 1
    mov dword [dap.buffer_address], 0x500
    mov dword [dap.start_sector], 0x0

    xor cx, cx
.write_loop:
    mov ah, 0x43
    lea si, [dap]
    int 0x13
    jc disk_write_error
    inc cx
    cmp cx, 3
    jne .write_loop

; READ VBR FROM DISK
    pop si
    mov eax, [si + 0x2] ; get lba
    mov word [dap.sectors], 1
    mov dword [dap.buffer_address], 0x7c00
    mov dword [dap.start_sector], eax

    xor cx, cx
.load_loop:
    mov ah, 0x42
    lea si, [dap]
    int 0x13
    jc disk_read_error
    inc cx
    cmp cx, 3
    jne .load_loop

    xor ax, ax
    mov ss, ax
    mov sp, 0x7c00

    jmp 0x0:0x7c00 ; jump to newly loaded bootloader

hang:
    cli
    hlt
    jmp hang

no_partition_found:
    lea si, [msg.no_partition_found]
    call print
    jmp hang

disk_read_error:
    lea si, [msg.disk_read_error]
    call print
    jmp hang

disk_write_error:
    lea si, [msg.disk_write_error]
    call print
    jmp hang

msg:
.no_partition_found: db "No bootable partitions found!", 0
.disk_read_error: db "Unable to read partition VBR", 0
.disk_write_error: db "Unable to update MBR on disk", 0

dap:
    db 0x10 ; size of packet
    db 0
.sectors: dw 1
.buffer_address: dd 0x500
.start_sector: dq 0

; Layout:
; 0x0 - Partition Number (used for writing the active bit to the right place on disk)
; 0x1 - Partition Type
; 0x2 - Partition LBA
; 0x6 - Partition status
; 0x7 - Unused
partitions:
    times (8 * 4) db 0

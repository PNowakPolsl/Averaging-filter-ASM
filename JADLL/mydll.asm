.DATA
    align 16

.CODE
PUBLIC ASM_AVGFILTER
ASM_AVGFILTER PROC
    ; Zachowanie rejestrów nieulotnych
    push    rbp
    mov     rbp, rsp

    push    rbx
    push    rsi
    push    rdi
    push    r12
    push    r13
    push    r14
    push    r15

    ; Przypisanie argumentów do rejestrów lokalnych
    mov     rbx, rdx           ; rbx = outputData
    mov     r12d, r8d          ; r12d = width
    mov     r13d, r9d          ; r13d = startY

    ; Pobierz endY i imageHeight z odpowiednich offsetów
    ; W x64 Windows, po pushe rejestrów, offsety argumentów na stosie to [rbp + 40] i [rbp + 48]
    mov     eax, dword ptr [rbp + 40]    ; Pobierz endY
    mov     r14d, eax

    mov     eax, dword ptr [rbp + 48]    ; Pobierz imageHeight
    mov     r15d, eax

    ; Oblicz stride (szerokoœæ w bajtach)
    mov     ecx, r12d
    imul    ecx, 3              ; 3 bajty na piksel (RGB)
    mov     rsi, rcx            ; rsi = stride

    ; Iteracja przez wiersze obrazu
row_loop:
    cmp     r13d, r14d
    jge     end_function        ; Przerwij, jeœli osi¹gniêto koniec zakresu wierszy

    ; SprawdŸ, czy y jest w granicach obrazu
    cmp     r13d, r15d
    jge     skip_row
    cmp     r13d, 0
    jl      skip_row

    ; Oblicz wskaŸnik do pocz¹tku aktualnego wiersza w outputData
    mov     eax, r13d
    imul    eax, esi            ; eax = y * stride
    lea     rdi, [rbx + rax]    ; rdi = outputData + y * stride

    ; Iteracja przez kolumny obrazu
    xor     r10d, r10d          ; r10d = x (0)
col_loop:
    cmp     r10d, r12d
    jge     next_row            ; PrzejdŸ do nastêpnego wiersza, jeœli wszystkie kolumny zosta³y przetworzone

    ; Oblicz wskaŸnik do aktualnego piksela
    ; Oblicz x * 3 jako x * 2 + x
    mov     eax, r10d
    shl     eax, 1              ; eax = x * 2
    add     eax, r10d           ; eax = x * 3
    lea     rcx, [rdi + rax]    ; rcx = outputData + y * stride + x * 3

    ; Ustaw piksel na bia³y
    mov     byte ptr [rcx], 255     ; R
    mov     byte ptr [rcx + 1], 255 ; G
    mov     byte ptr [rcx + 2], 255 ; B

    ; PrzejdŸ do nastêpnej kolumny
    inc     r10d
    jmp     col_loop

skip_row:
    ; Pomijanie wiersza, który jest poza granicami obrazu
    nop

next_row:
    inc     r13d
    jmp     row_loop

end_function:
    ; Przywrócenie rejestrów nieulotnych
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rdi
    pop     rsi
    pop     rbx
    pop     rbp
    ret
ASM_AVGFILTER ENDP
END

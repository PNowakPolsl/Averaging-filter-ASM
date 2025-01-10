.DATA
    align 16
const_0_111  dd 0.11111111, 0.11111111, 0.11111111, 0.11111111  ; Wektor zawieraj�cy [1/9, 1/9, 1/9, 1/9]

.CODE
PUBLIC ASM_AVGFILTER
ASM_AVGFILTER PROC
    ;-----------------------------------
    ; Zapisanie rejestr�w nieulotnych
    ;-----------------------------------
    push    rbp
    push    rbx
    push    rsi
    push    rdi
    push    r12
    push    r13
    push    r14
    push    r15

    ;-----------------------------------
    ; Pobranie parametr�w funkcji
    ;-----------------------------------
    mov     r10d, [rsp + 104]   ; r10d = wysoko�� obrazu (imageHeight)
    mov     r12d, r8d           ; r12d = startowy wiersz (startY)
    mov     r13d, edx           ; r13d = szeroko�� obrazu (width)
    mov     rbp, rcx            ; rbp = wska�nik na dane pikseli (pixelData)
    mov     r9d, r9d            ; r9d = ko�cowy wiersz (endY)

    ;-----------------------------------
    ; Iteracja po wierszach obrazu
    ;-----------------------------------
row_loop:
    cmp     r12d, r9d
    jge     end_function        ; Je�li y >= endY, zako�cz

    xor     r14d, r14d         ; Ustaw x na 0

col_loop:
    cmp     r14d, r13d
    jge     next_row           ; Je�li x >= width, przejd� do nast�pnego wiersza

    ; Wyzerowanie akumulatora w xmm0
    pxor    xmm0, xmm0         ; Reset akumulatora sumy pikseli

    ;---------------------------------------
    ; P�tla 3x3: sumowanie pikseli s�siednich
    ;---------------------------------------
    mov     r15d, -1           ; r15d = przesuni�cie w pionie (od aktualnego wiersza)

outer_3x3_loop:
    ; Sprawdzenie, czy wiersz mie�ci si� w granicach obrazu
    mov     edx, r12d
    add     edx, r15d
    cmp     edx, 0
    jl      skip_row
    cmp     edx, r10d
    jge     skip_row

    ; Inicjalizacja przesuni�cia w poziomie
    mov     r8d, -1

inner_3x3_loop:
    ; Sprawdzenie, czy kolumna mie�ci si� w granicach obrazu
    mov     eax, r14d
    add     eax, r8d
    cmp     eax, 0
    jl      skip_col
    cmp     eax, r13d
    jge     skip_col

    ; Obliczenie adresu danego piksela
    ; rowIndex = (y + r15d) * szeroko��
    ; colIndex = (x + r8d)
    ; offset   = (rowIndex + colIndex)*3
    mov     ecx, edx           ; ecx = (y + offsetY)
    imul    ecx, r13d
    add     ecx, eax           ; ecx = (y + offsetY)*width + (x + offsetX)
    imul    ecx, 3             ; Przelicz na offset w bajtach (B,G,R)

    ; Wczytanie danych piksela (32 bity) do xmm4
    movd    xmm4, dword ptr [rbp + rcx]

    ; Rozszerzenie warto�ci 8-bit -> 16-bit -> 32-bit
    pxor    xmm5, xmm5
    punpcklbw xmm4, xmm5       ; 8-bit -> 16-bit
    punpcklwd xmm4, xmm5       ; 16-bit -> 32-bit

    ; Konwersja na float i dodanie do akumulatora
    cvtdq2ps xmm4, xmm4
    addps   xmm0, xmm4

skip_col:
    add     r8d, 1
    cmp     r8d, 1
    jle     inner_3x3_loop

skip_row:
    add     r15d, 1
    cmp     r15d, 1
    jle     outer_3x3_loop

    ;---------------------------------------
    ; Obliczenie �redniej przez pomno�enie przez 0.11111111 (1/9)
    ;---------------------------------------
    mulps   xmm0, xmmword ptr [const_0_111]

    ;---------------------------------------
    ; Konwersja float -> int oraz saturacja warto�ci
    ;---------------------------------------
    cvttps2dq xmm1, xmm0       ; Konwersja na liczby ca�kowite
    packusdw  xmm1, xmm1       ; Zmniejszenie do 16 bit�w
    packuswb  xmm1, xmm1       ; Zmniejszenie do 8 bit�w

    ; xmm1 zawiera teraz dwa piksele w dolnych 32 bitach (00RRGGBB)
    movd    ebx, xmm1

    ;---------------------------------------
    ; Wyliczenie docelowego offsetu piksela (y*width + x)*3
    ;---------------------------------------
    mov     eax, r12d
    imul    eax, r13d
    add     eax, r14d
    imul    eax, 3

    ; Zapisanie przetworzonego piksela (4 bajty: B, G, R, X)
    mov     dword ptr [rbp + rax], ebx

    ; Przejd� do kolejnej kolumny
    inc     r14d
    jmp     col_loop

next_row:
    inc     r12d
    jmp     row_loop

end_function:
    ;-----------------------------------
    ; Przywr�cenie rejestr�w nieulotnych
    ;-----------------------------------
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
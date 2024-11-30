.586
;INCLUDE C:\masm32\include\windows.inc

.DATA
    mask_value dq 0.11111111, 0.11111111, 0.11111111, 0.11111111 ; Wartoœæ maski (1/9 w precyzji zmiennoprzecinkowej)
    max_value  db 255           ; Maksymalna wartoœæ dla kolorów (RGB 8-bit)
    zero_value dq 0.0, 0.0, 0.0, 0.0 ; Zero dla przycinania wyników

    offsets dq -1, 0, 1, -1, 0, 1, -1, 0, 1 ; Przesuniêcia dla maski 3x3 (w trakcie implementacji)

.CODE

AVARAGE PROC
    ; Argumenty:
    ; rcx - wskaŸnik do danych pikseli
    ; rdx - szerokoœæ obrazu (w pikselach)
    ; r8  - startY (pocz¹tek segmentu)
    ; r9  - segmentHeight (wysokoœæ segmentu)

    push rsi
    push rdi

    ; Inicjalizacja wskaŸników 
    mov rsi, rcx                  ; WskaŸnik do pikseli wejœciowych 
    mov rdi, rcx                  ; WskaŸnik do pikseli wyjœciowych 

    ; Iteracja po wierszach (niedokoñczona logika)
    mov r10, r8                   ; startY -> r10 (szkic)
    add r9, r8                    ; Oblicz koniec segmentu

IteracjaWierszy:
    cmp r10, r9                   ; Czy osi¹gniêto koniec segmentu?
    jge Koniec                    ; Na razie koñczy pêtlê bez obliczeñ

    ; Iteracja po kolumnach (niedopracowane)
    xor r11, r11                  ; r11 = kolumna (przyk³ad iteracji)
IteracjaKolumn:
    cmp r11, rdx                  ; Czy osi¹gniêto szerokoœæ wiersza?
    jge NastepnyWiersz

    ; Próba sumowania dla maski (szkic)
    pxor xmm0, xmm0               ; Wyzerowanie sumy
    lea rbx, offsets              ; Za³aduj przesuniêcia maski
    mov r12, 0                    ; Licznik maski

PetlaMaski:
    mov rax, QWORD PTR [rbx + r12 * 8] ; Za³aduj przesuniêcie (offset)
    add rax, r11                 ; Dodaj przesuniêcie kolumny
    imul rax, rdx                ; Przesuñ wiersz o szerokoœæ
    add rax, r10                 ; Dodaj aktualny wiersz
    add rax, rsi                 ; Oblicz wskaŸnik do piksela w masce
    movsd xmm1, QWORD PTR [rax]  ; Za³aduj piksel
    addsd xmm0, xmm1             ; Dodaj piksel do sumy

    add r12, 1                   ; Nastêpne przesuniêcie
    cmp r12, 9                   ; Czy przetworzono wszystkie piksele maski?
    jl PetlaMaski


    movsd QWORD PTR [rdi + r11], xmm0 ; Zapisz wynik do bufora wyjœciowego

    ; PrzejdŸ do nastêpnego piksela
    add r11, 1
    jmp IteracjaKolumn

NastepnyWiersz:
    add r10, 1                  ; PrzejdŸ do nastêpnego wiersza
    add rsi, rdx                ; Przesuñ wskaŸnik wejœciowy o szerokoœæ
    add rdi, rdx                ; Przesuñ wskaŸnik wyjœciowy o szerokoœæ
    jmp IteracjaWierszy

Koniec:
    ; Zakoñczenie 
    pop rdi
    pop rsi
    ret
AVARAGE ENDP

END

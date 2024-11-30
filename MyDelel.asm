.586
;INCLUDE C:\masm32\include\windows.inc

.DATA
    mask_value dq 0.11111111, 0.11111111, 0.11111111, 0.11111111 ; Warto�� maski (1/9 w precyzji zmiennoprzecinkowej)
    max_value  db 255           ; Maksymalna warto�� dla kolor�w (RGB 8-bit)
    zero_value dq 0.0, 0.0, 0.0, 0.0 ; Zero dla przycinania wynik�w

    offsets dq -1, 0, 1, -1, 0, 1, -1, 0, 1 ; Przesuni�cia dla maski 3x3 (w trakcie implementacji)

.CODE

AVARAGE PROC
    ; Argumenty:
    ; rcx - wska�nik do danych pikseli
    ; rdx - szeroko�� obrazu (w pikselach)
    ; r8  - startY (pocz�tek segmentu)
    ; r9  - segmentHeight (wysoko�� segmentu)

    push rsi
    push rdi

    ; Inicjalizacja wska�nik�w 
    mov rsi, rcx                  ; Wska�nik do pikseli wej�ciowych 
    mov rdi, rcx                  ; Wska�nik do pikseli wyj�ciowych 

    ; Iteracja po wierszach (niedoko�czona logika)
    mov r10, r8                   ; startY -> r10 (szkic)
    add r9, r8                    ; Oblicz koniec segmentu

IteracjaWierszy:
    cmp r10, r9                   ; Czy osi�gni�to koniec segmentu?
    jge Koniec                    ; Na razie ko�czy p�tl� bez oblicze�

    ; Iteracja po kolumnach (niedopracowane)
    xor r11, r11                  ; r11 = kolumna (przyk�ad iteracji)
IteracjaKolumn:
    cmp r11, rdx                  ; Czy osi�gni�to szeroko�� wiersza?
    jge NastepnyWiersz

    ; Pr�ba sumowania dla maski (szkic)
    pxor xmm0, xmm0               ; Wyzerowanie sumy
    lea rbx, offsets              ; Za�aduj przesuni�cia maski
    mov r12, 0                    ; Licznik maski

PetlaMaski:
    mov rax, QWORD PTR [rbx + r12 * 8] ; Za�aduj przesuni�cie (offset)
    add rax, r11                 ; Dodaj przesuni�cie kolumny
    imul rax, rdx                ; Przesu� wiersz o szeroko��
    add rax, r10                 ; Dodaj aktualny wiersz
    add rax, rsi                 ; Oblicz wska�nik do piksela w masce
    movsd xmm1, QWORD PTR [rax]  ; Za�aduj piksel
    addsd xmm0, xmm1             ; Dodaj piksel do sumy

    add r12, 1                   ; Nast�pne przesuni�cie
    cmp r12, 9                   ; Czy przetworzono wszystkie piksele maski?
    jl PetlaMaski


    movsd QWORD PTR [rdi + r11], xmm0 ; Zapisz wynik do bufora wyj�ciowego

    ; Przejd� do nast�pnego piksela
    add r11, 1
    jmp IteracjaKolumn

NastepnyWiersz:
    add r10, 1                  ; Przejd� do nast�pnego wiersza
    add rsi, rdx                ; Przesu� wska�nik wej�ciowy o szeroko��
    add rdi, rdx                ; Przesu� wska�nik wyj�ciowy o szeroko��
    jmp IteracjaWierszy

Koniec:
    ; Zako�czenie 
    pop rdi
    pop rsi
    ret
AVARAGE ENDP

END

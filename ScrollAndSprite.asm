ORG #8000

.START_SCREEN_ADDRESS equ #C000
.SCREEN_HEIGHT        equ   200
.SCREEN_WIDTH         equ    80
.PPI_PORT_B           equ   #F5



ORG #8000
  CALL SAVE_IMAGE
RET

ORG #8200
  CALL RESTORE_IMAGE
RET


ORG #8400
  CALL SET_BANK1_PAGE0
RET

ORG #8600
  CALL SET_BANK1_PAGE1
RET

SAVE_IMAGE

  LD DE, #4000
  LD HL, #C000
  LD BC, #3FFF
  LDIR

RET

RESTORE_IMAGE

  LD DE, #C000
  LD HL, #4000
  LD BC, #3FFF
  LDIR

RET

SET_BANK1_PAGE0

  LD  BC,#7F00+%11000101 ; BANK 1 / PAGE 0 -> #4000-#7FFF
  OUT (C),C

RET

SET_BANK1_PAGE1

  LD  BC,#7F00+%11001101 ; BANK 1 / PAGE 1 -> #4000-#7FFF
  OUT (C),C

RET




PUSH AF
CALL WAIT_NOT_VSYNC
CALL WAIT_VSYNC_ON
POP AF

LD BC, #BC0C   ; dans le port BC, on demande d'acceder au registre 13
OUT (C), C

LD  BC,#BD00+%00101100 ; dans le port BD, on ecrit dans le registre 13
OUT (C),C





MAIN_LOOP
JP MAIN_LOOP








RET







RET


CALL WAIT_NOT_VSYNC
CALL WAIT_VSYNC_ON

LD BC, #BC0C
OUT (C), C

LD  BC,#BD00+%00010000
OUT (C),C

CALL WAIT_NOT_VSYNC
CALL WAIT_VSYNC_ON

LD BC, #BC0C
OUT (C), C

LD  BC,#BD00+%00110000
OUT (C),C

JP MAIN_LOOP



call DISABLE_DEFAULT_INTERRUPT








; =================================================
MOVE_SPRITE_WITH_X
; =================================================

LOOP

CALL WAIT_NOT_VSYNC
CALL WAIT_VSYNC_ON

LD D, 7
call CHECK_KEY_PRESSED
AND A, %10000000
CP A, 0
JP NZ, LOOP_2

LD HL, MOVE_SPRITE + 1
INC (HL)


LOOP_2
CALL BLIT_SPRITE
JP LOOP



CALL BLIT_SPRITE
RET


; =================================================
CHECK_KEY_PRESSED
; =================================================
 ; Test clavier de la ligne
; dont le numero est dans D
; D doit contenir une valeur de 0 a 9
  LD          BC,&F40E        ; Valeur 14 sur le port A         
  OUT         (C),C         
  LD          BC,&F6C0        ; C'est un registre         
  OUT         (C),C         
  LD          BC,&F600        ; Validation         
  OUT         (C),C         
  LD          BC,&F792        ; Port A en entree         
  OUT         (C),C         
  LD          A,D             ; A=ligne clavier         
  OR          %01000000        
  LD          B,&F6         
  OUT         (C),A         
  LD          B,&F4           ; Lecture du port A         
  IN          A,(C)           ; A=Reg 14 du PSG         
  LD          BC,&F782        ; Port A en sortie         
  OUT         (C),C         
  LD          BC,&F600        ; Validation         
  OUT         (C),C           ; Et A contient la ligne
  RET

; =================================================
BLIT_SPRITE
; =================================================

  LD DE, START_SCREEN_ADDRESS

MOVE_SPRITE
  LD  HL, 0
  ADD HL, DE
  EX  HL, DE


  LD HL, SPRITE_D

  LD A, (HL)
  LD (BLIT_SPRITE_LOAD_WIDTH + 1), A
  INC HL

  LD B, (HL)
  LD C, 0
  INC HL

BLIT_SPRITE_ONE_LINE

  PUSH BC

BLIT_SPRITE_LOAD_WIDTH
  LD C, #FF
  LD B, 0

  PUSH DE
  LDIR
  POP DE

  CALL NEXT_LINE_DE

  POP BC
  DJNZ BLIT_SPRITE_ONE_LINE

  RET

; =================================================
WAIT_VSYNC_ON
; =================================================

  LD B, PPI_PORT_B
  IN A,(C)
  RRA                               
  JR NC, WAIT_VSYNC_ON
  RET

; =================================================
WAIT_NOT_VSYNC
; =================================================

  LD B, PPI_PORT_B
  IN A,(C)
  RRA                               
  JR C, WAIT_VSYNC_ON
  RET

; =================================================
SCROLL_SCREEN_LEFT
; =================================================

  LD HL, START_SCREEN_ADDRESS
  LD B,  SCREEN_HEIGHT ; number of lines

  JP SCROLL_SCREEN_LEFT_ONE_LINE ; skip following code that is to be executed except for the first iteration

SCROLL_SCREEN_LEFT_NEXT_LINE
  
  POP HL                                       ; get back HL = address of the first pixel of the line to move
  PUSH BC
  CALL NEXT_LINE_HL                            ; HL = next line HL
  POP BC

SCROLL_SCREEN_LEFT_ONE_LINE

  PUSH HL ; keep trace of the beginning of the line
  PUSH BC ; keep trace of remaining line count

  PUSH HL ; deduce DE from HL (HL = DE + 1)
  POP DE
  INC HL

  LD BC, SCREEN_WIDTH - 1 ; copy the line
  LDIR

  POP BC ; get back remaining line count
  DJNZ SCROLL_SCREEN_LEFT_NEXT_LINE ; decrement line count and process next line if necessary

  POP HL ; remove the last element on stack
  RET

; =================================================
NEXT_LINE_DE
; =================================================
  LD A, D
  ADD A, #08
  LD D, A

  RET NC

  EX HL, DE
  LD BC, #C050
  ADD HL, BC
  EX HL, DE

  RET

; =================================================
NEXT_LINE_HL
; =================================================
  
  LD A, H
  ADD A, #08
  LD H, A

  RET NC

  LD BC, #C050
  ADD HL, BC

  RET

; =================================================
DISABLE_DEFAULT_INTERRUPT
; =================================================
  DI
  LD HL, #C9FB ; #C9 -> RET     #FB -> EI
  LD (#38), HL
  EI
  RET

; =================================================
SPRITE_A
; =================================================

db 2, 5 
db #FF, #AA
db #AA, #AA 
db #FF, #AA
db #AA, #AA
db #AA, #AA

; =================================================
SPRITE_B
; =================================================

db 2, 5 
db #FF, #00
db #AA, #AA 
db #FF, #00
db #AA, #AA
db #FF, #00

; =================================================
SPRITE_C
; =================================================

db 2, 5 
db #FF, #AA
db #AA, #00 
db #AA, #00
db #AA, #00
db #FF, #AA

; =================================================
SPRITE_D
; =================================================

db 2, 5
db #FF, #00
db #AA, #AA 
db #AA, #AA
db #AA, #AA
db #FF, #00

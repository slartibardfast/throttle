debugonly equ 1






;constants of stuff that seem hard to remember at times.

TRUE  EQU 1
FALSE EQU 0

ENABLED  EQU 1
DISABLED EQU 0

BIT0  EQU 1
BIT1  EQU 2
BIT2  EQU 4
BIT3  EQU 8
BIT4  EQU 10h
BIT5  EQU 20h
BIT6  EQU 40h
BIT7  EQU 80h
BIT8  EQU 100h
BIT9  EQU 200h
BIT10 EQU 400h
BIT11 EQU 800h
BIT12 EQU 1000h
BIT13 EQU 2000h
BIT14 EQU 4000h
BIT15 EQU 8000h
BIT16 EQU 10000h
BIT17 EQU 20000h
BIT18 EQU 40000h
BIT19 EQU 80000h
BIT20 EQU 100000h
BIT21 EQU 200000h
BIT22 EQU 400000h
BIT23 EQU 800000h
BIT24 EQU 1000000h
BIT25 EQU 2000000h
BIT26 EQU 4000000h
BIT27 EQU 8000000h
BIT28 EQU 10000000h
BIT29 EQU 20000000h
BIT30 EQU 40000000h
BIT31 EQU 80000000h


TERMINATOR	EQU	0CAFEh		

;colors for standard text mode
;
;                Bit# 76543210
;blinking text?ÄÄÄÄÄÄÄÙ///³\\\
;                 backgrnd³ text color
;                  color  Àhigh intensity (bright) color?
BLACK     EQU 0
BLUE      EQU 1
GREEN     EQU 2
CYAN      EQU 3
RED       EQU 4
MAGENTA   EQU 5
BROWN     EQU 6
WHITE     EQU 7

BRIGHT    EQU BIT3           ;Bit 3 set if text is high intensity (bright)
BLINKING  EQU BIT7           ;Bit 7 set if text is blinking
;Note: high intensity black = dark grey
;Note: Blinking text can be disabled by calling INT 10, AX=1003, BL=0
;      This doubles the background color choices to 16 total.



;special characters
NUL     EQU 0
NULL    EQU 0
BELL    EQU 07
BS      EQU 08
TAB     EQU 09
LF      EQU 10
CR      EQU 13
ESCAPE  EQU 27           ;ESC is a reserved word....
PGUP    EQU "I"+EXTENDED
PGDOWN  EQU "Q"+EXTENDED   
RIGHT   EQU "M"+EXTENDED
LEFT    EQU "K"+EXTENDED    
DOWN    EQU "P"+EXTENDED    
UP      EQU "H"+EXTENDED
HOME	EQU 47h+EXTENDED
ENDKEY	EQU 4Fh+EXTENDED
F1	EQU 03bh+EXTENDED
F12     EQU 86h
INSERT  EQU 52h+EXTENDED

;file stuff
READONLY  EQU   BIT0
HIDDEN    EQU   BIT1
SYSTEM    EQU   BIT2
VOLUME    EQU   BIT3         ;ignored for file access
DIRECTORY EQU   BIT4         ;must be 0 for file access
ARCHIVE   EQU   BIT5
SHAREABLE EQU   BIT7         ;for novell networks
OPEN	EQU	2		; open existing file
CREATE	EQU	1		; create new file




; PCI equates
; PCI function address (PFA)
; bit 31 = 1
; bit 23:16 = bus number     (0-255)
; bit 15:11 = device number  (0-31)
; bit 10:8 = function number (0-7)
; bit 7:0 = register number  (0-255)

IO_ADDR_MASK    EQU     0FFFEh          ; mask off bit 0 for reading BARs
PCI_INDEX_PORT  EQU     0CF8h
PCI_DATA_PORT   EQU     0CFCh
PCI32           EQU     BIT31           ; bitflag to signal 32bit access
PCI16           EQU     BIT30           ; bitflag for 16bit access

PCI_FN0         EQU     (0 shl 8)
PCI_FN1         EQU     (1 shl 8)
PCI_FN2         EQU     (2 shl 8)
PCI_FN3         EQU     (3 shl 8)
PCI_FN4         EQU     (4 shl 8)
PCI_FN5         EQU     (5 shl 8)
PCI_FN6         EQU     (6 shl 8)
PCI_FN7         EQU     (7 shl 8)

PCI_CMD_REG		EQU	04h		; reg 04, command reg
 IO_ENA			EQU	BIT0
 MEM_ENA		EQU	BIT1
 BUS_MASTER             EQU     BIT2

; ISA equates
PORTA			EQU	060h		; 8742 Data port
PORTB			EQU	061h
  PARITY_BASE		EQU	080h		; Parity for base only
  PARITY_IO		EQU	040h		; Parity for I/O only
  PARITY_CHECKERS	EQU	0C0h		; Parity/IO channel error
  REFRESH_STATUS	EQU	010h		; Refresh signal status
  PARITY_DISABLED	EQU	00Ch		; Parity enable/disable bits
  SPEAKER		EQU	002h 		; Speaker Enable
  TIMER2_GATE		EQU	001h		; Timer 2 gate enable



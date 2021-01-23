; cmd line flags
DEBUG_MODE              equ     BIT0		; -d 
NEED_HELP               equ     BIT1		; -h or -? send help
NOL1			equ	BIT2		; -c override no L1 cache off
PCI_SCAN                equ     BIT3            ; PCI scan requested

; internal flags
NOACPI                  equ     BIT1            ; known incompatible chipset
SCAN2FILE		equ	BIT2		; output pci scan to file
THT12@5			equ	BIT3		; use 12.5% stepping table
THT6@25			equ	BIT4		; use 6.25% stepping table
IOTESTED		equ	BIT6		; flag for no endless loops
UNTESTED                equ     BIT7            ; this chipset is unknown


INTEL_VID		equ	8086h		; intel's vendor ID
VIA_VID			equ	1106h		; VIA
AMD_VID			equ	1022h		; AMD
MICRON_VID		equ	1344h		; micron
NVIDIA_VID              equ     10deh           ; nVidia
SIS_VID                 equ     1039h           ; SiS
ALI_VID                 equ     10b9h           ; ALI
ATI_VID			equ	1002h		; ATI

sbStruc struc
	vendorID	dw	08086h		; vendor ID
	deviceID	dw	07113h		; device ID
	ACPIBase	db	40h		; PCI base address reg	
	ACPIEnableReg	db	0		; PCI enable register
	ACPIEnableBit	db	0		; whatever bits need to be 1
	THT_IOReg	db	10h		; base+x to get to throttle
	THT_enaReg	db	10h		; whatever bits need to be 1
	SBFlags		db	0h		; misc flags
	userText	db	"Intel ICH  $"	; user text
sbStruc	ends


                        
START_IOBASE            equ     09000h          ; start of possible ACPI I/O
END_IOBASE              equ     0F000h          ; end of possible ACPI I/O
ACPI_SIZE               equ     100h            ; 256 bytes

THROTTLE_MASK           equ     1111b           ; clear all throttles
THROTTLE_625            equ     0001b           ; 6.25%
THROTTLE_125            equ     0010b           ; 12.5% throttled
THROTTLE_1875           equ     0011b           ; 18.75% 
THROTTLE_25             equ     0100b           ; 25% throttled
THROTTLE_3125           equ     0101b           ; 31.25%
THROTTLE_375            equ     0110b           ; 37.5% throttled
THROTTLE_4375           equ     0111b           ; 43.75
THROTTLE_50             equ     1000b           ; 50% throttled
THROTTLE_5625           equ     1001b           ; 56.25%
THROTTLE_6250           equ     1010b           ; 62.5% throttled
THROTTLE_6875           equ     1011b           ; 68.75%
THROTTLE_75             equ     1100b           ; 75% throttled
THROTTLE_8125           equ     1101b           ; 81.25%
THROTTLE_875            equ     1110b           ; 87.5% throttled
THROTTLE_9375           equ     1111b           ; 93.75%  


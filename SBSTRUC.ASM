comment %

structure of southbridge data (device ID, vendor ID, bits to toggle, etc)

ISA/LPC bridge: 0A=1 0B=06

10-10-07 added ICH8 (thanks Linards Ticmanis!)
        added a SLEW of ICH8 and 9 chipsets
        Intel is getting out of hand-should prolly come up with a better
        more robust solution for adding these, since the BAR never changes.

3-13-06 added ich6M

3-21-05 code cleanup, per suggestion of eric auer.
removed micron's chipset-no one has them anyway, and you can always use an
older version.


3-3-05 - changed via 596B device ID.  Was going to the ISA bridge, but ACPI
has been moved to a specific function now.

12-13-04 - readded VIA 8237 because I'm an idiot and somehow deleted it.


12-08-04 changed ali 1535 chipsets to use a different offset to find the ACPI
base address.  Either it was wrong before and no one complained about it,
or ALI has moved it without changing the device ID.
Either way, it works now, and we've got the back archive in case someone
needs it the old way.  Crazy.


10-15-04 added intel ICH 6


8-24-04 added via 8237

4-2-04: re-enabled sis 961.  Dunno what my problem was before, but it
works fine.


2-3-04 added ICH4-M


12-03-03 added ICH5

11-06-03 added Nvidia Nforce2 perhaps.


08-04-03
via 8231 device ID was typoed to 8235.  Duh.


07-28-03
added Via 586 rev F 
may need an additional read from register ACPI+14 to start throttling.

07-20-03
change AMD 768 to proper device ID 7443 instead of device 0.



02-25-03
added 8235 proper

12-16-02
added ali 153x support?

11-20-02
added Nvidia Nforce 1.
previous nvidia entry had wrong devID and base address register.


10-28-02
added via 596.  It was already there having a device ID as "596B".  Added
device ID "0596"  Cannot locate "596B" anywhere in datasheet land so the old
one can probably be removed.

10-18-02
web page says this supports the SiS 5513, which I can't find the vendor ID for.
added via 8235, hopefully backwards compatible with the 8233!
need to add SiS 960, 961 and 962!



%
        .DOSSEG
        .MODEL  small, c, os_dos

.386
.CODE

	extern	pciDevice:DWORD
	extern	pciDeviceID:DWORD



        INCLUDE constant.inc
        INCLUDE equates.inc
        INCLUDE macros.inc
;---------------------------------------------------------------------------
; getACPIBaseReg - return from the structure the PCI register that contains
;                  the ACPI I/O base address
; input: si->device entry 
; outpt: al - register value from the data structure
;
getACPIBaseReg proc public
;	push	si
;	call	strucLocate			; locate the device in struc
	mov	al, [si].sbStruc.ACPIBase	; read ACPI base register	
;	pop	si
	ret
getACPIBaseReg endp
;---------------------------------------------------------------------------
; getACPIEnableReg - return from the structure the PCI register that contains
;                    the ACPI I/O space enable register
; input: si->device entry 
; outpt: al - register value from the data structure
;	 ah - register data (bits to set) to enable I/O space
;
getACPIEnableReg proc public
;	push	si
;	call	strucLocate			; locate the device in struc
	mov	ax, word ptr [si].sbStruc.ACPIEnableReg	; read ACPI ena reg+data	
;	pop	si
	ret
getACPIEnableReg endp
;---------------------------------------------------------------------------
; getFlagsData - return from the structure the flags that are specific to this
;                chipset.
; input: si->device entry 
; outpt: al - flag data
;
getFlagsData proc public
;	push	si
;	call	strucLocate			; locate the device in struc
	mov	al, byte ptr [si].sbStruc.SBFlags ; read flags data	
;	pop	si
	ret
getFlagsData endp


;---------------------------------------------------------------------------
; getACPITHTReg - return from the structure the I/O register that controls
;                 cpu throttling.
; input: si->device entry
; outpt: al - register value from the data structure
;	 ah - bits that must be set to enable throttle
getACPITHTReg proc public
;	push	si
;	call	strucLocate			; locate the device in struc
	mov	ax, word ptr [si].sbStruc.THT_IOReg ; read ACPI ena reg+data	
;	pop	si
	ret
getACPITHTReg endp


;--------------------------------------------------------------------------
; strucLocate - point SI to the data structure for the desired device
; input: ds:[pciDeviceID] filled with selected device
; outpt: si points to structure
strucLocate proc
	push	eax
	mov	eax, ds:[pciDeviceID]		; load vendor/dev ID
	lea	si, ds:sbridgeData
@@:     
	cmp	word ptr [si], -1
	cmp	dword ptr [si].sbStruc.vendorID, eax	; match?
	jz	exit
	add	si, SIZEOF sbstruc
	jmp	@b
exit:
	pop	eax
	ret
strucLocate endp


.DATA
public sbridgeData
sbridgeData \
	    \
	    \
	dw	INTEL_VID		       	; intel's vendor ID
        dw      03a18h                          ; ICH device ID
	db	40h				; PCI reg 40 = base addy
	db	44				; acpi enable reg
	db	BIT4				; acpi enable bits
	db	10h				; base+10h = THT
	db	BIT4				; THT enable bits
	db	THT12@5				; 12.5% table flag
	db	"Intel ICH  $" 


	dw	INTEL_VID		       	; intel's vendor ID
	dw	02410h				; ICH device ID
	db	40h				; PCI reg 40 = base addy
	db	44				; acpi enable reg
	db	BIT4				; acpi enable bits
	db	10h				; base+10h = THT
	db	BIT4				; THT enable bits
	db	THT12@5				; 12.5% table flag
	db	"Intel ICH  $" 

        ; VIA 596B  2nd device ID?
      	dw	VIA_VID			       	; VIA vendor ID
        dw      3050h                           ; 596B device ID
        db      48h                             ; PCI reg 48 = base addy
	db	41h				; acpi enable reg
	db	BIT7				; acpi enable bits
	db	10h				; base+10h = THT
	db	10h				; THT enable bits
	db	THT6@25				; 6.5% table flag
	db	"VIA 596B   $"

	dw	INTEL_VID		       	; intel's vendor ID
        dw      02420h                          ; ICH0device ID
	db	40h				; PCI reg 40 = base addy
	db	44h				; acpi enable reg
	db	BIT4				; acpi enable bits
	db	10h				; base+10h = THT
	db	BIT4				; THT enable bits
	db	THT12@5				; 12.5% table flag
        db      "Intel ICH0 $"

	dw	INTEL_VID		       	; intel's vendor ID
	dw	02440h				; ICH2 device ID
	db	40h				; PCI reg 40 = base addy
	db	44h				; acpi enable reg
	db	BIT4				; acpi enable bits
	db	10h				; base+10h = THT
	db	BIT4				; THT enable bits
	db	THT12@5				; 12.5% table flag
        db      "Intel ICH2 $"

	dw	INTEL_VID		       	; intel's vendor ID
	dw	0244Ch				; ICH2 device ID
	db	40h				; PCI reg 40 = base addy
	db	44h				; acpi enable reg
	db	BIT4				; acpi enable bits
	db	10h				; base+10h = THT
	db	BIT4				; THT enable bits
	db	THT12@5				; 12.5% table flag
        db      "Intel ICH2m$"


	dw	INTEL_VID		       	; intel's vendor ID
        dw      024C0h                          ; ICH4 device ID
	db	40h				; PCI reg 40 = base addy
	db	44h				; acpi enable reg
	db	BIT4				; acpi enable bits
	db	10h				; base+10h = THT
	db	BIT4				; THT enable bits
	db	THT12@5				; 12.5% table flag
        db      "Intel ICH4 $"


	dw	INTEL_VID		       	; intel's vendor ID
        dw      02480h                          ; ICH3s device ID
	db	40h				; PCI reg 40 = base addy
	db	44h				; acpi enable reg
	db	BIT4				; acpi enable bits
	db	10h				; base+10h = THT
	db	BIT4				; THT enable bits
	db	THT12@5				; 12.5% table flag
        db      "Intel ICH3s$"

	dw	INTEL_VID		       	; intel's vendor ID
        dw      0248Ch                          ; ICH3m device ID
	db	40h				; PCI reg 40 = base addy
	db	44h				; acpi enable reg
	db	BIT4				; acpi enable bits
	db	10h				; base+10h = THT
	db	BIT4				; THT enable bits
	db	THT12@5				; 12.5% table flag
        db      "Intel ICH3m$"

	dw	INTEL_VID		       	; intel's vendor ID
        dw      024CCh                          ; ICH5 device ID
	db	40h				; PCI reg 40 = base addy
	db	44h				; acpi enable reg
	db	BIT4				; acpi enable bits
	db	10h				; base+10h = THT
	db	BIT4				; THT enable bits
	db	THT12@5				; 12.5% table flag
        db      "Intel ICH4M$"

        dw      INTEL_VID                       ; intel's vendor ID
        dw      024d0h                          ; ICH5 device ID
        db      40h                             ; PCI reg 40 = base addy
        db      44h                             ; acpi enable reg
        db      BIT4                            ; acpi enable bits
        db      10h                             ; base+10h = THT
        db      BIT4                            ; THT enable bits
        db      THT12@5                         ; 12.5% table flag
        db      "Intel ICH5 $"

	dw	INTEL_VID		       	; intel's vendor ID
        dw      02640h                          ; ICH6 device ID
	db	40h				; PCI reg 40 = base addy
	db	44h				; acpi enable reg
	db	BIT4				; acpi enable bits
	db	10h				; base+10h = THT
	db	BIT4				; THT enable bits
	db	THT12@5				; 12.5% table flag
        db      "Intel ICH6 $"

	dw	INTEL_VID		       	; intel's vendor ID
        dw      02641h                          ; ICH6M device ID
	db	40h				; PCI reg 40 = base addy
	db	44h				; acpi enable reg
        db      BIT7                            ; acpi enable bits in PCI
	db	10h				; base+10h = THT
	db	BIT4				; THT enable bits
	db	THT12@5				; 12.5% table flag
        db      "Intel ICH6M$"

	dw	INTEL_VID		       	; intel's vendor ID
        dw      027B9h                          ; ICH7 device ID
	db	40h				; PCI reg 40 = base addy
	db	44h				; acpi enable reg
        db      BIT7                            ; acpi enable bits in PCI
	db	10h				; base+10h = THT
	db	BIT4				; THT enable bits
	db	THT12@5				; 12.5% table flag
        db      "Intel ICH7 $"

	dw	INTEL_VID		       	; intel's vendor ID
        dw      027B8h                          ; ICH7 device ID
	db	40h				; PCI reg 40 = base addy
	db	44h				; acpi enable reg
        db      BIT7                            ; acpi enable bits in PCI
	db	10h				; base+10h = THT
	db	BIT4				; THT enable bits
	db	THT12@5				; 12.5% table flag
        db      "Intel ICH7M$"

	dw	INTEL_VID		       	; intel's vendor ID
        dw      027B0h                          ; ICH7 device ID
	db	40h				; PCI reg 40 = base addy
	db	44h				; acpi enable reg
        db      BIT7                            ; acpi enable bits in PCI
	db	10h				; base+10h = THT
	db	BIT4				; THT enable bits
	db	THT12@5				; 12.5% table flag
        db      "Intel ICH7 $"

	dw	INTEL_VID		       	; intel's vendor ID
        dw      027BCh                          ; ICH7 device ID
	db	40h				; PCI reg 40 = base addy
	db	44h				; acpi enable reg
        db      BIT7                            ; acpi enable bits in PCI
	db	10h				; base+10h = THT
	db	BIT4				; THT enable bits
	db	THT12@5				; 12.5% table flag
        db      "Intel ICH7 $"



	dw	INTEL_VID		       	; intel's vendor ID
        dw      02810h                          ; ICH8 device ID
	db	40h				; PCI reg 40 = base addy
	db	44h				; acpi enable reg
        db      BIT7                            ; acpi enable bits in PCI
	db	10h				; base+10h = THT
	db	BIT4				; THT enable bits
	db	THT12@5				; 12.5% table flag
        db      "Intel ICH8 $"

	dw	INTEL_VID		       	; intel's vendor ID
        dw      02811h                          ; ICH8 ME device ID
	db	40h				; PCI reg 40 = base addy
	db	44h				; acpi enable reg
        db      BIT7                            ; acpi enable bits in PCI
	db	10h				; base+10h = THT
	db	BIT4				; THT enable bits
	db	THT12@5				; 12.5% table flag
        db      "IntelICH8ME$"

	dw	INTEL_VID		       	; intel's vendor ID
        dw      02812h                          ; ICH8 DH device ID
	db	40h				; PCI reg 40 = base addy
	db	44h				; acpi enable reg
        db      BIT7                            ; acpi enable bits in PCI
	db	10h				; base+10h = THT
	db	BIT4				; THT enable bits
	db	THT12@5				; 12.5% table flag
        db      "IntelICH8DH$"

	dw	INTEL_VID		       	; intel's vendor ID
        dw      02814h                          ; ICH8 DO device ID
	db	40h				; PCI reg 40 = base addy
	db	44h				; acpi enable reg
        db      BIT7                            ; acpi enable bits in PCI
	db	10h				; base+10h = THT
	db	BIT4				; THT enable bits
	db	THT12@5				; 12.5% table flag
        db      "IntelICH8DO$"

	dw	INTEL_VID		       	; intel's vendor ID
        dw      02815h                          ; ICH8M device ID
	db	40h				; PCI reg 40 = base addy
	db	44h				; acpi enable reg
        db      BIT7                            ; acpi enable bits in PCI
	db	10h				; base+10h = THT
	db	BIT4				; THT enable bits
	db	THT12@5				; 12.5% table flag
        db      "Intel ICH8M$"

	dw	INTEL_VID		       	; intel's vendor ID
        dw      02912h                          ; ICH9 DH device ID
	db	40h				; PCI reg 40 = base addy
	db	44h				; acpi enable reg
        db      BIT7                            ; acpi enable bits in PCI
	db	10h				; base+10h = THT
	db	BIT4				; THT enable bits
	db	THT12@5				; 12.5% table flag
        db      "IntelICH9DH$"

	dw	INTEL_VID		       	; intel's vendor ID
        dw      02914h                          ; ICH9 DO device ID
	db	40h				; PCI reg 40 = base addy
	db	44h				; acpi enable reg
        db      BIT7                            ; acpi enable bits in PCI
	db	10h				; base+10h = THT
	db	BIT4				; THT enable bits
	db	THT12@5				; 12.5% table flag
        db      "IntelICH9DO$"

	dw	INTEL_VID		       	; intel's vendor ID
        dw      02916h                          ; ICH9 R device ID
	db	40h				; PCI reg 40 = base addy
	db	44h				; acpi enable reg
        db      BIT7                            ; acpi enable bits in PCI
	db	10h				; base+10h = THT
	db	BIT4				; THT enable bits
	db	THT12@5				; 12.5% table flag
        db      "IntelICH9R $"

	dw	INTEL_VID		       	; intel's vendor ID
        dw      02917h                          ; ICH9 mobil device ID
	db	40h				; PCI reg 40 = base addy
	db	44h				; acpi enable reg
        db      BIT7                            ; acpi enable bits in PCI
	db	10h				; base+10h = THT
	db	BIT4				; THT enable bits
	db	THT12@5				; 12.5% table flag
        db      "Intel Mobil$"

	dw	INTEL_VID		       	; intel's vendor ID
        dw      02918h                          ; ICH9 ICH9B device ID
	db	40h				; PCI reg 40 = base addy
	db	44h				; acpi enable reg
        db      BIT7                            ; acpi enable bits in PCI
	db	10h				; base+10h = THT
	db	BIT4				; THT enable bits
	db	THT12@5				; 12.5% table flag
        db      "Intel ICH9B$"



	dw	INTEL_VID		       	; intel's vendor ID
        dw      0719Bh                          ; 82440MX
	db	40h				; PCI reg 40 = base addy
	db	44h				; acpi enable reg
	db	BIT4				; acpi enable bits
	db	10h				; base+10h = THT
	db	BIT4				; THT enable bits
        db      THT12@5                         ; 12.5% table flag
        db      "Intel 440MX$"


; moved here to avoid a conflict with another VIA device with the
; device ID of the 686B 1106 - 3068

        ; VIA 8235
      	dw	VIA_VID			       	; VIA vendor ID
        dw      03177h                          ; 8231 device ID
        db      88h                             ; PCI reg 48 = base addy
        db      00h                             ; acpi enable reg
        db      00h                             ; acpi enable bits
	db	10h				; base+10h = THT
	db	10h				; THT enable bits
	db	THT6@25				; 6.5% table flag
        db      "VIA 8235 II$"

        ; VIA 3227
      	dw	VIA_VID			       	; VIA vendor ID
        dw      03227h                          ; 8237 device ID
        db      88h                             ; PCI reg 88 = base addy
        db      00h                             ; acpi enable reg
        db      00h                             ; acpi enable bits
	db	10h				; base+10h = THT
	db	10h				; THT enable bits
        db      THT6@25                         ; 6.5% table flag
        db      "VIA 3227   $"

        ; VIA 3337
      	dw	VIA_VID			       	; VIA vendor ID
        dw      03337h                          ; 8237 device ID
        db      88h                             ; PCI reg 88 = base addy
        db      00h                             ; acpi enable reg
        db      00h                             ; acpi enable bits
	db	10h				; base+10h = THT
	db	10h				; THT enable bits
        db      THT6@25                         ; 6.5% table flag
        db      "VIA 8337   $"


	; VIA 586F
      	dw	VIA_VID			       	; VIA vendor ID
	dw	03040h				; 586 Rev F device ID
        db      48h                             ; PCI reg 48 = base addy
	db	41h				; acpi enable reg
	db	80h				; acpi enable bits
	db	10h				; base+10h = THT
	db	10h				; THT enable bits
        db      THT6@25                         ; 12.5% table flag
	db	"VIA 586-F  $"


	; VIA 686B
      	dw	VIA_VID			       	; VIA vendor ID
	dw	03068h				; 686B device ID
        db      48h                             ; PCI reg 48 = base addy
	db	41h				; acpi enable reg
	db	80h				; acpi enable bits
	db	10h				; base+10h = THT
	db	10h				; THT enable bits
	db	THT6@25				; 6.5% table flag
	db	"VIA 686B   $"



	; VIA 686A
      	dw	VIA_VID			       	; VIA vendor ID
	dw	03057h				; 686A device ID
        db      48h                             ; PCI reg 48 = base addy
	db	41h				; acpi enable reg
	db	BIT7				; acpi enable bits
	db	10h				; base+10h = THT
	db	10h				; THT enable bits
	db	THT6@25				; 6.5% table flag
	db	"VIA 686A   $"

	; VIA 596B
      	dw	VIA_VID			       	; VIA vendor ID
	dw	0596Bh				; 596B device ID
        db      48h                             ; PCI reg 48 = base addy
	db	41h				; acpi enable reg
	db	BIT7				; acpi enable bits
	db	10h				; base+10h = THT
	db	10h				; THT enable bits
	db	THT6@25				; 6.5% table flag
	db	"VIA 596B   $"

	; VIA 586
;      	dw	VIA_VID			       	; VIA vendor ID
;	dw	0586h				; 596B device ID
;!!        db      48h                             ; PCI reg 48 = base addy
;	db	41h				; acpi enable reg
;	db	BIT7				; acpi enable bits
;	db	10h				; base+10h = THT
;	db	10h				; THT enable bits
;	db	THT6@25				; 6.5% table flag
;	db	"VIA 596B   $"



; have another 8231 with ISA bridge having an ID of 8231
; except the BAR is incorrect.
; however, there is also an 8235 ID and the BAR appears to be in the same
; location (48h) as the 8231

	; VIA 8231
      	dw	VIA_VID			       	; VIA vendor ID
        dw      08231h                          ; 8231 device ID
        db      48h                             ; PCI reg 48 = base addy
	db	41h				; acpi enable reg
	db	80h				; acpi enable bits
	db	10h				; base+10h = THT
	db	10h				; THT enable bits
	db	THT6@25				; 6.5% table flag
	db	"VIA 8231   $"


        ; AMD 755 
      	dw	AMD_VID			       	; AMD vendor ID
        dw      07403h                          ; 755 device ID
        db      58h                             ; PCI reg 58 = base addy
	db	41h				; acpi enable reg
	db	80h				; acpi enable bits
	db	10h				; base+10h = THT
	db	10h				; THT enable bits
        db      THT12@5+UNTESTED                ; 12.5% table flag
        db      "AMD 755    $"

        ; AMD 756 
      	dw	AMD_VID			       	; AMD vendor ID
        dw      0740Bh                          ; 756 device ID
        db      58h                             ; PCI reg 58 = base addy
	db	41h				; acpi enable reg
	db	80h				; acpi enable bits
	db	10h				; base+10h = THT
	db	10h				; THT enable bits
        db      THT12@5+UNTESTED                ; 12.5% table flag
        db      "AMD 756    $"

        ; AMD 766 
      	dw	AMD_VID			       	; AMD vendor ID
        dw      07413h                          ; 766 device ID
        db      58h                             ; PCI reg 58 = base addy
	db	41h				; acpi enable reg
	db	80h				; acpi enable bits
	db	10h				; base+10h = THT
	db	10h				; THT enable bits
	db	THT12@5				; 12.5% table flag
        db      "AMD 766    $"

	; AMD 768
      	dw	AMD_VID			       	; AMD vendor ID
        dw      07443h                          ; 768 device ID
        db      58h                             ; PCI reg 58 = base addy
	db	41h				; acpi enable reg
	db	80h				; acpi enable bits
	db	10h				; base+10h = THT
	db	10h				; THT enable bits
        db      THT12@5                         ; 12.5% table flag
	db	"AMD 768    $"

	; AMD Geode companion
      	dw	AMD_VID			       	; AMD vendor ID
        dw      2090h                           ; geode device ID
        db      24h                             ; PCI reg 24 = base addy
	db	00h				; acpi enable reg
	db	00h				; acpi enable bits
	db	00h				; base+0h = THT
	db	10h				; THT enable bits
        db      THT12@5                         ; 12.5% table flag
	db	"AMD Geode  $"



; the following chipsets are not supported properly.  ACPI cannot be
; enabled or disabled, as I have no idea where the registers are that control
; em.  So far this has not been much of a problem.
; see below notes for how the c503 is implemented/experimental.

        ; SiS 85C503
        dw      SIS_VID                         ; SiS vendor ID
        dw      0008h                           ; 008  device ID -root is 530
        db      68h                             ; trying 90 now PCI reg 74 = base addy
        db      40h                             ; acpi enable reg
        db      80h                             ; acpi enable bits
	db	10h				; base+10h = THT
	db	10h				; THT enable bits
        db      THT12@5+UNTESTED                ; 12.5% table flag
        db      "SiS 85C503 $"

	;pm1a for the above is pointing to 0x8000
	;maybe at 68, but only a 16bit  90 and 74 definitely not as claimed above

; SiS 85C503  #2 - if the above bombs out, maybe this will work
        dw      SIS_VID                         ; SiS vendor ID
        dw      0008h                           ; 008  device ID -root is 530
        db      74h                             ; trying 90 now PCI reg 74 = base addy
        db      40h                             ; acpi enable reg
        db      80h                             ; acpi enable bits
	db	10h				; base+10h = THT
	db	10h				; THT enable bits
        db      THT12@5+UNTESTED                ; 12.5% table flag
        db      "SiS 85C5032$"


        ; Nvidia Nforce
        dw      NVIDIA_VID                      ; Nvidia vendor ID
        dw      010b2h                          ; NForce device ID
        db      48h                             ; PCI reg 48 = base addy
        db      00h                             ; acpi enable reg
        db      00h                             ; acpi enable bits
	db	10h				; base+10h = THT
	db	10h				; THT enable bits
        db      THT12@5                         ; 12.5% table flag
        db      "NvidiaNforc$"
;test1=60h
;test2=64
;test3=68h 68 seems to work?
        ; Nvidia Nforce2
        dw      NVIDIA_VID                      ; Nvidia vendor ID
        dw      00060h                          ; NForce2 device ID
        db      68h                             ; PCI reg 8c = base addy
        db      00h                             ; acpi enable reg
        db      00h                             ; acpi enable bits
	db	10h				; base+10h = THT
	db	10h				; THT enable bits
        db      THT12@5+UNTESTED                ; 12.5% table flag
        db      "Nvda Nforc2$"

	; Nvidia Nforce2
        dw      NVIDIA_VID                      ; Nvidia vendor ID
        dw      00050h                          ; NForce2 device ID
        db      60h                             ; PCI reg 60 = base addy (alwasys seems to be base address 1000h)
        db      00h                             ; acpi enable reg
        db      00h                             ; acpi enable bits
	db	10h				; base+10h = THT
	db	10h				; THT enable bits
        db      THT12@5                         ; 12.5% table flag
        db      "Nvda Nforc2$"


        ; Nvidia Nforce
        dw      NVIDIA_VID                      ; Nvidia vendor ID
        dw      01b2h                           ; NForce device ID
        db      84h                             ; PCI reg 84 = base addy
        db      00h                             ; acpi enable reg
        db      00h                             ; acpi enable bits
	db	10h				; base+10h = THT
	db	10h				; THT enable bits
        db      THT6@25+UNTESTED                ; 12.5% table flag
        db      "NvidiaNforc$"

        ; Nvidia Gforce
        dw      NVIDIA_VID                      ; Nvidia vendor ID
        dw      07d8h                           ; GForce 610i device ID
        db      060h                            ; PCI reg 60? = base addy - 
;totally cheated, this isn't even the right function to get a value of 1000
        db      00h                             ; acpi enable reg
        db      00h                             ; acpi enable bits
	db	10h				; base+10h = THT
	db	10h				; THT enable bits
        db      THT12@5+UNTESTED                ; 12.5% table flag
        db      "NvidiaGforc$"


        ; Via 8233
        dw      VIA_VID                         ; Via vendor ID
        dw      03074h                          ; 8233 device ID
        db      88h                             ; PCI reg 88 = base addy
        db      00h                             ; acpi enable reg
        db      00h                             ; acpi enable bits
	db	10h				; base+10h = THT
	db	10h				; THT enable bits
        db      THT6@25                         ; 6.25% table flag
        db      "Via 8233   $"

        ; Via 8233A
        dw      VIA_VID                         ; Via vendor ID
        dw      03147h                          ; 8233A device ID
        db      88h                             ; PCI reg 88 = base addy
        db      00h                             ; acpi enable reg
        db      00h                             ; acpi enable bits
	db	10h				; base+10h = THT
	db	10h				; THT enable bits
        db      THT6@25+UNTESTED                ; 6.25% table flag
        db      "Via 8233A  $"

        ; Via 8235 
        dw      VIA_VID                         ; Via vendor ID
        dw      08235h                          ; 8235  device ID
        db      88h                             ; PCI reg 88 = base addy
        db      00h                             ; acpi enable reg
        db      00h                             ; acpi enable bits
	db	10h				; base+10h = THT
	db	10h				; THT enable bits
        db      THT6@25+UNTESTED                ; 6.25% table flag
        db      "Via 8235   $"

	; VIA 8231 - this is a known working one
      	dw	VIA_VID			       	; VIA vendor ID
        dw      08235h                          ; 8231 device ID
        db      48h                             ; PCI reg 48 = base addy
	db	41h				; acpi enable reg
	db	80h				; acpi enable bits
	db	10h				; base+10h = THT
	db	10h				; THT enable bits
	db	THT6@25				; 6.5% table flag
	db	"VIA 8231-5 $"



        ; ati SB600 southbridge #2		; whoa, ati?
        ; NO IDEA how this one works.
        ; acpidump claims the PM1A base address is 800
        ; actual LPC bridge is device 438D.
        ; fudged the device ID to 9806 and to read a known not BAR
        ; to end up at 800.  friggen ati and their non-release of datasheets!
        dw      ATI_VID                         ; ATI vendor ID
        dw      09806h                          ; sb600  device ID
        db      60h                             ; PCI reg 60 = base addy
        db      00h                             ; acpi enable reg
        db      00h                             ; acpi enable bits
	db	10h				; base+10h = THT
	db	10h				; THT enable bits
        db      THT6@25+UNTESTED                ; 6.25% table flag
        db      "ATI SB600  $"



        ; ati SB600 southbridge 		; whoa, ati?
        ; NO IDEA how this one works.
        ; acpidump claims the PM1A base address is 4000, but that
        ; doesn't show up anywhere in PCI dump.
        ; actual LPC bridge is device 438D.
        ; fudged the device ID to 4383 and to read a known not BAR
        ; to end up at 4000.  friggen ati and their non-release of datasheets!
        dw      ATI_VID                         ; ATI vendor ID
        dw      04384h                          ; sb600  device ID
        db      0ch                             ; PCI reg 88 = base addy
        db      00h                             ; acpi enable reg
        db      00h                             ; acpi enable bits
	db	10h				; base+10h = THT
	db	10h				; THT enable bits
        db      THT6@25+UNTESTED                ; 6.25% table flag
        db      "ATI SB600  $"






;90 test1
;44
;4a
;66
;6c
           ;
           ; dec 7th 2004.
           ; changed base address register from E2 to E0 because of acpidump
           ; report.  Confusing, as I thought this one had been tested already
           ; unless newer chipsets moved the base address and kept the old
           ; device/vendor ID.  
           ;

        ; Ali M153x
        dw      ALI_VID                         ; ALI vendor ID
        dw      07101h                          ; 153x  device ID
        db      0e0h                            ; PCI reg E2 = base addy?
        db      00h                             ; acpi enable reg
        db      00h                             ; acpi enable bits
	db	10h				; base+10h = THT
	db	10h				; THT enable bits
        db      THT12@5                         ; 12.5% table flag
        db      "Ali M1535  $"

	dw      ALI_VID                         ; ALI vendor ID
        dw      01533h                          ; 153x  device ID
        db      0a5h                            ; PCI reg a5 = base addy?
        db      00h                             ; acpi enable reg
        db      00h                             ; acpi enable bits
	db	10h				; base+10h = THT
	db	10h				; THT enable bits
        db      THT6@25                         ; 12.5% table flag
        db      "Ali Alddn V$"

        ; SiS 960
        dw      SIS_VID                         ; SiS vendor ID
        dw      00961h                          ; 961  device ID
        db      74h                             ; PCI reg 74 = base addy
        db      40h                             ; acpi enable reg
        db      80h                             ; acpi enable bits
        db      10h                             ; base+10h = THT
        db      10h                             ; THT enable bits
        db      THT12@5                         ; 12.5% table flag
        db      "SiS 960/1  $"

        ; SiS 962
        dw      SIS_VID                         ; SiS vendor ID
        dw      00962h                          ; 962 device ID
        db      74h                             ; PCI reg 74 = base addy?
        db      40h                             ; acpi enable reg
        db      80h                             ; acpi enable bits
        db      10h                             ; base+10h = THT
        db      10h                             ; THT enable bits
        db      THT12@5+UNTESTED                ; 12.5% table flag
        db      "SiS 962    $"
;test! 6-1-06
        ; SiS 964
        dw      SIS_VID                         ; SiS vendor ID
        dw      00964h                          ; 964 device ID
        db      74h                             ; PCI reg 74 = base addy?
        db      40h                             ; acpi enable reg
        db      80h                             ; acpi enable bits
        db      10h                             ; base+10h = THT
        db      10h                             ; THT enable bits
        db      THT12@5+UNTESTED                ; 12.5% table flag
        db      "SiS 964    $"
;end
	; Piix4
        dw      INTEL_VID                       ; intel's vendor ID
        dw      07113h                          ; piix 4 device ID
        db      40h                             ; PCI reg 40 = base addy
        db      80h                             ; acpi enable reg
        db      BIT0                            ; acpi enable bits
        db      10h                             ; base+10h = THT
        db      BIT4                            ; THT enable bits
        db      THT12@5                         ; 12.5% table flag
        db      "Intel PIIX4$"



;
;known incompatible devices:
;piix: 8086-122e
;piix3: 8086-7000
; 
;
        ; Piix
        dw      INTEL_VID                       ; intel's vendor ID
        dw      0122eh                          ; piix device ID
        db      00h                             ; 
        db      00h                             ; 
        db      0                               ; 
        db      0                               ; 
        db      0                               ; 
        db      NOACPI                          ; Error flag
        db      "Intel PIIX $"

        ; Piix 3
        dw      INTEL_VID                       ; intel's vendor ID
        dw      07000h                          ; piix 3 device ID
        db      00h                             ; 
        db      00h                             ; 
        db      0                               ; 
        db      0                               ; 
        db      0                               ; 
        db      NOACPI                          ; Error flag
        db      "Intel PIIX3$"

        ; VIA 82C694
        dw      VIA_VID                         ; via
        dw      8598h                          ; 82c694 (bridge)
        db      00h                             ; 
        db      00h                             ; 
        db      0                               ; 
        db      0                               ; 
        db      0                               ; 
        db      NOACPI                          ; Error flag
        db      "VIA  82c694$"


dw	-1


End


comment %
; SiS 85C503
; ACPIDUMP says that A1 base is 5000.
  
Bus:00 Dev:00 Fn:00 PFA:00000000 1039 0530      
0   1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
39 10 30 05 07 00 10 22 02 00 00 06 00 40 80 00
00 00 00 E0 00 00 00 00 00 00 00 00 00 00 00 00 
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
00 00 00 00 C0 00 00 00 00 00 00 00 00 00 00 00 
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
60 DA A0 00 00 0F B2 00 50 00 00 00 00 18 00 00 
2A 2A 00 73 00 00 00 00 C0 00 01 50 00 00 00 00 =6b
88 A0 00 00 00 00 88 00 00 00 00 00 00 00 00 00 
40 C0 8E 03 60 00 03 44 00 10 AB 00 48 00 00 00 
00 00 00 00 40 00 00 01 00 00 00 00 00 00 00 00 
40 40 80 00 00 00 00 00 00 00 00 00 00 00 00 00 
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
02 00 20 00 03 02 00 1F 00 00 00 00 00 00 00 00 
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
                                                
Bus:00 Dev:00 Fn:01 PFA:00000100 1039 5513      
39 10 13 55 07 00 00 00 D0 8A 01 01 00 80 80 00 
F1 01 00 00 F5 03 00 00 71 01 00 00 75 03 00 00 
01 40 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
00 00 00 00 00 00 00 00 00 00 00 00 0E 01 00 00 
00 00 01 03 01 B3 00 00 33 07 C6 DD 00 02 00 02 
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
                                                
Bus:00 Dev:01 Fn:00 PFA:00000800 1039 0008      
 0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
39 10 08 00 0F 00 00 02 B1 00 01 06 00 00 80 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
F8 0B 80 80 0A 04 00 02 FF FF 10 0F 11 08 04 01 
11 70 02 01 20 00 20 00 00 00 12 00 00 05 34 00 
10 80 75 00 34 01 00 00 90 02 09 00 20 14 00 00 
1E 00 20 0C 80 08 00 00 00 00 00 80 00 00 80 00 tried 74 before, not good here.
01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
00 50 00 00 00 00 00 00 00 00 00 00 00 00 00 00 how about 00-0?
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
%

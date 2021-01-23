
        .DOSSEG
        .MODEL  small, c, os_dos

.586
.CODE

        INCLUDE constant.inc
	INCLUDE macros.inc
	INCLUDE equates.inc

	extern	printreg:NEAR
        extern  NTDetect:NEAR
        extern  hex2ascii:NEAR
	extern	open_file:NEAR
	extern	close_file:NEAR
	extern	filehandle:WORD
	extern	flags:BYTE
;===============================================================
; 8/16/32bit PCI reader
;
; Entry: EAX=PCI Bus/Device/fn/register number
;           BIT30 set if 32 bit access requested
;           BIT29 set if 16 bit access requested
;           otherwise defaults to 8bit read
;
; Exit:  DL,DX,EDX register data depending on requested read size
;
; Note: this routine is meant to be called via pciRegRead8, pciRegread16,
;	or pciRegRead32, listed below.
;
; Note2: don't attempt to read 32bits of data from a non dword aligned reg
;	 number.  Likewise, don't do 16bit reads from non word aligned reg #
;        
pciRegRead proc public

	push	ebx
	push	cx
        mov     ebx, eax                        ; save eax, dh
        mov     cl, dh
        and     eax, NOT PCI32+PCI16            ; clear out data size request
        or      eax, BIT31                      ; make a PCI access request
        and     al, NOT 3                       ; force index to be dword

        mov     dx, PCI_INDEX_PORT
        out     dx, eax                         ; write PCI selector

        mov     dx, PCI_DATA_PORT
        mov     al, bl
        and     al, 3                           ; figure out which port to
        add     dl, al                          ; read to

	in      eax, dx                         ; do 32bit read
        test    ebx, PCI32
        jz      @f

        mov     edx, eax                        ; return 32bits of data
@@:
	mov     dx, ax                          ; return 16bits of data
        test    ebx, PCI32+PCI16
        jnz     @f
        mov     dh, cl                          ; restore dh for 8 bit read
@@:
        mov     eax, ebx                        ; restore eax
        and     eax, NOT PCI32+PCI16            ; clear out data size request
	pop	cx
	pop	ebx
	ret
pciRegRead      endp


public pciRegRead8 
public pciRegRead16
public pciRegRead32 

pciRegRead8:
        and     eax, NOT PCI16+PCI32            ; set up 8 bit read size
        jmp     pciRegRead			; call generic PCI access

pciRegRead16:
        and     eax, NOT PCI16+PCI32		; set up 16 bit read size
        or      eax, PCI16			; call generic PCI access
        jmp     pciRegRead

pciRegRead32:
        and     eax, NOT PCI16+PCI32		; set up 32 bit read size
        or      eax, PCI32			; call generic PCI access
        jmp     pciRegRead




;===============================================================
; 8/16/32bit PCI writer
;
; Entry: EAX=PCI Bus/Device/fn/register number
;           BIT31 set if 32 bit access requested
;           BIT30 set if 16 bit access requested
;           otherwise defaults to 8bit read
;        DL/DX/EDX data to write depending on size
;
;
; note: this routine is meant to be called via pciRegWrite8, pciRegWrite16,
; 	or pciRegWrite32 as detailed below.
;
; Note2: don't attempt to write 32bits of data from a non dword aligned reg
;	 number.  Likewise, don't do 16bit writes from non word aligned reg #
;
pciRegWrite proc

	push	ebx
	push	cx
        mov     ebx, eax                        ; save eax, dx
        mov     cx, dx
        or      eax, BIT31                      ; make a PCI access request
        and     eax, NOT PCI16                  ; clear out data size request
        and     al, NOT 3                       ; force index to be dword

        mov     dx, PCI_INDEX_PORT
        out     dx, eax                         ; write PCI selector

        mov     dx, PCI_DATA_PORT
        mov     al, bl
        and     al, 3                           ; figure out which port to
        add     dl, al                          ; write to

        mov     eax, edx                        ; put data into eax
        mov     ax, cx

        out     dx, al
        test    ebx, PCI16+PCI32                ; only 8bit access? bail
        jz      @f

        out     dx, ax                          ; write 16 bit value
        test    ebx, PCI16                      ; 16bit requested?  bail
        jnz     @f

        out     dx, eax                         ; write full 32bit
@@:
        mov     eax, ebx                        ; restore eax
        and     eax, NOT PCI32+PCI16            ; clear out data size request
        mov     dx, cx                          ; restore dx
	pop	cx
	pop	ebx
	ret
pciRegWrite      endp


public  pciRegWrite8
public  pciRegWrite16
public  pciRegWrite32

pciRegWrite8:
        and     eax, NOT PCI16+PCI32		; set up 8 bit write size
        jmp     pciRegWrite			; call generic PCI access

pciRegWrite16:
        and     eax, NOT PCI16+PCI32		; set up 16 bit write size
        or      eax, PCI16			; call generic PCI access
        jmp     pciRegWrite

pciRegWrite32:
        and     eax, NOT PCI16+PCI32		; set up 32 bit write size
        or      eax, PCI32			; call generic PCI access
        jmp     pciRegWrite





;===============================================================
; locatePCIDevice: scan through PCI space looking for a device+vendor ID
;
; Entry: EAX=Device+vendor ID
;
;  Exit: EAX=PCI address if device found
;        CY clear if found, set if not found. EAX invalid if CY set.
;
; [old stackless] Destroys: ebx, edx, esi, edi, cl
;
locatePCIDevice proc  near public

	push	cx
	push	edx
	push	esi
	push	edi

        mov     esi, eax                ; save off vend+device ID
        mov     edi, (80000000h - 100h) ; start with bus 0, dev 0 func 0

nextPCIdevice:
        add     edi, 100h
        cmp     edi, 8001f800h          ; scanned all devices?
        stc
        jz      PCIscanExit             ; not found

        mov     eax, edi                ; read PCI registers
        call    pciRegRead32
        cmp     edx, esi                ; found device?
        jnz     nextPCIDevice
        clc

PCIScanExit:
	pushf
	mov	eax, edi		; return found PCI address
	and	eax, NOT BIT31		; return only bus/dev/fn #
	popf

	pop	edi
	pop	esi
	pop	edx
	pop	cx
	ret
locatePCIDevice endp





pciScan proc public
	push	dx
	push	ax
	lea	dx, fname
	mov	al, CREATE
	call	open_file
	pop	ax
	pop	dx


        mov     ecx, 80000000h          ; start with bus 0, dev 0 func 0
        sub     ecx, 100h               ; 

nextdevice:
	mov	ebx, edx		; save current value
        add     ecx, 100h
        cmp     ecx, 8001f000h
        jz      exit

        mov     eax, ecx                ; should prolly change this to 
        call    pciRegRead32

        cmp     dx, -1
        jz      nextDevice

	cmp	edx, ebx  		; same as last device? skipit
	jz	nextDevice

        ;
        ; found a device.  Print all registers
        ;
        mov     pciFlag, 1              ; set a flag
	push	eax
	push	ecx

        call    printbusDevFn
        call    regs2file

	pop	ecx
	pop	eax
        jmp     nextDevice

exit:
	call	close_file

        cmp     pciFlag, 0
        jnz     @f

        WriteLNCR ' '
        WriteLNCR 'No PCI devices found.'
        call    NTDetect
        jnc     @f
        WriteLNCR 'giveio.sys driver not installed!?'
@@:

	writeLNCR 'PCI scan complete.  Output is in file PCISCAN.TXT'
	ret
pciFlag db      0
pciScan	endp

; print the bus, device, FN, PFA, venID and devID numbers to the screen
; entry: EAX = PFA, EDX=ven,Dev IDs
;
printbusDevFn proc public
        push    eax
        push    ebx
        push    cx
        push    dx
        push    si
        push    di
        push    es

        push    ds
        pop     es


        lea     di, line

        mov     ebx, eax

        lea     si, busMsg
        mov     cx, 4
        rep     movsb

        
        bswap   ebx
        mov     al, bh
        call    hex2ascii
        xchg    ah, al
        stosw

        bswap   ebx

	lea	si, DevMsg
	mov	cx, 5
	rep	movsb


        mov     al, bh
        shr     al, 3

     	call	hex2ascii
	xchg	ah, al
	stosw


     	lea	si, FNMsg
	mov	cx, 4
	rep	movsb


        mov     al, bh
        and     al, 7
       
	call	hex2ascii
 	xchg	ah, al
	stosw
	      	
     
      	lea	si, pfaMsg
	mov	cx, 5
	rep	movsb


	mov	cx, 4
@@:	
	rol	ebx, 8
	mov	al, bl
	call	hex2ascii
	xchg	ah, al
	stosw
	loop	@b

	mov	al, " "
	stosb


	mov	ebx, edx
	ror	ebx, 16

	;
	; vendor ID
	;
	mov	cx, 2

@@:
	rol	ebx, 8
	mov	al, bl
	call	hex2ascii
	xchg	ah, al
	stosw
	loop	@b

	mov	al, " "
	stosb

	;
	; device ID
	;
	mov	cx, 2
	
@@:
	rol	ebx, 8
	mov	al, bl
	call	hex2ascii
	xchg	ah, al
	stosw
	loop	@b


	mov	cx, 5
	mov	al, " "
	rep	stosb




	;
	; print it out.
	;

       ;	mov	ah, 9
       ;	lea	dx, line
       ;	int	21h


       	call	print2file



	pop     es
        pop     di
        pop     si
        pop     dx
        pop     cx
        pop     ebx
        pop     eax
        ret
printbusDevFn endp


; print out a list of pci registers to a file
; input: eax = pfa
; outpt: none.
regs2file proc

	
	push	ax
	push	dx
	push	di
	push	es

	push	ds
	pop	es

	mov	cx, 16		; 16 registers per row
	xor	al, al		; start with register 0
l1:
   	push	cx
	mov	cx, 16
	lea	di, line
@@:	
	push	ax
	call	pciRegRead8
	mov	al, dl
	call	hex2ascii
	xchg	ah, al
	stosw
	mov	al, " "
	stosb
	pop	ax
	inc	al
	loop	@b
	
       ;	push	ax
       ;	mov	ah, 9
       ;	lea	dx, line
       ;	int	21h
       ;	pop	ax

       	call	print2file


	pop	cx
	loop	l1

	
	lea	di, line
	mov	al, " "
	mov	cx, 47
	rep	stosb
	call	print2file
	



	pop	es
	pop	di
	pop	dx
	pop	ax
	ret
regs2file endp

; writes data to the file which better be open by the time we call it.
print2file proc
	push	ax
	push	bx
	push	dx
	push	cx
	mov	ah, 40h
	lea	dx, line
	mov	cx, 50
	mov	bx, cs:[filehandle]
	int	21h
	pop	cx
	pop	dx
	pop	bx
	pop	ax
	ret
print2file endp





.DATA
fname	db	"pciscan.txt",0

busMsg  db      "Bus:$"
DevMsg  db      " Dev:$"
FnMsg   db      " Fn:$"
PFAMsg  db      " PFA:$"  
line    db      "                                                ",CR,LF,"$"


End

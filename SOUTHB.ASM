; southbridge and other hardware routines.
;
;
        .DOSSEG
        .MODEL  small, c, os_dos

.486
.CODE

        INCLUDE constant.inc
        INCLUDE equates.inc
        INCLUDE macros.inc

        extern  pciRegRead16:NEAR
	extern	pciRegRead8:NEAR
	extern	pciRegWrite8:NEAR
	extern	pciRegWrite16:NEAR
	extern  locatePCIDevice:NEAR
        extern  flags:BYTE
        extern  printreg:NEAR
	extern	getACPIBaseReg:NEAR
	extern	getACPITHTReg:NEAR
	extern	getACPIEnableReg:NEAR


; sbSearch - locate a compatible southbridge.
; CY set if not found
; CY clear if located.
; input: SI->sbdata
; outpt: SI->last discovered device
;
sbSearch proc public
	push	eax
;	push	si

        test    cs:[flags], DEBUG_MODE
        jz      @f

        WriteLN 'Search for a compatible chipset...'
@@:



tryNext:
	add	si, SIZEOF sbStruc
	cmp	word ptr [si], -1
	stc					; assume error
	jz	exit



	test    cs:[flags], DEBUG_MODE
        jz      @f
	writelnCR ' '

        lea	dx, ds:[si].sbStruc.userText
	mov	ah, 9
	int	21h
	mov	eax, dword ptr ds:[si].sbStruc.vendorID
	mov	cx, 4
	call	printReg
	ror	eax, 16
	WriteLN ' '
	call	printReg

@@:	

	mov	eax, dword ptr [si].sbStruc.vendorID
	call	locatePCIDevice
	jc	tryNext

	debug_msg '..found!'

	;
	; found a device!
	;
	mov	[pciDevice], eax  		; save PFA
	mov	eax, dword ptr [si].sbStruc.vendorID
	mov	[pciDeviceID], eax		; save dev/ven ID
	clc
exit:
;	pop	si
	pop	eax
        ret
sbSearch endp


; return the base address stored in the PMIO register
; input: si-> device entry
; outpt: DX = base address
;
getPMIOBase proc public
	push    eax
	mov	eax, [pciDevice]
	call	getACPIBaseReg
	call	pciRegRead16

;mov dx, 4000h
	
	and     dx, IO_ADDR_MASK                ; mask off bits
        pop     eax
        ret
getPMIOBase endp


cacheOff proc public
; L1 cache off routine
; lockups are very common here, so do some voodoo steps to make sure cache
; is off and all buffers are flushed.
;
.486

	test	cs:[flags], NOL1	; -c command line override?
	jnz	override

        debug_msg 'Disable the L1 Cache...'

	push	ax
        cli
        in      al, 61h                 ; flush write buffers by doing
        in      al, 61h                 ; an i/o read.
        wbinvd                          ; flush the cache
	invd
	mov	eax, CR0		; Make sure cache is disabled
	or	eax, 060000000H 	; Disable cache
	mov	cr0, eax		; Write back to CR0
        wbinvd
	invd                            ; flush da cache
        sti
	pop	ax
        debug_msg 'done.'
exit:
	ret

override:
	debug_msg 'User requested no L1 changes.'
	jmp	exit
cacheOff endp

cacheOn proc public
; L1 cache on routine
; lockups are very common here, so do some voodoo steps to make sure cache
; is and buffers are flushed.
;
.486

	test	cs:[flags], NOL1	; -c command line override?
	jnz	exit

	debug_msg 'Enable the L1 Cache...'
	push	ax
        cli
        in      al, 61h                 ; flush write buffers by doing
        in      al, 61h                 ; an i/o read.
	wbinvd                          ; flush the cache
	invd
	mov	eax, CR0		; Make sure cache is disabled
        and     eax, NOT 060000000H     ; Enable cache
	mov	cr0, eax		; Write back to CR0
	wbinvd                          ; flush da cache
	invd
        sti
	pop	ax

	debug_msg 'done.'
exit:
	ret
cacheOn endp




;---------------------------------------------------------------------------
; setNewIOBase - find and program the ACPI I/O base address
; input: none
; outpt: CY clear, new I/O base address programmed 
;	 CY set, failed to allocate memory space
setNewIOBase proc public
	push	eax
	push	dx

        debug_msg 'Need to program our own ACPI base address.'
	call	getNewIOBase
	jc	failed

        test    cs:[flags], DEBUG_MODE
        jz      @f
	WriteLNCR ' '
        WriteLN 'Found available space, program it into chipset...'
@@:

        mov     eax, [pciDevice]
	cli
	call	disableIO			; hit control reg 4
	
	call	getACPIBaseReg			; locate the PCI register
						; that holds the base address
						; for ACPI
	call	pciRegWrite16			; write new base address
	
	call	enableIO			; rehit reg 4
	sti

        debug_msg 'done.'
	
	clc
	jmp	exit


failed:
	
        debug_msg 'Failed to allocate free I/O space for ACPI!  Game over.'
	stc

exit:
	pop	dx
	pop	eax
	ret	

setNewIOBase endp



;--------------------------------------------------------------------------
; disableIO - turn off I/O enable bit in control reg 4 of this device
; input: eax - PFA for device
; outpt: none
;
disableIO proc
	push	ax
	push	dx
	mov	al, PCI_CMD_REG
	call	pciRegRead8
	and	dl, NOT IO_ENA
	call	pciRegWrite8
	pop	dx
	pop	ax
	ret
disableIO endp
;--------------------------------------------------------------------------
; enableIO - turn on I/O enable bit in control reg 4 of this device
; input: eax - PFA for device
; outpt: none
;
enableIO proc
	push	ax
	push	dx
	mov	al, PCI_CMD_REG
	call	pciRegRead8
	or	dl, IO_ENA
	call	pciRegWrite8
	pop	dx
	pop	ax
	ret
enableIO endp



;---------------------------------------------------------------------------
; getNewIOBase - locate a 256 byte chunk of unused I/O space to locate ACPI
; input: none
; outpt: CY clear, DX = new base address
;	 CY set, DX =undefined.  No address available.
;
getNewIOBase proc
        debug_msg 'Search for open I/O space.'

	mov	dx, START_IOBASE
	sub	dx, ACPI_SIZE
look:
	add	dx, ACPI_SIZE			; next chunk
	cmp	dx, END_IOBASE			; have we maxed out?
	stc
	jz	exit


        test    cs:[flags], DEBUG_MODE
        jz      @f
        WriteLNCR ' '
	WriteLN 'Examining 256 bytes at:'
        mov     ax, dx
        mov     cx, 4
        call    printreg
        WriteLN 'h...'
@@:
	call	checkIO				; see if this I/O is unused
        jc      look
exit:
	ret
getNewIOBase endp

;---------------------------------------------------------------------------
; checkIO - scan 256 bytes of I/O, hoping to find nothing but FF's
; input: dx - base address to start scan
; outpt: CY set if I/O is used.
;
checkIO proc
        push    ax
        push    cx
	push 	dx
        mov     cx, 256 / 2
@@:
        in      ax, dx
        cmp     ax, -1
        stc
        jnz     exit
	add	dx, 2
	loop    @b
        clc
exit:
	pop	dx
        pop     cx
        pop     ax
        ret
checkIO endp



;---------------------------------------------------------------------------
; testIOSpace - read the throttle register to make sure the IO space is ok.
; input: none
; outpt: CY set if IO space closed and we're unable to get it going.
;	 CY clear if we're a-ok.
;        uses [ioBase] variable
testIOSpace proc public

	cmp	cs:[testflag], 2   
	stc
	jz	exit

        call    getPMIOBase			; get base address from PCI
;mov	dx, 4000h
	mov	ds:[ioBase], dx			; save it

        cmp     dx, 0
        jnz     baseOK

        debug_msg 'ACPI I/O space is 0.  Probably disabled,'
 
	call    setNewIOBase
	jc	exit
	inc	byte ptr cs:[testFlag]
	jmp	testIOSpace			; retry


testFlag	db	0			; flag to avoid endless loop

baseOK:

        test    cs:[flags], DEBUG_MODE
        jz      @f
	push	ax
	push	cx
	WriteLN 'Got a valid base address:'
        mov     ax, ds:[ioBase]
        mov     cx, 4
        call    printreg
        WriteLNCR 'h'
	pop	cx
	pop	ax
@@:

	;
	; got a valid base address, lets make sure it's working.
	;
	mov	dx, ds:[ioBase]	
	call	getACPITHTReg			; get register and data
	xor	ah, ah				; for throttle
	add	dx, ax				; throw away data
        in      al, dx
        cmp     al, -1                          ; IOSpace enabled?
	clc
	jnz     exit


        debug_msg 'ACPI I/O space is disabled, try to enable it.'

	call   	enableIoSpace			; turn on ACPI space

	test	cs:[flags], IOTESTED
	stc
	jnz	exit
	or	cs:[flags], IOTESTED		; flag
	jmp	testIOSpace
	        
exit:
	mov	cs:[testflag], 0		; restore for next time

	ret
testIOSpace endp

;---------------------------------------------------------------------------
; enableIOSpace - turn on the ACPI base address via whatever register this
;                 chipset uses to turn it on.  
; input: none
; outpt: none ACPI IO space enable, hopefully.
enableIOSpace proc public
	push	eax
	push	dx
	mov	eax, ds:[pciDevice]
	push	ax
	call	getACPIEnableReg		; get register and data
	mov	dx, ax				; al=reg, ah=data
	pop	ax				; 
	mov	al, dl				; 
	call	pciRegRead8			; read current value
	or	dl, dh				; or in enable bits
	call	pciRegWrite8			; write new value
	call	enableIO			; hit cmd reg4 too.
	pop	dx
	pop	eax
	ret
enableIOSpace endp


;------------------------------------------------------------------------
; setThrottle - write the new throttle data into the throttle register
; input: al - data to write 0-F
; outpt: none
;
; note: this routine is still a tad fishy.  it assumes enable bit is in the
; same 8 bit register as the throttle itself. (ACPI spec says it is BIT 4)
;
setThrottle proc public

	test	cs:[flags], DEBUG_MODE
	jz	@f

	push	cx
	mov	cl, 2
	call	printReg
	pop	cx
	writelncr ' '

@@:


	push	ax
	push	bx
	push	dx

	mov	bx, ax				; save input
	mov	dx, [ioBase]
	call	getACPITHTReg			; get register and data
	push	ax
	xor	ah, ah				; for throttle
	add	dx, ax				; throw away data
	pop	ax

	in      al, dx				; read current value
        and	al, NOT THROTTLE_MASK		; clear 3:0
	not	ah				;
	and	al, ah				; 
	not	ah				;
	out	dx, al				; disable all throttle
	cmp	bl, 0				; user wants none?  quit
	jz	exit
	
	or	al, bl				; new throttle
	or	al, ah				; new enable
	out	dx, al
exit:
	pop	dx
	pop	bx
	pop	ax
	ret
setThrottle endp





.DATA
SBflags         db      0
public pciDevice, pciDeviceID, ioBase

pciDevice       dd      0deafbabeh  		; PFA
pciDeviceID	dd	0cafef00dh		; vendor/device ID
ioBase		dw	0

End





; misc stuff.

       	.DOSSEG
        .MODEL  small, c, os_dos

.386


        .CODE

	INCLUDE constant.inc
        INCLUDE macros.inc
        INCLUDE equates.inc


; inProtMode?
; input: none
; output: CY set if some sort of protected mode discovered. (windows, emm386)
;       if windows NT/2K/XP detected, the giveio.sys driver is opened.
;
inProtMode? proc public
;	call	underWindows?	; if we're in windows we KNOW were not real.
;	jc	exit
	push	ax
	smsw	ax		; peek at CR0 and see if we're in prot mode
	clc
	test	al, BIT0 	; if bit0 is 1, we're in protected mode
	jz	exit	
	stc		
exit:
	pop	ax
	ret
inProtMode? endp





; underWindows? - detect if we're running in a DOS box.
; input: none
; outpt: CY set if running under NT or windows 9x/ME
;
underWindows?   proc public
        call    NTDetect
        jc      @f

	push    ax
	push	bx
	push	cx
	mov     ax, 160ah
        int     2fh
        cmp     ax, 160ah               ; returns 0 if supported.
	pop	cx
	pop	bx
	pop	ax
	clc
	jz      @f
        stc
@@:
        ret
underWindows?   endp




; attempts to open the driver "giveio.sys" if we're running under NT
; giveio.sys opens up access to all I/O ports so we can scan PCI devices
; and manipulate the ACPI registers we need to tweak.
; exits with CY set if NT based O/S detected.
NTDetect proc public
	push	ax
	push	bx
	push	dx
	mov	ax, 3306h
	int	21h
	cmp	bx, 3205h		; NT signature, XP too.
        clc
	jnz	@f
        call    openNTDriver
        stc
@@:
	pop	dx
	pop	bx
	pop	ax
	ret
NTDetect endp


; if we're running under NT, attempt to open the generic I/O driver.
; it will always fail, but IO access is enabled.
openNTDriver proc
        push    ds
        push    cs
        pop     ds
	lea	dx, driverFname
	mov	ax, 3d01h
	int	21h
        pop     ds
        ret
	

driverFname	db	"\\.\giveio",0
openNTDriver endp



;===========================================================================
;Procedure: PrintReg
;Purpose:   Displays the contents of a register. 
;           Displays data at current cursor location 
;Input:     EAX  Register to print
;           CL   Length of output (8 for full EAX, 4 for AX, 2 for AL...)
;           
;Output:    Data written to screen using Stdout 
;Processing: Move nibble into output register, display it, loop til finished 
;---------------------------------------------------------------------------
printreg proc public

	push    cx
        push    dx
        
	push    cx
        xor     ch, ch
        mov     dx, 8
        sub     dx, cx
        mov     cx, dx
        shl     cx, 2                   ; multply by 4 for shift#
        rol     eax, cl
        pop     cx


nextchar:
	rol     eax,4                      ;print next character
	mov     dl,al                      ;
	and     dl,0fh                     ;strip out upper 4 bits
        call    display_hex_char
	loop    nextchar
	pop	dx	
	pop     cx
	ret
printreg endp
;===========================================================================
;Procedure: Display_hex_char
;Purpose:   Displays the hex value in DL as ASCII
;           Displays data at current cursor location 
;Input:     DL = hex value to print
;           
;Output:    Data printed to screen using Stdout 
;Processing: add 30 or 37 to character, display to screen using int 10
;---------------------------------------------------------------------------
display_hex_char proc        
        push    dx
        add     dl,30h
        cmp     dl,3ah
        jb      charok
        add     dl,7
charok:
        push    ax
        push    bx
        push    cx
        mov     ah,2
        int     21h
        pop     cx
        pop     bx
        pop     ax
        pop     dx
        ret
display_hex_char endp
;===========================================================================
;Procedure: getakey
;Purpose:   Reads a keypress from the keyboard.
;           
;Input:     None
;           
;Output:    Carry flag set if key pressed.  
;           AL=key value in ascii.  
;           BIT 7 of AL is set if ctrl key is pressed. (for hotkeys)
;---------------------------------------------------------------------------
getakey	proc public

	mov	ah, 11h			; check for keystroke
	int	16h
	clc
	jz	@f

      	mov	ah, 10h			; get keystroke
      	int	16h
	
	cmp	al, 0E0h		; extended key?
	stc
	jz	extnded

	cmp	al, 0
	stc
	jnz	@f

extnded:
	xchg	al, ah			; if so, extended key is in AH
	or	al, BIT7
	stc
@@:
	ret
getakey	endp

;===========================================================================
;Procedure: ASCII2hex
;Purpose:   returns the value in hex of the ASCII word in AX
;           
;Input:     AX=ASCII hex number 
;           
;Output:    AL=hex value  AH is destroyed
;           
;Processing: convert AH and AL to hex,shift AH into AL, exit 
;---------------------------------------------------------------------------
ASCII2hex proc public
	sub     ax,3030h
	cmp     ah,0fh
	jb      ok
	sub     ah,7
ok:        
	cmp     al,0fh
	jb      ok2
	sub     al,7
ok2:
	shl     ah,4
	add     al,ah
	ret
ASCII2hex endp
;===========================================================================
;Procedure: ucase
;Purpose:   Converts character in AL to uppercase.
;           
;Input:     AL=character
;           
;Output:    AL=uppercase character (if a-z)
;           All other registers preserved.  (flags too)
;
;Processing: test valid range (a-z), set to upper, exit
;---------------------------------------------------------------------------
ucase   proc  public
	pushf
	cmp al,"a"                  ;if  it's not a-z, skipit
	jb noupper
	cmp al,"z"
	ja noupper
	and al,5fh                  ;strip off a few bits to make it upper
noupper:        
	popf
	ret
ucase   endp

; input: AL - ascii value, inputed from keyboard
; output: CY set if value is not 0-9, A-F 
isHex? proc public
	push	ax
	call	ucase
	
	test	al, BIT6			; A-Z?
	jnz	checkChar
	
	cmp	al, "0"
	jb	notHex
	cmp	al, "9"
	ja	notHex
	jmp	ishex

checkChar:
	cmp	al, "A"
	jb	nothex
	cmp	al, "F"
	ja	nothex
isHex:	
	clc
	jmp	@f
nothex:
	stc
@@:
	pop	ax
	ret
isHex? endp

; input: AL - ascii value
; output: CY set if value is not 0-9
isDec?  proc public
	cmp	al, "0"
        jb      notDec
	cmp	al, "9"
        ja      notDec
        clc
        jmp     exit
notDec:
        stc
exit:
        ret
isDec?  endp


;===========================================================================
;Procedure: Hex2ASCII
;Purpose:   returns the ASCII value of a hex byte in AL
;           
;Input:     AL=hex value
;           
;Output:    AX=ASCII value
;Example:   AL=3Eh = AX=3345              
;
;Processing: Separate AL nibble into AH, add 30 or 37 to each
;---------------------------------------------------------------------------
hex2ascii proc public
	xor	ah, ah
	shl	ax, 4				; seperate digits
	shr	al, 4		
	call	convert
convert:
	xchg	ah, al			       	; swap digits
	cmp	al, 10				; set CF if < 10
	sbb	al, 69h				; subtract with borrow
	das					; decimal adjust
	ret
hex2ascii	endp
open_file proc near
;open existing file
;
;input: ds:dx-->filename (asciiz)
;       al=file Mode (create or open)
;output: none

	push	ax
	push	cx

	mov	ah, 3bh			; start with a mode
	add	ah, al			; add in create or open mode
	xor	cx, cx

	int	21h
	jc	@f
	mov	cs:[filehandle], ax
@@:
	pop	cx
	pop	ax
	ret
public filehandle
filehandle	dw	0

open_file endp


close_file proc near
	push	ax
	push	bx

	cmp	cs:[filehandle], -1
	jz	@f
	mov     bx, cs:[filehandle]  
	mov     ax,3e00h
        int     21h              ;close file
@@:
	
	pop	bx
	pop	ax
	ret
close_file endp



.DATA

End



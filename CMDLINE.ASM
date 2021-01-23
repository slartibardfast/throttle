; command line parser
;

       	.DOSSEG
        .MODEL  small, c, os_dos

.386


        .CODE

	INCLUDE constant.inc
        INCLUDE macros.inc
        INCLUDE equates.inc

        extern  flags:BYTE
        extern  throttleVal:BYTE
	extern	ucase:NEAR
        extern  isHex?:NEAR

        
; scan through the command line looking for flags.
; set flag bits accordingly.
; input: none
; output: cs:[flags] modified
;
processCmdline proc public
        push    es
        push    ds
        push    bx
        push    si

        push    ds
        pop     es

        mov     ah, 51h                         ; get PSP
        int     21h
        mov     ds, bx

        mov     si, 80h
        movzx   bx, byte ptr[si]
        add     si, bx
        inc     si

        mov     byte ptr[si], NULL              ; zero terminate

        mov     si, 81h

cmdlineloop:

        lodsb

        cmp     al, " "                 ; found a space?
        jz      cmdlineloop
        cmp     al, NULL                ; found end of line?
        jz      exitpc
        cmp     al, "-"                 ; found a flag?
        jz      checkflags
        cmp     al, "/"                 ; found a flag?
        jz      checkflags
        
	
	call    isHex?                  ; is it a number?
        jc      @f

	mov     cs:[throttleVal], al	; save it.  No menu displayed
	
@@:
	jmp	cmdlineloop

exitpc:
        pop     si
        pop     bx
        pop     ds
        pop     es        
        ret

checkflags:			 	
        lodsb
        cmp     al, " "                 ; false flag
        jz      cmdlineloop
        cmp     al, NULL                ; found end of line?
        jz      exitpc
        cmp     al, "-"                 ; found a double flag?
        jz      checkflags
        cmp     al, "/"                 ; found a double flag?
        jz      checkflags

        ; must be a flag 

	call	ucase

	cmp	al, "?"
	jz	sethelp

	cmp	al, "H"
	jz	sethelp
	
	cmp	al, "D"
        jz      setDebug
	
	cmp	al, "C"
	jz	setNocache

	cmp	al, "P"
	jz	setPciScan
	
	jmp     cmdlineloop             ; nothing we care about, continue
                                        ; could jump to help msg
sethelp:
        or      cs:[flags], NEED_HELP
        jmp     checkflags              ; allows flags to be stacked

setdebug:
        or      cs:[flags], DEBUG_MODE
        WriteLNCR 'Debug mode enabled.'
	jmp	checkflags

setNocache:
	or	cs:[flags], NOL1	; don't futz with the L1 cache
	jmp	checkflags

setpciScan:
	or	cs:[flags], PCI_SCAN	; dump PCI listing
	jmp	checkflags
processCmdline endp

.DATA

End



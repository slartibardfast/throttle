;
; writeln
;
; input:
;   textstring
;
; output:
;   none (text displayed on screen) No carrage return at end.
;
; destroys:
;   ax, dx
;   flags
;
; usage: WriteLN 'Hello, world!'
;


WRITELN MACRO   _string
LOCAL   _afterstring
	push	ax
	push	dx
	push	ds
	push	cs
	pop	ds

        call    _afterstring

db      _string,'$'
_afterstring:
        mov     ah,9
	pop	dx
	int	21h
	pop	ds
	pop	dx
	pop	ax

        ENDM
;
; writelnCR
;
; input:
;   textstring
;
; output:
;   none (text displayed on screen) with a carrage return at end.
;
; destroys:
;   ax, dx
;   flags
;
; usage: WriteLNCR 'Hello, world!'
;


WRITELNCR MACRO   _string
LOCAL   _afterstring
	push	ax
	push	dx
	push	ds
	push	cs
	pop	ds
        call    _afterstring

db	_string,13,10,'$'
_afterstring:
        mov     ah,9
	pop	dx
	int	21h
	pop	ds
	pop	dx
	pop	ax
        ENDM


debug_msg MACRO _string
	push	ax
	test	cs:[flags], DEBUG_MODE
	jz	@f
	WriteLNCR _string
@@:
	pop	ax

ENDM


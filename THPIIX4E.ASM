; throttle - southbridge based hardware slowdown.
;	     uses ACPI registers to enable software throttling.
; 
; jeff@silent.net
;
; you are free to use/modify/abuse this code however you see fit.
; 
;
; compiled with MASM 6.11
;


       	.DOSSEG
        .MODEL  small, c, os_dos

.386


        .CODE

        INCLUDE constant.inc
        INCLUDE macros.inc
        INCLUDE equates.inc


        extern  processCmdline:NEAR
        extern  inProtMode?:NEAR
        extern  sbSearch:NEAR
        extern  getPMIOBase:NEAR
	extern	cacheOff:NEAR
        extern  cacheOn:NEAR
        extern  NTDetect:NEAR
	extern	testIOSpace:NEAR
	extern	ioBase:WORD
	extern	setThrottle:NEAR
	extern	getakey:NEAR
	extern	ASCII2hex:NEAR
	extern	getFlagsData:NEAR
	extern	setThrottle:NEAR
	extern	isHex?:NEAR
	extern	pciScan:NEAR
	extern	sbridgeData:BYTE


        .STARTUP

	push	ds
	pop	es


	call    processCmdline                  ; set flags
        test    cs:[flags], NEED_HELP
        jnz     help

        call    NTDetect                        ; see if we're in a CMD shell

        test    cs:[flags], PCI_SCAN
        jnz     doPciScan


	lea	si, ds:sbridgeData
	sub	si, SIZEOF sbStruc
	

retry:
        call    sbSearch                        ; locate a compatible SB.
        jc      notCompatible
	
	call	getFlagsData
	test	al, NOACPI
	jnz	knownBad

	push	si
        call    testIOSpace                     ; see if ACPI is enabled
	pop	si
	jc      retry ;ACPIfailure



	nop
	nop
        debug_msg 'Check command line throttle value.'


        cmp     byte ptr cs:[throttleVal], -1
        jz      doMenu

        mov     al, cs:[throttleVal]
        jmp     doKey



doMenu:
	call    displayMenu			; print 12.5 or 6.25% menu
wait4key:
	call    getakey
        jnc     wait4key

	cmp     al, ESCAPE                      ; esc pressed?
        jz      exit

        ;
        ; examine keys
        ;

doKey:        
       	call	isHex?				; allow only 0-F
       	jc	doMenu

	mov	ah, "0"
	call	ASCII2hex			; convert input to hex	
        and     al, 0fh

	mov	cl, al				; save AL (user input)

	call	getFlagsData			; get flags based on detected
	lea	bx, ds:[throttles6]		; chipset
	test	al, THT6@25
	jnz	@f
	
	;
	; acceptable values for input are 0-7 only.
	; mask off invalid bits.
	and	cl, 7	
	lea	bx, ds:[throttles12] 		; point to 

;why?	call	getFlagsData
;	test	al, THT12@5
;	jnz	@f
	
@@:
	mov	al, cl				; restore AL
	xor	ah, ah
	add	bx, ax
       	mov     al, ds:[bx]			; get proper throttle amount

	debug_msg 'See if this is running in a DOS box under windows.'

        call    inProtMode?                   	; check if running in real mode
        jc      windows

	debug_msg 'Not running under windows. Can turn off L1 cache unless user overrides.'

        call    cacheOff                        ; turn off L1 cache if we can
        debug_msg 'Cache Disabled.'
        jmp     ahead
windows:
        debug_msg 'Unable to disable L1 cache due to CPU in protected mode.'

ahead:

	debug_msg 'Write throttle register with value:'

	call	setThrottle

        cmp     al, 0
        jnz     @f				; re-enable L1 if no throttle
        call    inProtMode?                     ; but not in protected mode
	jc	@f
	call    cacheOn		

@@:
	debug_msg 'Done, wrap it up, exit back to DOS.  Throttle changed.'
	jmp	exit
	        

notCompatible:
        WriteLNCR ' '
        WriteLNCR 'Sorry, unable to find a compatible chipset.'
 	WriteLNCR ' '
	WriteLNCR 'Do this:'
	WriteLNCR 'Type   throttle -p'
	WriteLNCR 'Send the file PCISCAN.TXT to jeff@silent.net'
	WriteLNCR 'It is possible that this is a new chipset that has not been implemented yet.'
	jmp     exit

knownBad:
	WriteLNCR ' '
	WriteLNCR 'Sorry, this is a known incompatible chipset.'
	WriteLNCR 'More than likely, this machine is slightly too old'
	WriteLNCR 'to have ACPI support.  There is nothing that can be done.'
	jmp	exit



help:
	lea	dx, helpMsg
	mov	ah, 9
	int	21h
	jmp	exit

ACPIFailure:
        WriteLNCR ' '
        WriteLNCR 'Unable to enable ACPI for clock throttling!'
        WriteLNCR 'Run throttle -d to enter debug mode.'
        WriteLNCR 'Send output to jeff@silent.net for a new version.'
	jmp     notCompatible


doPciScan:
	call	pciScan
	jmp	exit

exit:
        mov     ax, 4c00h
	int 	21h






displayMenu proc
        push	ax
	push	dx
	lea     dx, throttles12Msg
	call	getFlagsData

        test    al, UNTESTED
        jz      @f
        writeLNCR ' '
        writeLNCR 'Note!  The chipset found in your computer is listed as UNTESTED.'
        writeLNCR 'It would be very nice of you to send an email to jeff@silent.net'
        writeLNCR 'To let him know the results of running this program.'
        writeLNCR ' '
        

@@:
	test	al, THT12@5
	jnz	@f
	lea	dx, throttles6Msg
	test	al, THT6@25
	jnz	@f
@@:
	mov     ah, 9
        int     21h
	pop	dx
	pop	ax
	ret
displayMenu endp

public flags, throttleVal

flags           db      0
throttleVal     db      -1               ; value inputted from cmdline




.DATA


throttles12Msg  db	CR,LF,CR,LF
		db      "Speed options:",CR,LF,CR,LF
                db      "0. top speed              (No throttle)",CR,LF
                db      "1. not really slow at all (12.5% throttled)",CR,LF
                db      "2. sorta kinda slow       (25% throttled)",CR,LF
                db      "3. gettin' there          (37.5% throttled)",CR,LF
                db      "4. half slow              (50% throttled)",CR,LF
                db      "5. pretty slow            (62.5% throttled)",CR,LF
                db      "6. considerably slow      (75% throttled)",CR,LF
                db      "7. whoa! Is it 1983?      (87.5% throttled)",CR,LF,CR,LF
                db      "ESC. get me outta here. No changes.",CR,LF,"$"
;
;12.5% throttle tables  
;
throttles12     db      0, THROTTLE_875, THROTTLE_75, THROTTLE_6250, \
                        THROTTLE_50, THROTTLE_375, THROTTLE_25,THROTTLE_125

;
;6.25% throttle tables.  Commonly used by VIA chipsets.
;

throttles6Msg   db	CR,LF,CR,LF
		db      "Speed options:",CR,LF,CR,LF
                db      "0. top speed                       (No throttle)",CR,LF
                db      "1. barely a dent                   (6.25% throttled)",CR,LF
                db      "2. not really slow at all          (12.5% throttled)",CR,LF
                db      "3. ha! I laugh at this speed.      (18.75% throttled)",CR,LF
                db      "4. you call this slow?             (25% throttled)",CR,LF
                db      "5. bring it on. I can take it.     (31.25% throttled)",CR,LF
                db      "6. meh. this is for sissies.       (37.5% throttled)",CR,LF
                db      "7. now we're getting somewhere.    (43.75% throttled)",CR,LF
                db      "8. Half speed Cap'n!               (50% throttled)",CR,LF
                db      "9. Gimme a 486.                    (56.25% throttled)",CR,LF
                db      "A. I can wait all day.             (62.5% throttled)",CR,LF
                db      "B. ok, make that a 386.            (68.75% throttled)",CR,LF
                db      "C. quarter impulse power.          (75% throttled)",CR,LF
                db      "D. whoa! is it 1983?               (81.25% throttled)",CR,LF
                db      "E. where'd my pentium go?          (87.5% throttled)",CR,LF
                db      "F. hello? is this thing on?        (93.75% throttled)",CR,LF,CR,LF
                db      "ESC. get me outta here. No Changes.",CR,LF,"$"

throttles6      db	0, THROTTLE_9375, THROTTLE_875, THROTTLE_8125, \
			THROTTLE_75, THROTTLE_6875, THROTTLE_6250, \
			THROTTLE_5625, THROTTLE_50, THROTTLE_4375, \
			THROTTLE_375, THROTTLE_3125, THROTTLE_25, \
			THROTTLE_1875, THROTTLE_125, THROTTLE_625



helpMsg         db      "thPIIX4E 23-Jan-2021 based on",CR,LF
				db      "Throttle build 27 03-Nov-16 jeff leyda  jeff@silent.net",CR,LF
                db      "Homepage: http://www.oldskool.org/pc/throttle",CR,LF
             ;   db      "Part of the flopper project: http://www.oldskool.org/pc/flopper",CR,LF
		db	CR,LF
		db	"This program uses features in certain chipsets to provide a means of CPU",CR,LF
		db	"clock throttling to emulate 486, 386 or slower clock speeds.",CR,LF
		db	"This is useful for programs (games) that run too fast on modern processors.",CR,LF
		db	CR,LF
                db      "Usage: thottle <value> <switches>",CR,LF
                db      "       throttle      = cache off, display menu for throttle options",CR,LF
                db      "       throttle 3    = set throttle value 3 without the menu",CR,LF
                db      "       throttle 0    = disable throttling without the menu",CR,LF
                db      "       throttle -c   = do not disable L1 cache (slowdown is not as effective)",CR,LF
		db	"       throttle -p   = create a list of all PCI devices (pciscan.txt)",CR,LF
                db      "       throttle -d   = debug mode",CR,LF
                db      "       throttle -h   = this screen",CR,LF
                db      "       throttle -d 5 = debug mode, force throttle value 5 without menu",CR,LF
		db	CR,LF
		db	"Provided this machine uses a compatible chipset, you will be prompted with a",CR,LF
		db	"menu for selecting the amount of slowdown desired.",CR,LF
		db	CR,LF
		db	"This program is not a TSR, nor does it use any system memory.",CR,LF
		db	"Throttle will work under windows 9x, but L1 cache will remain enabled.",CR,LF
		db	"Best results are in safe mode DOS only.",CR,LF
		db	"$"

END

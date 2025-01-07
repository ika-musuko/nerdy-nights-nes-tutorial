; vim: set noexpandtab tabstop=8 shiftwidth=8:
; information the emulator needs about the game:
	.inesmap 0 		; mapper 0 = NROM, no bank swapping
	.inesmir 1		; background mirroring (ignore for now)
	.inesprg 1		; include 1x 16kb bank of prg code
	.ineschr 1 		; include 1x 8kb bank of chr data

; here we tell the assembler where to put the code in memory
	.bank	0
	.org	$8000		; cartridge start

; TODO: understand the following
;	- why txs sets up the stack
;	- why x is now zero when we increment it

RESET:
	sei			; disable irq (see $fffe)
	cld			; disable decimal mode

	ldx	#$40
	stx	$4017		; disable APU frame irq

	txs			; set up stack
	inx			; now x = 0

	stx	$2000		; disable NMI
	stx	$2001		; disable rendering
	stx	$4010		; disable dmc irq


; wait for vblank to happen to make sure ppu is ready
vblankwait1:
				; $2002 is the PPU status register
				;
				; according to p.25 of NESDoc.pdf
				; during vblank, bit 7 of $2002 is set.
				;
				; we have to wait for the nes to refresh
				; the screen, during which $2002 bit 7 is
				; NOT set. when the screen is ready, "vblank"
				; (vertical blank) has happened, and $2002
				; bit 7 is set.
				;
				;
	bit	$2002		; "bit" operation
				; - N = bit7
				; - V = bit6
				; - Z = A & memory
				;
				; the value of the accumulator is irrelevant here
				; because we only care about whether the N flag is
				; set for bpl
				;
				;
	bpl	vblankwait1	; bpl branches if the N flag is NOT set,
				; iow, vblank has NOT happened yet and
				; the ppu is NOT ready
				;

; TODO: understand the following
;	- why we are doing ", x"
;	- what locations $0000~$0700 are
;	- why only $0300 gets value #$fe
;	- why we are incrementing x
;	- why we are branching back to clrmem when x is not zero
clrmem:
	lda	#$00
	sta	$0000, x
	sta	$0100, x
	sta	$0100, x
	sta	$0200, x
	sta	$0400, x
	sta	$0500, x
	sta	$0600, x
	sta	$0700, x
	lda	#$fe
	sta	$0300, x
	inx
	bne	clrmem

vblankwait2:			; wait for vblank again, PPU is ready after this
	bit	$2002
	bpl	vblankwait2

_start:
	lda	#%1000_0000	; intensify blues on screen
	sta	$2001

forever:
	jmp	forever


NMI:
	rti


;; interrupts ;;
	.bank	1
	.org	$fffa	; interrupt vector
			; the layout is
			; $fffa nmi_handler
			; $fffc reset_handler
			; $fffe irq_handler

	.dw	NMI	; jump to NMI label on nmi interrupt
			; if enabled, nmi happens once per frame
			; nmi is enabled by default

	.dw	RESET	; jump to RESET label on reset interrupt
			; this is what happens when the system starts up

	.dw	0	; irq_handler unused here



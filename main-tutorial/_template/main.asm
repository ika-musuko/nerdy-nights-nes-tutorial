; vim: set noexpandtab tabstop=8 shiftwidth=8:

;; config ;;
	.inesmap 0		; mapper 0 = NROM, no bank swapping
	.inesmir 1		; background mirroring
	.inesprg 1		; 16kb prg code
	.ineschr 1		; 8kb chr data

;; code ;;
	.bank	0
	.org	$8000

RESET:
	sei
	cld

	; disable APU frame irq
	ldx	#$40
	stx	$4017

	; set up stack
	ldx	#$ff
	txs

	stx	$2000		; disable NMI
	stx	$2001		; disable rendering
	stx	$4010		; disable dmc irq

vblankwait1:
	bit	$2002
	bpl	vblankwait1

	ldx	#0
clearram:
	lda	#0

	sta	$0000, x
	sta	$0100, x
	sta	$0200, x
	sta	$0300, x
	sta	$0400, x
	sta	$0500, x
	sta	$0600, x
	sta	$0700, x

	inx
	bne	clearram

vblankwait2:
	bit	$2002
	bpl	vblankwait2

_start:


forever:
	jmp	forever



NMI:
	rti


;; interrupts ;;
	.bank	1
	.org	$fffa
	.dw	NMI
	.dw	RESET
	.dw	0		; irq unused




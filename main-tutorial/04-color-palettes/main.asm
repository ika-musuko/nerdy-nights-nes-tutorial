; vim: set noexpandtab tabstop=8 shiftwidth=8:

;; config ;;
	.inesmap 0		; mapper 0 = NROM, no bank swapping
	.inesmir 1		; background mirroring
	.inesprg 1		; 16kb prg code
	.ineschr 1		; 8kb chr data

;; code ;;
	.bank	0
	.org	$c000
RESET:
	sei
	cld

	; disable APU frame irq
	ldx	#$40
	stx	$4017

	; set up stack
	ldx	#$ff
	txs

	inx			; now X = 0
	stx	$2000		; disable NMI
	stx	$2001		; disable rendering
	stx	$4010		; disable dmc irq


vblankwait1:
	bit	$2002
	bpl	vblankwait1


	ldx	#$00
clearram:
	lda	#$00

	sta	$0000, x
	sta	$0100, x
	sta	$0300, x
	sta	$0400, x
	sta	$0500, x
	sta	$0600, x
	sta	$0700, x

	; move all sprites off screen
	lda	#$fe
	sta	$0200, x

	inx
	bne	clearram

vblankwait2:
	bit	$2002
	bpl	vblankwait2

_start:
LoadPalettes:
	; first, set the color palette address
	; we store palettes at $3F00
	; $2006 is the PPU address, which is 16 bit, so requires 2 writes
	lda	$2002		; read PPU status to set the high/low latch to high
	lda	#$3f		; write high byte
	sta	$2006
	lda	#$00		; write low byte
	sta	$2006		; now the value is $3f10

	; now we can write to $2007 to set the palette colors
	ldx	#$00
LoadPalettesLoop:
	lda	PaletteData, x
	sta	$2007
	inx
	cpx	#$20
	bne	LoadPalettesLoop


forever:
	jmp	forever



NMI:
	rti


;;;;;;;;;;;;;;;;

	.bank	1
;; data ;;
	.org	$e000
PaletteData:
; possible color values: https://nerdy-nights.nes.science/scraper/images/4924FAF3-9FC9-CED2-8403873F9EA75342.png
; note: do not use color $0d
	; background
	.db	$0f,$31,$32,$33,$0f,$35,$36,$37,$0f,$39,$3a,$3b,$0f,$3d,$3e,$0f
	; sprite
	.db	$0f,$1c,$15,$14,$0f,$02,$38,$3c,$0f,$1c,$15,$14,$0f,$02,$38,$3c

;; interrupts ;;
	.org	$fffa
	.dw	NMI
	.dw	RESET
	.dw	0		; irq unused




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

	; we will use $02xx for sprites
	; move all sprites off screen
	;
	; see comment below about the sprite data structure
	; regarding Y and X position for why setting this to $fe works
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
	; $2006 is the PPU address (PPUADDR), which is 16 bit, so requires 2 writes
	lda	$2002		; read PPU status to set the high/low latch to high
	lda	#$3f		; write high byte
	sta	$2006
	lda	#$00		; write low byte
	sta	$2006		; now the value is $3f10

	; now we can write to $2007 (PPUDATA) to set the palette colors
	ldx	#$00
LoadPalettesLoop:
	lda	PaletteData, x
	sta	$2007
	inx
	cpx	#$20
	bne	LoadPalettesLoop


SetupSprites:
	; sprite data structure:
	; - byte 0: Y position ($00~$ef, top->bottom. $f0~, off screen)
	; - byte 1: tile number, tile number to be taken from pattern table
	; - byte 2: attributes
	;     76543210
	;     |||   ||
  	;     |||   ++- Color Palette of sprite.
	;     |||       Choose which set of 4 from the 16 colors to use
  	;     |||
  	;     ||+------ Priority (0: in front of background; 1: behind background)
  	;     |+------- Flip sprite horizontally
  	;     +-------- Flip sprite vertically
	; - byte 3: X position ($00-$f9, left->right. $fa~, off screen)
	;
	; this data structure is repeated for each sprites so:
	;   - $0200~$0203: sprite 0
	;   - $0204~$0207: sprite 1
	;   - $0208~$020b: sprite 2
	;   etc

	; put sprite 0 in center ($80) of screen vertically
	lda	#$40
	sta	$0200
	; put sprite 0 in center ($80) of screen horizontally
	sta	$0203

	lda	#$00
	sta	$0201		; tile number = 0
	sta	$0202		; color palette = 0, no flipping

	lda	#%1_00000_00	; enable NMI, sprites from pattern table 0
	sta	$2000		; PPUCTRL

	lda	#%000_10_00_0	; black background, enable sprites
	sta	$2001		; PPUMASK


forever:
	jmp	forever



NMI:
;; load sprites using DMA (direct memory access)
; this needs to happen during NMI because it has to happen at the beginning
; of the vblank period
;
; NMI happens once per frame so this is going to get called every frame
;
	; load sprites into $0200
	lda	#$00
	sta	$2003		; set low byte of ram address ($2003 OAMADDR)
	lda	#$02
	sta	$4014		; set high byte of ram address ($4014 OAMDMA)
				; automatically start sprite DMA transfer

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


;;;;;;;;;;;;;;;;
	.bank	2
;; additional data files ;;
	.org	$0000
	.incbin	"mario.chr"

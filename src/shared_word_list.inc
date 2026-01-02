; ------------------------------------------------------------------------------
; Copyright (c) 2025 Devon Artmeier
;
; Permission to use, copy, modify, and/or distribute this software
; for any purpose with or without fee is hereby granted.
;
; THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL
; WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIE
; WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE
; AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL
; DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR
; PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER 
; TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
; PERFORMANCE OF THIS SOFTWARE.
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; Parent header structure
; ------------------------------------------------------------------------------

shlist.head		equ 0					; List head
shlist.freed		equ 2					; Freed nodes tail
shlist.node_size	equ 4					; Size of node
shlist.cursor		equ 6					; List cursor
shlist.start		equ 8					; Start of list
shlist.end		equ $A					; End of list
shlist.child		equ $C					; Number of child lists
shlist.struct_len	equ $E					; Length of structure

; ------------------------------------------------------------------------------
; Child header structure
; ------------------------------------------------------------------------------

chlist.head		equ 0					; List head
chlist.tails		equ 2					; List tail
chlist.struct_len	equ 4					; Length of structure

; ------------------------------------------------------------------------------

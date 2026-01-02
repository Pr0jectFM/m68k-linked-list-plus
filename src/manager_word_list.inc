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
; Manager list header structure
; ------------------------------------------------------------------------------

malist.head		equ 0					; List head
malist.tail		equ 2					; List tail
malist.freed		equ 4					; Freed nodes tail
malist.node_size	equ 6					; Size of node
malist.cursor		equ 8					; List cursor
malist.end		equ $A					; End of list
malist.chhead		equ $C					; Beginning location of the child list
malist.chlen		equ $E					; Child list length
malist.struct_len	equ $10					; Length of structure

; ------------------------------------------------------------------------------
; Manager list node header structure
; ------------------------------------------------------------------------------

manode.next		equ 0					; Next node
manode.previous		equ 2					; Previous node
manode.list		equ 4					; List the node is part of
manode.child		equ 6					; Location of child
manode.childsize	equ 8					; Amount of space allocated for this child
manode.childfree	equ $A					; Total amount of space between this child and the next
manode.struct_len	equ $C					; Length of structure

; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; Word list functions
; ----------------------------------------------------------------------
; Copyright (c) 2024 Devon Artmeier
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
; Initialize word list
; ------------------------------------------------------------------------------
; PARAMETERS:
;	d0.w - Node size (node header included)
;	d1.w - Number of nodes in pool
;	d2.w - Number of lists
;	a0.l - Shared list address
; ------------------------------------------------------------------------------

InitSharedList:
	movem.l	d0-d3/a1,-(sp)					; Save registers
	
	move.w	d2,sharedlist.Children(a0)

	clr.w	sharedlist.Head(a0)					; Reset head and tail
	clr.w	sharedlist.Freed(a0)				; Reset freed nodes tail
	move.w	d0,sharedlist.NodeSize(a0)			; Set node size

	lea	sharedlist.StructLen(a0),a1			; Child lists
	clropt.l	d3						; Clear value

.ClearChildren:
	move.l	d3,(a1)+				; Reset head and tail
	dbf	d2,.ClearChildren
	move.w	a1,sharedlist.Start(a0)

	move.w	a1,d3
	add.w	d0,d3
	move.w	d3,sharedlist.Cursor(a0)

	mulu.w	d1,d0						; Set end of list
	add.w	a1,d0
	move.w	d0,sharedlist.End(a0)

	subq.w	#1,d1						; Node loop count
	clropt.l	d0

.SetupNodes:
	move.l	d0,(a1)+					; Reset links
	move.w	d0,(a1)+

	move.w	sharedlist.NodeSize(a0),d3				; Node data loop count
	subq.w	#node.StructLen,d3
	lsr.w	#1,d3
	subq.w	#1,d3

.ClearNode:
	move.w	d0,(a1)+					; Clear node data
	dbf	d3,.ClearNode					; Loop until node data is cleared
	dbf	d1,.SetupNodes					; Loop until all nodes are set up
	movem.l	(sp)+,d0-d3/a1					; Restore registers
	rts

; ------------------------------------------------------------------------------
; Reset word list
; ------------------------------------------------------------------------------
; PARAMETERS:
;	a4.l - Word list address
; ------------------------------------------------------------------------------

ResetSharedList:
	movem.l	d0-d1/a5,-(sp)					; Save registers
	
	clr.w	sharedlist.Head(a4)					; Reset list
	clr.w	sharedlist.Freed(a4)				; Reset freed node tail
	
	move.w	sharedlist.Start(a4),d0
	add.w	sharedlist.NodeSize(a4),d0
	move.w	d0,sharedlist.Cursor(a4)

	clropt.l	d0
	move.w	sharedlist.Children(a4),d1
	lea	sharedlist.StructLen(a4),a5			; Child lists

.ClearChildren:
	move.l	d0,(a5)+					; Reset head and tail
	dbf	d1,.ClearChildren

	clr.l	node.Next(a5)					; Reset next and previous links in first node
	
	movem.l	(sp)+,d0-d1/a5					; Restore registers
	rts

; ------------------------------------------------------------------------------
; Add word list node
; ------------------------------------------------------------------------------
; PARAMETERS:
;	a4.l  - Word list address
;	d0.w  - Layer*childlist.StructLen
; RETURNS:
;	eq/ne - Success/Failure
;	a5.l  - Allocated word list node
; ------------------------------------------------------------------------------

AddSharedListNode:
	movem.l	d0-d1/a2-a3,-(sp)					; Save registers
	lea	sharedlist.StructLen(a4,d0.w),a3

	moveq	#1,d7
	tst.w	sharedlist.Head(a4)					; Are there any nodes?
	beq	.NoNodes					; If not, branch

; ------------------------------------------------------------------------------

	moveq	#2,d7
	move.w	sharedlist.Freed(a4),d0				; Were there any nodes that were freed?
	beq.s	.Append						; If not, branch

	moveq	#3,d7
	movea.w	d0,a5						; If so, retrieve node
	move.w	node.Next(a5),sharedlist.Freed(a4)			; Set next free node

	tst.w	childlist.Head(a3)					; Are there any nodes?
	bne.s	.SetLinks					; If so, branch
	move.w	a5,childlist.Head(a3)
	move.w	a5,childlist.Tail(a3)

; ------------------------------------------------------------------------------

.SetLinks:
	movea.w	childlist.Tail(a3),a2				; Get list tail
	move.w	a5,childlist.Tail(a3)

	move.w	a5,node.Next(a2)				; Set links
	move.w	a2,node.Prev(a5)
	clr.w	node.Next(a5)

; ------------------------------------------------------------------------------

.Finish:
	lea	node.StructLen(a5),a2				; Node data
	move.w	sharedlist.NodeSize(a4),d0				; Clear loop count
	subq.w	#node.StructLen,d0
	lsr.w	#1,d0
	subq.w	#1,d0
	moveq	#0,d1						; Zero

.ClearNode:
	move.w	d1,(a2)+					; Clear node data
	dbf	d0,.ClearNode					; Loop until node data is cleared

	if def(__DEBUG__)
		bsr	CheckList
	endif

	movem.l	(sp)+,d0-d1/a2-a3					; Restore registers
	ori	#4,sr						; Success
	rts

; ------------------------------------------------------------------------------

.NoNodes:
	move.w	sharedlist.Start(a4),a5				; Allocate at start of list node pool
	move.w	a5,sharedlist.Head(a4)
	move.w	a5,childlist.Head(a3)
	move.w	a5,childlist.Tail(a3)
	bra	.Finish

; ------------------------------------------------------------------------------

.Append:
	move.w	sharedlist.Cursor(a4),d0				; Get cursor
	cmp.w	sharedlist.End(a4),d0					; Is there no more room?
	bcc.s	.Fail						; If so, branch

	movea.w	d0,a5
	add.w	sharedlist.NodeSize(a4),d0				; Advance cursor
	move.w	d0,sharedlist.Cursor(a4)

	tst.w	childlist.Head(a3)					; Are there any nodes?
	bne.s	.SetLinks					; If so, branch
	move.w	a5,childlist.Head(a3)
	move.w	a5,childlist.Tail(a3)

	bra	.SetLinks					; Set links

; ------------------------------------------------------------------------------

.Fail:
	if def(__DEBUG__)
		RaiseError "No more room in the shared linked list!"
	endif
	movem.l	(sp)+,d0-d1/a2-a3					; Restore registers
	andi	#~4,sr						; Failure
	rts

; ------------------------------------------------------------------------------
; Remove word list node
; ------------------------------------------------------------------------------
; PARAMETERS:
;	a4.l  - Word list address
;	a5.l  - Word list node
;	d0.w  - Layer*childlist.StructLen
; RETURNS:
;	eq/ne - End of word list/Not end of word list
;	a5.l  - Next word list node
; ------------------------------------------------------------------------------

RemoveSharedListNode:
	movem.l	d0/a2-a3,-(sp)					; Save registers
	
	move.w	node.Next(a5),-(sp)				; Get next node

	lea	sharedlist.StructLen(a4,d0.w),a3

	cmpa.w	childlist.Head(a3),a5				; Is this the head node?
	beq	.Head						; If not, branch
	cmpa.w	childlist.Tail(a3),a5				; Is this the tail node?
	beq	.Tail						; If so, branch

; ------------------------------------------------------------------------------

.Middle:
	moveq	#1,d7
	movea.w	node.Prev(a5),a2				; Fix links
	move.w	node.Next(a5),node.Next(a2)
	movea.w	node.Next(a5),a2
	move.w	node.Prev(a5),node.Prev(a2)

; ------------------------------------------------------------------------------

.AppendFreed:
	move.w	sharedlist.Freed(a4),d0				; Get freed list tail
	beq.s	.FirstFreed					; If there are no freed nodes, branch

	move.w	d0,node.Next(a5)				; Set links

	move.w	a5,sharedlist.Freed(a4)
	bra.s	.Finish	

.FirstFreed:
	move.w	a5,sharedlist.Freed(a4)				; Set first freed node
	clr.w	node.Next(a5)

; ------------------------------------------------------------------------------

.Finish:
	assert.w	sharedlist.Freed(a4),ne,#0

	if def(__DEBUG__)
		bsr	CheckList
	endif

	movea.w	(sp)+,a5					; Get next node
	movem.l	(sp)+,d0/a2-a3					; Restore registers
	
	cmpa.w	#0,a5						; Check if next node exists
	rts

; ------------------------------------------------------------------------------

.Tail:
	movea.w	node.Prev(a5),a2				; Fix links
	move.w	a2,childlist.Tail(a3)
	clr.w	node.Next(a2)

	bra	.AppendFreed					; Append freed nodes

; ------------------------------------------------------------------------------

.Head:
	cmpa.w	childlist.Tail(a3),a5				; Is this also the tail node?
	beq.s	.Last						; If so, branch

	movea.w	node.Next(a5),a2				; Fix links
	move.w	a2,childlist.Head(a3)
	clr.w	node.Prev(a2)

	bra	.AppendFreed					; Append freed nodes

; ------------------------------------------------------------------------------

.Last:
	clr.l	childlist.Head(a3)
	clr.w	(sp)

	move.w	sharedlist.StructLen(a4),a2
	move.w	sharedlist.Children(a4),d0

.CheckClear:
	tst.l	(a2)+
	bne	.AppendFreed
	dbf	d0,.CheckClear
	bsr	ResetSharedList

	bra	.Finish

; ------------------------------------------------------------------------------

CheckList:
	pushr.l	d0/a3/a5
	lea	sharedlist.StructLen(a4),a3
	move.w	sharedlist.Children(a4),d0

.superloop:
	move.w	childlist.Head(a3),a5
	bra	.entry

.loop:
	move.w	node.Next(a5),a5
	assert.w	a5,ne,#0

.entry:
	cmp.w	childlist.Tail(a3),a5
	bne	.loop
	addq.w	#childlist.StructLen,a3
	dbf	d0,.superloop


	popr.l	d0/a3/a5
	rts
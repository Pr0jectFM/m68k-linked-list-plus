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
;	d2.w - Child list length
;	a0.l - List address
; ------------------------------------------------------------------------------

InitManList:
	pushr.l	d0-d2/a1					; Save registers
	
	clr.l	manlist.Head(a0)					; Reset head and tail
	clr.w	manlist.Freed(a0)					; Reset freed nodes tail
	move.w	d0,manlist.NodeSize(a0)				; Set node size
	
	move.w	d2,manlist.ChildLen(a0)

	mulu.w	d1,d0						; Set end of list
	addi.w	#manlist.StructLen,d0
	add.w	a0,d0
	move.w	d0,manlist.End(a0)

	moveq	#manlist.StructLen,d0				; Reset cursor
	add.w	manlist.NodeSize(a0),d0
	add.w	a0,d0
	move.w	d0,manlist.Cursor(a0)


	subq.w	#1,d1						; Node loop count
	lea	manlist.StructLen(a0),a1				; Node pool
	moveq	#0,d0						; Clear value

.SetupNodes:
	move.l	d0,(a1)+					; Reset links
	move.w	d0,(a1)+

	move.w	manlist.NodeSize(a0),d2				; Node data loop count
	sub.w	#mannode.StructLen,d2
	beq	.skip
	lsr.w	#1,d2
	subq.w	#1,d2

.ClearNode:
	move.w	d0,(a1)+					; Clear node data
	dbf	d2,.ClearNode					; Loop until node data is cleared
	dbf	d1,.SetupNodes					; Loop until all nodes are set up

.skip:
	popr.l	d0-d2/a1					; Restore registers
	rts

; ------------------------------------------------------------------------------
; Reset word list
; ------------------------------------------------------------------------------
; PARAMETERS:
;	a4.l - Word list address
; ------------------------------------------------------------------------------

ResetManList:
	pushr.l	d0/a1					; Save registers
	
	clr.l	manlist.Head(a4)					; Reset list
	clr.w	manlist.Freed(a4)					; Reset freed node tail

	moveq	#manlist.StructLen,d0				; Reset cursor
	add.w	manlist.NodeSize(a4),d0
	add.w	a4,d0
	move.w	d0,manlist.Cursor(a4)

	move.w	d2,manlist.StructLen+mannode.ChildFree(a1)

	clr.l	manlist.StructLen+mannode.Next(a4)			; Reset next and previous links in first node
	
	popr.l	d0/a1					; Restore registers
	rts

; ------------------------------------------------------------------------------
; Add word list node
; ------------------------------------------------------------------------------
; PARAMETERS:
;	d0.w  - Size of child
;	a4.l  - Word list address
; RETURNS:
;	eq/ne - Success/Failure
;	a5.l  - Allocated word list node
; ------------------------------------------------------------------------------

AddManListNode:
	pushr.l	d1-d2/a3					; Save registers
	
	tst.w	manlist.Head(a4)					; Are there any nodes?
	beq	.NoNodes					; If not, branch

; ------------------------------------------------------------------------------

	move.w	manlist.Freed(a4),d1				; Were there any nodes that were freed?
	beq.s	.Append						; If not, branch
	
	movea.w	d1,a5						; If so, retrieve node
	move.w	mannode.Next(a5),manlist.Freed(a4)			; Set next free node

; ------------------------------------------------------------------------------

.SetLinks:
	bsr	LocateChild

; ------------------------------------------------------------------------------

.Finish:
	lea	mannode.StructLen(a5),a3				; Node data
	move.w	manlist.NodeSize(a4),d0				; Clear loop count
	sub.w	#mannode.StructLen,d0
	beq	.SkipClear
	lsr.w	#1,d0
	subq.w	#1,d0
	moveq	#0,d1						; Zero

.ClearNode:
	move.w	d1,(a3)+					; Clear node data
	dbf	d0,.ClearNode					; Loop until node data is cleared

.SkipClear:
	if def(__DEBUG__)
		bsr	TestManList
	endif

	movem.l	(sp)+,d1-d2/a3					; Restore registers

	ori	#4,sr						; Success
	rts
	
; ------------------------------------------------------------------------------

.Append:
	move.w	manlist.Cursor(a4),d1				; Get cursor
	cmp.w	manlist.End(a4),d1					; Is there no more room?
	bcc.s	.Fail						; If so, branch

	movea.w	d1,a5
	add.w	manlist.NodeSize(a4),d1				; Advance cursor
	move.w	d1,manlist.Cursor(a4)

	bra.s	.SetLinks					; Set links

; ------------------------------------------------------------------------------

.Fail:
	if def(__DEBUG__)
		RaiseError "No more room in the manager list!"
	endif
	popr.l	d1-d2/a3					; Restore registers
	andi	#~4,sr						; Failure
	rts

; ------------------------------------------------------------------------------

.NoNodes:
	lea	manlist.StructLen(a4),a5				; Allocate at start of list node pool
	move.w	a5,manlist.Head(a4)
	move.w	a5,manlist.Tail(a4)

	move.w	manlist.ChildHead(a4),d1
	move.w	d0,mannode.ChildSize(a5)
	move.w	manlist.ChildLen(a4),mannode.ChildFree(a5)
	move.w	d1,mannode.Child(a5)

	bra	.Finish

; ------------------------------------------------------------------------------
; Add word list node
; ------------------------------------------------------------------------------
; PARAMETERS:
;	d0.w  - Size of child
;	d1.w  - Space to place it
;	a4.l  - Word list address
; RETURNS:
;	eq/ne - Success/Failure
;	a5.l  - Allocated word list node
; ------------------------------------------------------------------------------

AddManListNodeFixed:
	pushr.l	d1-d3/a3					; Save registers
	move.w	manlist.Head(a4),a3
	cmp.w	#0,a3
	beq	.NoNodes
	move.w	d0,d3
	add.w	d1,d3
	bra	.FindNode

.NextNode:
	cmp.w	manlist.Tail(a4),a3
	beq	.Tail
	move.w	mannode.Next(a3),a3

.FindNode:
	cmp.w	mannode.Child(a3),d3
	bhi	.NextNode

	move.w	mannode.Prev(a3),a3
	move.w	mannode.Child(a3),d2
	add.w	mannode.ChildSize(a3),d2
	cmp.w	d1,d2
	bhi	.Taken
	move.w	mannode.Child(a3),d2
	add.w	mannode.ChildFree(a3),d2
	cmp.w	d3,d2
	blo	.Taken

	tst.w	manlist.Freed(a4)
	beq	.MiddleNoFreed
	move.w	manlist.Freed(a4),a5
	move.w	mannode.Next(a5),manlist.Freed(a4)
	bra	.MiddleCont

.MiddleNoFreed:
	move.w	manlist.Cursor(a4),d2				; Get cursor
	cmp.w	manlist.End(a4),d2					; Is there no more room?
	bcc	.Fail						; If so, branch

	move.w	d2,a5
	add.w	manlist.NodeSize(a4),d2				; Advance cursor
	move.w	d2,manlist.Cursor(a4)

.MiddleCont:
	pushr.w	a4
	move.w	mannode.Next(a3),a4
	move.w	a4,mannode.Next(a5)
	move.w	a5,mannode.Prev(a4)
	popr.w	a4
	move.w	a5,mannode.Next(a3)
	move.w	a3,mannode.Prev(a5)
	move.w	d0,mannode.ChildSize(a5)

	move.w	mannode.Child(a3),d2
	add.w	mannode.ChildFree(a3),d2
	sub.w	d1,d2
	move.w	d2,mannode.ChildFree(a5)

	move.w	d1,d2
	add.w	manlist.ChildHead(a4),d2
	move.w	d2,mannode.Child(a5)
	sub.w	mannode.Child(a3),d2
	move.w	d2,mannode.ChildFree(a3)
	bra	.Finish

; ------------------------------------------------------------------------------

.NoNodes:
	; create dummy node
	lea	manlist.StructLen(a4),a3				; Allocate at start of list node pool
	move.w	a3,manlist.Head(a4)
	tst.w	d1
	bne	.KeepDummy
	move.w	a3,a5
	bra	.SkipDummy

.KeepDummy:
	move.w	manlist.ChildHead(a4),mannode.Child(a3)
	clr.w	mannode.ChildSize(a3)
	move.w	d1,mannode.ChildFree(a3)
	lea	mannode.StructLen(a3),a5
	move.w	a5,mannode.Next(a3)
	move.w	a3,mannode.Prev(a5)

.SkipDummy:
	; setup proper node
	move.w	a5,manlist.Tail(a4)
	move.w	d0,mannode.ChildSize(a5)
	move.w	d1,d2
	add.w	manlist.ChildHead(a4),d2
	move.w	d2,mannode.Child(a5)
	move.w	manlist.ChildLen(a4),d2
	sub.w	d1,d2
	move.w	d2,mannode.ChildFree(a5)
	clr.w	mannode.Next(a5)

	move.w	a5,d2
	add.w	manlist.NodeSize(a4),d2				; Advance cursor
	move.w	d2,manlist.Cursor(a4)

	bra	.Finish
; ------------------------------------------------------------------------------

.Tail:
	move.w	mannode.Child(a3),d2
	add.w	mannode.ChildSize(a3),d2
	cmp.w	d1,d2
	bhi	.Taken
	move.w	mannode.Child(a3),d2
	add.w	mannode.ChildFree(a3),d2
	cmp.w	d3,d2
	blo	.Taken

	move.w	d1,d2
	sub.w	mannode.Child(a3),d2
	move.w	d2,mannode.ChildFree(a3)
	tst.w	manlist.Freed(a4)
	beq	.TailNoFreed
	move.w	manlist.Freed(a4),a5
	move.w	mannode.Next(a5),manlist.Freed(a4)
	bra	.TailCont

.TailNoFreed:
	move.w	manlist.Cursor(a4),d2				; Get cursor
	cmp.w	manlist.End(a4),d2					; Is there no more room?
	bcc.s	.Fail						; If so, branch

	move.w	d2,a5
	add.w	manlist.NodeSize(a4),d2				; Advance cursor
	move.w	d2,manlist.Cursor(a4)

.TailCont:
	move.w	a5,mannode.Next(a3)
	move.w	a3,mannode.Prev(a5)
	move.w	a5,manlist.Tail(a4)
	move.w	d0,mannode.ChildSize(a5)
	move.w	d1,d2
	add.w	manlist.ChildHead(a4),d2
	move.w	d2,mannode.Child(a5)
	move.w	manlist.ChildLen(a4),d2
	sub.w	d1,d2
	move.w	d2,mannode.ChildFree(a5)
	clr.w	mannode.Next(a5)
	bra	.Finish
; ------------------------------------------------------------------------------

.Taken:
	if def(__DEBUG__)
		move.w	mannode.Child(a3),d7
		RaiseError "Area has been taken!"
	endif
	popr.l	d1-d3/a3					; Restore registers
	andi	#~4,sr						; Failure
	rts
; ------------------------------------------------------------------------------

.Fail:
	if def(__DEBUG__)
		RaiseError "No more room in the manager list!"
	endif
	popr.l	d1-d2/a3					; Restore registers
	andi	#~4,sr						; Failure
	rts

; ------------------------------------------------------------------------------

.Finish:
	lea	mannode.StructLen(a5),a3				; Node data
	move.w	manlist.NodeSize(a4),d0				; Clear loop count
	sub.w	#mannode.StructLen,d0
	beq	.SkipClear
	lsr.w	#1,d0
	subq.w	#1,d0
	moveq	#0,d1						; Zero

.ClearNode:
	move.w	d1,(a3)+					; Clear node data
	dbf	d0,.ClearNode					; Loop until node data is cleared

.SkipClear:
	if def(__DEBUG__)
		bsr	TestManList
	endif

	movem.l	(sp)+,d1-d3/a3					; Restore registers

	ori	#4,sr						; Success
	rts

; ------------------------------------------------------------------------------
; Find place to put the child
; ------------------------------------------------------------------------------
; PARAMETERS:
;	d0.w  - Size of child
;	a3.l  - Current node
;	a4.l  - Word list address
;	a5.l  - New node
; ------------------------------------------------------------------------------

LocateChild:
	movea.w	manlist.Tail(a4),a3				; Get list tail
	move.w	mannode.ChildFree(a3),d1
	sub.w	mannode.ChildSize(a3),d1
	cmp.w	d1,d0
	bhi.s	.Loop
	move.w	a5,manlist.Tail(a4)
	move.w	a5,mannode.Next(a3)				; Set links
	move.w	a3,mannode.Prev(a5)
	bra	.SetChild

.Loop:
	cmp.w	manlist.Head(a4),a3
	beq	.Fail
	move.w	mannode.Prev(a3),a3
	
.Search:
	move.w	mannode.ChildFree(a3),d1
	sub.w	mannode.ChildSize(a3),d1
	cmp.w	d1,d0
	bhi.s	.Loop
	pushr.w	a4
	move.w	mannode.Next(a3),a4
	move.w	a5,mannode.Next(a3)				; Set links
	move.w	a4,mannode.Next(a5)
	move.w	a5,mannode.Prev(a4)
	move.w	a3,mannode.Prev(a5)
	popr.w	a4

.SetChild:
	move.w	mannode.ChildSize(a3),mannode.ChildFree(a3)
	move.w	d0,mannode.ChildSize(a5)
	move.w	d1,mannode.ChildFree(a5)
	move.w	mannode.Child(a3),d1
	add.w	mannode.ChildSize(a3),d1
	move.w	d1,mannode.Child(a5)
	rts

.Fail:
	if def(__DEBUG__)
		RaiseError "No more room for the child!"
	endif
	addq.l	#4,sp
	popr.l	d1-d2/a3					; Restore registers
	andi	#~4,sr						; Failure
	rts

; ------------------------------------------------------------------------------
; Remove word list node
; ------------------------------------------------------------------------------
; PARAMETERS:
;	a4.l  - Word list address
;	a5.l  - Word list node
; RETURNS:
;	eq/ne - End of word list/Not end of word list
;	a5.l  - Next word list node
; ------------------------------------------------------------------------------

RemoveManListNode:
	movem.l	d0/a3,-(sp)					; Save registers
	
	move.w	mannode.Prev(a5),-(sp)				; Get next node

	cmpa.w	manlist.Head(a4),a5				; Is this the head node?
	beq.s	.Head						; If not, branch
	cmpa.w	manlist.Tail(a4),a5				; Is this the tail node?
	beq.s	.Tail						; If so, branch

; ------------------------------------------------------------------------------

.Middle:
	movea.w	mannode.Prev(a5),a3				; Fix links
	move.w	mannode.ChildFree(a5),d0
	add.w	d0,mannode.ChildFree(a3)

	move.w	mannode.Next(a5),mannode.Next(a3)
	movea.w	mannode.Next(a5),a3
	move.w	mannode.Prev(a5),mannode.Prev(a3)

; ------------------------------------------------------------------------------

.AppendFreed:
	move.w	manlist.Freed(a4),d0				; Get freed list tail
	beq.s	.FirstFreed					; If there are no freed nodes, branch

	move.w	d0,mannode.Next(a5)				; Set links
	move.w	a5,manlist.Freed(a4)
	bra.s	.Finish	

.FirstFreed:
	move.w	a5,manlist.Freed(a4)				; Set first freed node
	clr.w	mannode.Next(a5)

; ------------------------------------------------------------------------------

.Finish:
	if def(__DEBUG__)
		bsr	TestManList
	endif

	movea.w	(sp)+,a5					; Get next node
	movem.l	(sp)+,d0/a3					; Restore registers
	
	cmpa.w	#0,a5						; Check if next node exists
	rts

; ------------------------------------------------------------------------------

.Tail:
	movea.w	mannode.Prev(a5),a3				; Fix links
	move.w	mannode.ChildFree(a5),d0
	add.w	d0,mannode.ChildFree(a3)
	move.w	a3,manlist.Tail(a4)
	move.w	mannode.Next(a5),mannode.Next(a3)

	bra.s	.AppendFreed					; Append freed nodes

; ------------------------------------------------------------------------------

.Head:
	cmpa.w	manlist.Tail(a4),a5				; Is this also the tail node?
	beq.s	.Last						; If so, branch

	illegal

	movea.w	mannode.Next(a5),a3				; Fix links
	move.w	a3,manlist.Head(a4)
	clr.w	mannode.Prev(a3)

	bra.s	.AppendFreed					; Append freed nodes

; ------------------------------------------------------------------------------

.Last:
	bsr	ResetManList					; Reset list
	clr.w	(sp)
	bra.s	.Finish

; ------------------------------------------------------------------------------

TestManList:
	pushr.l	d0-d1/a3-a5

	move.w	manlist.Head(a4),a5
	cmp.w	#0,a5
	beq	.end
	clropt.l	d1

.loop:
	move.w	mannode.ChildFree(a5),d0
	assert.w	d0,pl,#0		; node child allocated space must be positive
	assert.w	mannode.ChildSize(a5),pl,#0	; node child size must be positive
	assert.w	d0,hs,mannode.ChildSize(a5)	; node child allocated space must be larger or equal to the size
	add.w	d0,d1
	cmp.w	manlist.Tail(a4),a5
	beq	.next
	move.w	a5,a3
	move.w	mannode.Next(a5),a5
	move.w	mannode.Child(a5),d0
	assert.w	d0,hs,mannode.Child(a3)	; the nodes must have their children be in order
	bra	.loop

.next:
	move.w	manlist.ChildLen(a4),d0
	assert.w	d1,eq,d0		; all node child allocated space must add up to the full size

.end:
	popr.l	d0-d1/a3-a5
	rts
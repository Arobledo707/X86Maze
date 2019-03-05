;maze game by Alberto Robledo
.586
.model flat, stdcall
option casemap:none

; Link in the CRT.
includelib libcmt.lib
includelib libvcruntime.lib
includelib libucrt.lib
includelib legacy_stdio_definitions.lib

extern printf:NEAR
extern _getch:NEAR

.data
		movePrompt db 'Use wasd to move:', 0ah, 0
		winText db 'You Win!', 0ah, 0
		loseText db 'You died!', 0ah, 0
		
		maze db '.','.','T','.','.','.','.','.','.','.', 0ah
		 db '.','.','T','.','T','.','T','.','.','.', 0ah
		 db '.','.','.','.','.','.','.','.','T','.', 0ah
		 db '.','.','.','T','.','.','T','.','.','T', 0ah
		 db '.','.','.','.','.','.','.','.','.','.', 0ah
		 db '.','T','.','.','.','T','.','.','T','.', 0ah
		 db '.','.','.','T','.','.','.','.','.','.', 0ah
		 db '.','.','.','.','.','.','T','.','.','.', 0ah
		 db '.','.','.','.','.','.','.','.','T','.', 0ah
		 db '.','T','.','.','X','.','.','.','.','.', 0ah, 0
		
		
.code

; maze is stored in esi
; player location is stored in ebx
main proc c
		call LoadMaze
	MainLoop:
		call PrintMaze

		call TakeTurn
		
		; checks to see if game continues
		; 0 is continue
		cmp eax, 0
		jne GameEnd
		
		; jumps back to game if eax is 0
		jmp MainLoop
		
	GameEnd:
		ret
main endp

FunctionPrologue macro
		push ebp
		mov ebp, esp
endm

FunctionEpilogue macro
		mov esp, ebp
		pop ebp
endm

CheckCollisionAndSetPlayer macro
		; checks to see if player hit a trap
		cmp byte ptr[esi+ebx], 'T'
		je endGame
		
		; checks to see if player hit goal
		cmp byte ptr[esi+ebx], 'X'
		je winGame
		
		; sets location to be players new location
		mov byte ptr[esi+ebx], 50h

endm


; gets user input for movement
TakeTurn proc
		FunctionPrologue
		
	InputLoop:
		; prints prompt for player
		push offset movePrompt
		call printf
		add esp, 8
		
		; checks user input -------------------------------
		call _getch
		; check if equal to down 's'
		cmp eax, 73h
		je CheckMoveDown
		
		; check if equal to up 'w'
		cmp eax, 77h
		je CheckMoveUp
		
		; check if equal to left 'a'
		cmp eax, 61h
		je CheckMoveLeft
		
		; check if equal to right 'd'
		cmp eax, 64h
		je CheckMoveRight
		
		; check if equal to quit 'q'
		cmp eax, 71h
		je endGame
		;----------------------------------------------------
		
		; end turn if none of these were pressed
		jmp endTurnAlive
		
	; checks for player movement ---------------------------------
	CheckMoveLeft:
		
		; sets registers for division
		; moves player location into eax
		; sets edx to zero
		mov eax, ebx
		mov edx, 0
		
		; moves 11 into ecx
		; maze is 10 x 11
		; so divide by the column amount
		mov ecx, 11
		idiv ecx
		; if its zero then we are at the start of a column
		cmp edx, 0
		je endTurnAlive
		
		; else we move left
		jmp MoveLeft
		
	CheckMoveRight:
		; checks if the element to the right is 0ah
		cmp byte ptr[esi+ebx+1], 0ah
		je endTurnAlive
		
		; if it isnt we can move right
		jmp MoveRight
		
	CheckMoveUp:
		; if we are at element 10 or less
		; we cant move up
		cmp ebx, 10
		jle endTurnAlive
		
		; else we can move up
		jmp MoveUp
		
	CheckMoveDown:
		; if we are past element 99 we cant move down
		cmp ebx, 99
		jge endTurnAlive
		
		; else move down
		jmp MoveDown
		
	; ---------------------------------------------------------------------
		
		
	; Movement and collision checking ------------------------------------------
	MoveLeft:
		; clears current location to '.'
		mov byte ptr [esi+ebx], 2Eh
		
		; moves left by 1
		sub ebx, 1
		
		; checks for collision for 'X' and 'T'
		CheckCollisionAndSetPlayer
		
		; if we didnt collide we end the turn and
		; jump to set eax to 0
		jmp endTurnAlive

	MoveRight:
		; clears player position to '.'
		mov byte ptr [esi+ebx], 2Eh
		
		; sets player position to the right by 1
		add ebx, 1
		
		CheckCollisionAndSetPlayer
	
		jmp endTurnAlive
		
	MoveDown:
	; clears current location to '.'
		mov byte ptr [esi+ebx], 2Eh
		
		; moves down 1 row
		add ebx, 11
		
		CheckCollisionAndSetPlayer
	
		jmp endTurnAlive
		
	MoveUp:
	; clears current location to '.'
		mov byte ptr[esi+ebx], 2Eh
		
		; moves up by one row
		sub ebx, 11
		
		CheckCollisionAndSetPlayer
		
		jmp endTurnAlive
	;-------------------------------------------------------------------	
		
		
		
	; end game flags ----------------------------------------------------
	; sets eax to 1 if player runs into a trap
	endGame:
		mov eax, 1
		; prints you lose text
		push offset loseText
		call printf
		add esp, 8
		
		jmp endTurn
		
	;sets eax to 2 for when the player arrives at goal
	winGame:
		mov eax, 2
		; prints you win text
		push offset winText
		call printf
		add esp, 8
		
		jmp endTurn
		
	; sets eax to zero if player is still alive or playing
	endTurnAlive:
		mov eax, 0
	
	endTurn:
	;-----------------------------------------------------------------------
		FunctionEpilogue
		ret
TakeTurn endp

PrintMaze proc
		FunctionPrologue
		; pushes the maze and prints it
		; maze is stored in esi
		push esi
		call printf
		add esp, 8
		
		FunctionEpilogue
		ret 
PrintMaze endp

; loads maze and spawns player
LoadMaze proc
		FunctionPrologue

		; moves maze to esi
		mov esi, offset maze
		
		call SpawnPlayer
		
		FunctionEpilogue
		ret
LoadMaze endp

;spawns player at location 5, 0
SpawnPlayer proc
		FunctionPrologue
		; storing player postion in ebx
		mov ebx, 5
		
		mov byte ptr [esi+ebx], 50h
		
		FunctionEpilogue
		ret
SpawnPlayer endp

END
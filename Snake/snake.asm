EXTRN ExitProcess: PROC
EXTRN GetStdHandle: PROC
EXTRN WriteConsoleA: PROC
EXTRN SetConsoleCursorPosition: PROC
EXTRN Sleep: PROC
EXTRN GetAsyncKeyState: PROC

.data
	consoleHandle QWORD ?       ; Console output handle
    bytesWritten DWORD ?        ; Required by WriteConsoleA
    STD_OUTPUT_HANDLE EQU -11   ; Param to get output handle
    
    wallChar BYTE '#', 0
    spaceChar BYTE ' ', 0
	snakeHeadChar BYTE '@', 0

	; Snake head position
    snakeHeadX WORD 40
    snakeHeadY WORD 12

	; Direction (0=Up, 1=Down, 2=Left, 3=Right)
	direction QWORD 3

	gameOver QWORD 0 ; 0 = fun, 1 = game over

.code 
	main PROC
		; Get console output handle
		mov rcx, STD_OUTPUT_HANDLE
		call GetStdHandle
		mov consoleHandle, rax
		
		; Draw walls
		call DrawWalls

		; Draw Snake Head
		call DrawSnakeHead

		; Main game loop
	GameLoop:
		; Check if game is over
		mov rax, gameOver
		cmp rax, 1
		je GameEnd
		
		; Check keyboard input
		call CheckKeyboard
		
		; Move the snake
		call MoveSnake
		
		; Game speed
		sub rsp, 32
		mov rcx, 150 ; Sleep for 150 ms
		call Sleep
		add rsp, 32
		
		; Continue loop
		jmp GameLoop

	GameEnd:
		; Exit
		mov rcx, 0
		call ExitProcess
	main ENDP

	; SetCursorPosition - Move cursor to X, Y
	; Params: RCX = X (column), RDX = Y (row)
	SetCursorPosition PROC
		; Save params
		push rcx
		push rdx
		
		; COORD is X - 16 bits, Y - 16 bits
		mov ax, cx
		shl rdx, 16 ; Shift Y to upper 16 bits
		or rdx, rax ; RDX has Y high, X low
		
		mov rcx, consoleHandle
		call SetConsoleCursorPosition
		
		pop rdx
		pop rcx
		ret
	SetCursorPosition ENDP

	; DrawChar - Draw a character at current cursor position
	; Params: RCX = address of character to draw
	DrawChar PROC
		push rcx
		
		mov r10, rcx ; Save character address
		
		sub rsp, 40 ; Shadow
		
		mov rcx, consoleHandle ; Console handle
		mov rdx, r10 ; Character address
		mov r8, 1 ; Write 1 character
		lea r9, bytesWritten ; Address to store bytes written
		mov qword ptr [rsp+32], 0 ; Reserved param (NULL)
		
		call WriteConsoleA
		
		add rsp, 40
		
		pop rcx
		ret
	DrawChar ENDP

	; DrawWalls - Draw walls
	DrawWalls PROC
		; Board dimensions: 80x25 (X: 0-79, Y: 0-24)

		push r12
		push r13
		
		; Draw top wall (Y = 0, X = 0 to 79)
		mov r12, 0 ; X counter
	DrawTopWall:
		cmp r12, 80
		jge DrawTopWallDone
		
		mov rcx, r12 ; X position
		mov rdx, 0 ; Y = 0 (top)
		call SetCursorPosition
		
		lea rcx, wallChar
		call DrawChar
		
		inc r12
		jmp DrawTopWall
	DrawTopWallDone:

		; Draw bottom wall (Y = 24, X = 0 to 79)
		mov r12, 0 ; X counter
	DrawBottomWall:
		cmp r12, 80
		jge DrawBottomWallDone
		
		mov rcx, r12 ; X position
		mov rdx, 24 ; Y = 24 (bottom)
		call SetCursorPosition
		
		lea rcx, wallChar
		call DrawChar
		
		inc r12
		jmp DrawBottomWall
	DrawBottomWallDone:

		; Draw left wall (X = 0, Y = 0 to 24)
		mov r13, 0 ; Y counter
	DrawLeftWall:
		cmp r13, 25
		jge DrawLeftWallDone
		
		mov rcx, 0 ; X = 0 (left)
		mov rdx, r13 ; Y position
		call SetCursorPosition
		
		lea rcx, wallChar
		call DrawChar
		
		inc r13
		jmp DrawLeftWall
	DrawLeftWallDone:

		; Draw right wall (X = 79, Y = 0 to 24)
		mov r13, 0 ; Y counter
	DrawRightWall:
		cmp r13, 25
		jge DrawRightWallDone
		
		mov rcx, 79 ; X = 79 (right)
		mov rdx, r13 ; Y position
		call SetCursorPosition
		
		lea rcx, wallChar
		call DrawChar
		
		inc r13
		jmp DrawRightWall
	DrawRightWallDone:

		pop r13
		pop r12
		ret
	DrawWalls ENDP

	; DrawSnakeHead - Draw Snake Head at postion
	; Params: Uses the snakeHeadX and snakeHeadY
	DrawSnakeHead PROC
		; Set cursor to snake head position
		movzx rcx, snakeHeadX
		movzx rdx, snakeHeadY
		call SetCursorPosition
		
		lea rcx, snakeHeadChar
		call DrawChar
		
		ret
	DrawSnakeHead ENDP

	; EraseSnakeHead - Erase Snake Head at its position
	; Params: Uses the snakeHeadX and snakeHeadY
	EraseSnakeHead PROC
		; Set cursor to snake head position
		movzx rcx, snakeHeadX
		movzx rdx, snakeHeadY
		call SetCursorPosition
		
		lea rcx, spaceChar
		call DrawChar
		
		ret
	EraseSnakeHead ENDP

	; MoveSnake - Move snake one step in current direction
	; Desc: Updates snakeHeadX and snakeHeadY based on direction
	MoveSnake PROC
		; Erase current position
		call EraseSnakeHead
		
		; Update position based on direction
		mov rax, direction
		
		cmp rax, 0 ; Up
		je MoveUp
		cmp rax, 1 ; Down
		je MoveDown
		cmp rax, 2 ; Left
		je MoveLeft
		cmp rax, 3 ; Right
		je MoveRight

		jmp MoveEnd

	MoveUp:
		dec snakeHeadY
		jmp MoveEnd
		
	MoveDown:
		inc snakeHeadY
		jmp MoveEnd
		
	MoveLeft:
		dec snakeHeadX
		jmp MoveEnd
		
	MoveRight:
		inc snakeHeadX
		jmp MoveEnd

	MoveEnd:
		; Draw at new position
		call DrawSnakeHead
		ret
	MoveSnake ENDP

	; CheckKeyboard - Check arrow key press and update direction
	CheckKeyboard PROC
		; Arrow key codes: Up=26h, Down=28h, Left=25h, Right=27h
		
		sub rsp, 40 ; Shadow
		
		; Check Up arrow
		mov rcx, 26h
		call GetAsyncKeyState
		test ax, 8000h ; Check if key is pressed (high bit set)
		jz CheckDown

		; Prevent going down if going up
		mov rax, direction
		cmp rax, 1 ; Don't allow up if going down
		je CheckDown
		mov direction, 0 ; Set direction to Up
		jmp CheckKeyboardEnd

	CheckDown:
		; Check Down arrow
		mov rcx, 28h
		call GetAsyncKeyState
		test ax, 8000h
		jz CheckLeft

		; Prevent going up if going down
		mov rax, direction
		cmp rax, 0 ; Don't allow down if going up
		je CheckLeft
		mov direction, 1 ; Set direction to Down
		jmp CheckKeyboardEnd

	CheckLeft:
		; Check Left arrow
		mov rcx, 25h
		call GetAsyncKeyState
		test ax, 8000h
		jz CheckRight

		; Prevent going right if going left
		mov rax, direction
		cmp rax, 3 ; Don't allow left if going right
		je CheckRight
		mov direction, 2 ; Set direction to Left
		jmp CheckKeyboardEnd

	CheckRight:
		; Check Right arrow
		mov rcx, 27h
		call GetAsyncKeyState
		test ax, 8000h
		jz CheckKeyboardEnd

		; Prevent going left if going right
		mov rax, direction
		cmp rax, 2 ; Don't allow right if going left
		je CheckKeyboardEnd
		mov direction, 3 ; Set direction to Right

	CheckKeyboardEnd:
		add rsp, 40
		ret
	CheckKeyboard ENDP
	
	; CheckCollision - Check if snake ate the wall
	; Desc: Set gameOver = 1 if collision detected
	CheckCollision PROC
		; Check left wall (X = 0)
		movzx rax, snakeHeadX
		cmp rax, 0
		je CollisionDetected
		
		; Check right wall (X = 79)
		cmp rax, 79
		je CollisionDetected
		
		; Check top wall (Y = 0)
		movzx rax, snakeHeadY
		cmp rax, 0
		je CollisionDetected
		
		; Check bottom wall (Y = 24)
		cmp rax, 24
		je CollisionDetected
		
		; No collision
		jmp NoCollision

	CollisionDetected:
		mov gameOver, 1

	NoCollision:
		ret
	CheckCollision ENDP
END
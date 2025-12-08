INCLUDELIB ucrt.lib

EXTRN ExitProcess: PROC
EXTRN GetStdHandle: PROC
EXTRN WriteConsoleA: PROC
EXTRN SetConsoleCursorPosition: PROC
EXTRN SetConsoleTitleA: PROC
EXTRN Sleep: PROC
EXTRN GetAsyncKeyState: PROC
EXTRN SetConsoleCursorInfo: PROC

EXTRN srand: PROC
EXTRN rand: PROC

EXTRN GetTickCount: PROC

.data
	consoleHandle QWORD ? ; Console output handle
    bytesWritten DWORD ? ; Required by WriteConsoleA
    STD_OUTPUT_HANDLE EQU -11 ; Param to get output handle

    wallChar BYTE 219, 0
    spaceChar BYTE ' ', 0
	clearSpaces BYTE '                    ', 0  ; used for clearing

	startSpeed QWORD 100 ; Starting speed
	gameSpeed QWORD 100 ; Speed during game
    minSpeed QWORD 20 ; minimum speed

    ; Game over message
    gameOverMsg BYTE 'GAME OVER!', 0
    gameOverMsgLen EQU $ - gameOverMsg - 1

	gameOver QWORD 0 ; 0 = fun, 1 = game over

    ; Score message
    scoreLabel BYTE 'Score: ', 0
    scoreLabelLen EQU $ - scoreLabel - 1
	scoreBuffer BYTE 20 DUP(0) ; Buffer for score as string

    score QWORD 0 ; Player score

	; Food data
    foodChar BYTE '*', 0
    foodX WORD 0
    foodY WORD 0

	; Snake head position
	snakeHeadChar BYTE '@', 0
    snakeHeadX WORD 40
    snakeHeadY WORD 12
	
	; Direction (0=Up, 1=Down, 2=Left, 3=Right)
	direction QWORD 3

	; Snake body
	bodyChar BYTE '+', 0
	snakeBody WORD 400 DUP(?) ; 200 segments * 2 WORDs (X,Y)
    snakeDim QWORD 1

	; Menu data
	menuSelection QWORD 0 ; Menu selection (0=Play, 1=Instructions, 2=Exit)
	maxMenuItems QWORD 3 ; Number of menu items
	hasPlayedOnce QWORD 0 ; 0 = first time, 1 = has played before

	; Score
	lastScore QWORD 0 ; Store last game score
	highScore QWORD 0 ; Best score achieved

	; Length label
    lengthLabel BYTE 'Length: ', 0
    lengthLabelLen EQU $ - lengthLabel - 1

	; Console title
    consoleTitle BYTE 'Assembly Snake Game', 0
	
	; Menu strings
	titleLine1 BYTE '         SNAKE GAME', 0
	titleLine2 BYTE '    =====================', 0
	
	groupTitle BYTE '    Group Members:', 0
	member1 BYTE '    - Wiktor Szydlowski (75135)', 0
	member2 BYTE '    - Valerii Matviiv (75176)', 0
	member3 BYTE '    - Markiian Voloshyn (75528)', 0
	
	menuPlay BYTE '   PLAY', 0
	menuPlayAgain BYTE '   PLAY AGAIN', 0
	menuInstructions BYTE '   HOW TO PLAY', 0
	menuExit BYTE '   EXIT', 0
	
	menuArrow BYTE '    > ', 0
	menuSpace BYTE '      ', 0
	
	highScoreText BYTE '    High Score: ', 0
	yourScoreText BYTE '    Your Score: ', 0
	
	navHelp BYTE '    Use arrows and ENTER to select', 0
	
	; Instructions text
	instTitle BYTE '         HOW TO PLAY', 0
	instLine1 BYTE '    - Use arrow keys to move', 0
	instLine2 BYTE '    - Eat food (*) to grow', 0
	instLine3 BYTE '    - Avoid walls and yourself', 0
	instLine4 BYTE '    - Press any key to return', 0

.code 
	main PROC
		; Get console output handle
		mov rcx, STD_OUTPUT_HANDLE
		call GetStdHandle
		mov consoleHandle, rax

		; Set console title
		sub rsp, 32
		lea rcx, consoleTitle
		call SetConsoleTitleA
		add rsp, 32

		; Hide the cursor
		call HideCursor
		
		; Init random number genrator
		call InitRandom

	MainMenuLoop:
		; Draw menu
		call DrawMenu

	MenuLoop:
		; Handle menu input
		call MenuInput
		test rax, rax ; Check if Enter was pressed
		jz MenuLoop
		
		; Check which option
		mov rax, menuSelection
		
		cmp rax, 0 ; PLAY option
		je StartGame
		
		cmp rax, 1; HOW TO PLAY option
		je ShowInst
		
		cmp rax, 2 ; EXIT option
		je ExitProgram
		
		jmp MenuLoop ; You never know
		
	ShowInst:
		call ShowInstructions
		jmp MainMenuLoop ; Return to menu
		
	StartGame:
		; Initialize game
		call InitGame

	 ; Clear screen and draw game
		call ClearScreen
		call DrawWalls
		call DrawSnakeHead
		call PlaceFood
		call DrawFood
		call DisplayScore

		; Game loop
	GameLoop:
		; Check if game is over
		mov rax, gameOver
		cmp rax, 1
		je GameEnd
		
		; Check keyboard multiple times (more responsive)
		mov r12, 3

	InputCheckLoop:
		; Check keyboard input
		call CheckKeyboard
		
		; Sleep for 1/3 of the game speed
		sub rsp, 32
		mov rcx, gameSpeed
		mov rax, rcx
		xor rdx, rdx ; Clear rdx (needed for division)
		mov rbx, 3
		div rbx 
		mov rcx, rax
		call Sleep
		add rsp, 32
		
		dec r12
		jnz InputCheckLoop

		call MoveSnake

		call UpdateScore
		call DisplayScore

		; Check if snake ate food
		call CheckFoodCollision
		cmp rax, 1
		jne NoFoodEaten

		; Delicious 
		mov rax, gameSpeed
		sub rax, 2
		mov rbx, minSpeed
		cmp rax, rbx
		jl DontSpeedUp
		mov gameSpeed, rax

	DontSpeedUp::
		call GrowSnake
		call PlaceFood
		call DrawFood
	
	NoFoodEaten:
		; Continue loop
		jmp GameLoop

	GameEnd:
		mov rax, score
		mov lastScore, rax
		
		; Update high score if current score is better
		mov rbx, highScore
		cmp rax, rbx
		jle NoNewHighScore
		mov highScore, rax ; New high score
		
	NoNewHighScore:
		mov hasPlayedOnce, 1
		
		call ShowGameOver
		
		; Reset menu selection to 0 (PLAY AGAIN)
		mov menuSelection, 0
		
		; Return to menu
		jmp MainMenuLoop
		
	ExitProgram:
		mov rcx, 0
		call ExitProcess
	main ENDP

	; HideCursor - Make the console cursor invisible
	HideCursor PROC
		sub rsp, 48 ; Shadow + CONSOLE_CURSOR_INFO
		
		; CONSOLE_CURSOR_INFO
		; dwSize (DWORD) = 1
		; bVisible (BOOL) = 0
		mov dword ptr [rsp+32], 1 ; dwSize = 1
		mov dword ptr [rsp+36], 0 ; bVisible = FALSE
		
		; Call SetConsoleCursorInfo
		mov rcx, consoleHandle
		lea rdx, [rsp+32]
		call SetConsoleCursorInfo
		
		add rsp, 48
		ret
	HideCursor ENDP

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
		push r12
		push r13

		; Save old head position
		mov r12w, snakeHeadX
		mov r13w, snakeHeadY
		
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
		; Check wall collision
		call CheckCollision

		; Check snake body collision
		call CheckSelfCollision

		mov rax, gameOver
		cmp rax, 1
		je SkipBodyUpdate

		; Erase the tail
		mov rax, snakeDim
		dec rax ; Last index
		shl rax, 2 ; Multiply by 4 for offset
		
		; Get tail position
		movzx rcx, word ptr [snakeBody + rax] ; Tail X
		movzx rdx, word ptr [snakeBody + rax + 2] ; Tail Y
		call SetCursorPosition
		lea rcx, spaceChar
		call DrawChar
		
		; Shift body segments forward
		mov rcx, snakeDim
		dec rcx ; Start at last index
		
	ShiftBodyLoop:
		cmp rcx, 0
		jle ShiftBodyDone
		
		; Calculate offsets
		mov rax, rcx
		shl rax, 2 ; Current offset
		
		mov rbx, rcx
		dec rbx
		shl rbx, 2 ; Previous offset
		
		; Copy previous segment to current: body[i] = body[i-1]
		mov dx, word ptr [snakeBody + rbx] ; Get previous X
		mov word ptr [snakeBody + rax], dx ; Set current X
		
		mov dx, word ptr [snakeBody + rbx + 2] ; Get previous Y
		mov word ptr [snakeBody + rax + 2], dx ; Set current Y
		
		dec rcx
		jmp ShiftBodyLoop

	ShiftBodyDone:
		; Update head position
		mov ax, snakeHeadX
		mov snakeBody[0], ax
		mov ax, snakeHeadY
		mov snakeBody[2], ax
		
		; Draw head at new position
		call DrawSnakeHead
		
		; Draw body segments
		mov rax, snakeDim
		cmp rax, 1
		jle SkipBodyUpdate ; No body yet
		
		call DrawSnakeBody

	skipBodyUpdate:
		pop r13
		pop r12

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

	; ShowGameOver - Tell user that he lost 
	ShowGameOver PROC
		push r12

		; Erase the score display next to wall
		mov rcx, 82
		mov rdx, 1
		call SetCursorPosition
		
		sub rsp, 40
		
		mov rcx, consoleHandle
		lea rdx, clearSpaces ; 20 spaces
		mov r8, 20
		lea r9, bytesWritten
		mov qword ptr [rsp+32], 0
		
		call WriteConsoleA
		
		add rsp, 40

		; Clear the game over message area first
		; Clear a rectangle around
		; Clear rows 11-15, colum
		mov r12, 11 ; Start Y
		
	ClearMessageArea:
		cmp r12, 16
		jge ClearDone
		
		mov rcx, 30
		mov rdx, r12
		call SetCursorPosition
		
		; Write 20 spaces
		sub rsp, 40
		mov rcx, consoleHandle
		lea rdx, clearSpaces
		mov r8, 20
		lea r9, bytesWritten
		mov qword ptr [rsp+32], 0
		call WriteConsoleA
		add rsp, 40
		
		inc r12
		jmp ClearMessageArea
		
	ClearDone:
		; Position cursor at center
		mov rcx, 35
		mov rdx, 12
		call SetCursorPosition
		
		; Write game over message
		sub rsp, 40
		
		mov rcx, consoleHandle
		lea rdx, gameOverMsg
		mov r8, gameOverMsgLen
		lea r9, bytesWritten
		mov qword ptr [rsp+32], 0
		
		call WriteConsoleA
		
		add rsp, 40

		; Show final score
		mov rcx, 32
		mov rdx, 14
		call SetCursorPosition
		
		; Write final score label
		sub rsp, 40
		
		mov rcx, consoleHandle
		lea rdx, scoreLabel
		mov r8, scoreLabelLen
		lea r9, bytesWritten
		mov qword ptr [rsp+32], 0
		
		call WriteConsoleA
		
		add rsp, 40
		
		; Convert and display final score
		mov rax, score
		call ConvertScoreToString
		
		sub rsp, 40
		
		mov r8, rcx ; Move length
		mov rcx, consoleHandle
		lea rdx, scoreBuffer
		lea r9, bytesWritten
		mov qword ptr [rsp+32], 0
		
		call WriteConsoleA
		
		add rsp, 40
		
		; Wait so user can see the message
		sub rsp, 32
		mov rcx, 2000 ; 2 seconds
		call Sleep
		add rsp, 32
		
		pop r12

		ret
	ShowGameOver ENDP

	; InitRandom - Init random number generator
	InitRandom PROC
		sub rsp, 32 ; Shadow
		
		; Get system tick as seed
		call GetTickCount

		mov rcx, rax
		call srand
		
		add rsp, 32
		ret
	InitRandom ENDP

	; PlaceFood - Place food at random position
	PlaceFood PROC
		push r12
		push r13
	
	GenerateNewPosition:
		; Generate random X (1 to 78)
		sub rsp, 32
		call rand
		add rsp, 32

		xor rdx, rdx
		mov rcx, 78 ; Range: 78 (positions 1-78)
		div rcx ; rdx = rand() % 78
		inc rdx
		mov foodX, dx
		
		; Generate random Y (1 to 23)
		sub rsp, 32
		call rand
		add rsp, 32

		xor rdx, rdx
		mov rcx, 23 ; Range: 23 (positions 1-23)
		div rcx ; rdx = rand() % 23
		inc rdx
		mov foodY, dx
		
		 ; Check if food position is on the snake body
		movzx r8, foodX
		movzx r9, foodY
		
		; Loop through all snake segments
		xor r12, r12 ; Segment index
		
	CheckSnakeSegments:
		mov rax, snakeDim
		cmp r12, rax
		jge FoodPositionOK ; Checked all segments
		
		; Calculate offset: index * 4
		mov rax, r12
		shl rax, 2
		
		; Get segment position
		movzx rcx, word ptr [snakeBody + rax] ; Segment X
		movzx rdx, word ptr [snakeBody + rax + 2] ; Segment Y
		
		; Compare with food position
		cmp r8, rcx
		jne NotThisSegment
		cmp r9, rdx
		jne NotThisSegment
		
		; Collision! Generate new position
		jmp GenerateNewPosition
		
	NotThisSegment:
		inc r12
		jmp CheckSnakeSegments
		
	FoodPositionOK:
		pop r13
		pop r12
		ret
		ret
	PlaceFood ENDP

	; DrawFood - Draw food at current position
	DrawFood PROC
		; Set cursor to food position
		movzx rcx, foodX
		movzx rdx, foodY
		call SetCursorPosition
		
		lea rcx, foodChar
		call DrawChar
		
		ret
	DrawFood ENDP

	; CheckFoodCollision - Check if snake head is on food
	; Returns: RAX = 1 if food eaten, 0 if not
	CheckFoodCollision PROC
		; Compare X positions
		movzx rax, snakeHeadX
		movzx rbx, foodX
		cmp rax, rbx
		jne NotEaten
		
		; Compare Y positions
		movzx rax, snakeHeadY
		movzx rbx, foodY
		cmp rax, rbx
		jne NotEaten
		
		; Delicious
		mov rax, 1
		ret

	NotEaten:
		mov rax, 0
		ret
	CheckFoodCollision ENDP

	; InitSnake - Init snake body array with head position
	InitSnake PROC
		mov ax, snakeHeadX
		mov snakeBody[0], ax
		
		mov ax, snakeHeadY
		mov snakeBody[2], ax
		
		mov snakeDim, 1
		
		ret
	InitSnake ENDP

	; DrawSnakeBody - Draw all body segments
	DrawSnakeBody PROC
		push r12
		
		mov r12, 1 ; Body index (skip head)
		
	DrawBodyLoop:
		; Check if all segments are drawn
		mov rax, snakeDim
		cmp r12, rax
		jge DrawBodyDone
		
		; Offset = index * 4 (each segment is 2 WORDs = 4 bytes)
		mov rax, r12
		shl rax, 2 ; Multiply by 4
		
		; Get X pos: snakeBody[offset]
		movzx rcx, word ptr [snakeBody + rax]
		
		; Get Y pos: snakeBody[offset + 2]
		movzx rdx, word ptr [snakeBody + rax + 2]
		
		; Draw body
		call SetCursorPosition
		lea rcx, bodyChar
		call DrawChar
		
		inc r12
		jmp DrawBodyLoop

	DrawBodyDone:
		pop r12
		ret
	DrawSnakeBody ENDP

	; GrowSnake - Increment snake length
	GrowSnake PROC
		inc snakeDim
		ret
	GrowSnake ENDP

	; CheckSelfCollision - Check if snake head collided with its own body
	CheckSelfCollision PROC
		push r12
		
		; If snake length is 4 no body to collide with
		mov rax, snakeDim
		cmp rax, 4
		jle SelfCollisionEnd
		
		; Get head position
		movzx r8, snakeHeadX
		movzx r9, snakeHeadY
		
		; Loop through body segments
		mov r12, 1

	CheckSelfLoop:
		mov rax, snakeDim
		cmp r12, rax
		jge SelfCollisionEnd
		
		; Calculate offset: index * 4
		mov rax, r12
		shl rax, 2
		
		; Get body segment position
		movzx rcx, word ptr [snakeBody + rax] ; Segment X
		movzx rdx, word ptr [snakeBody + rax + 2] ; Segment Y
		
		; Compare with head position
		cmp r8, rcx ; Compare X
		jne NotThisSegment
		cmp r9, rdx ; Compare Y
		jne NotThisSegment
		
		; Collision detected
		mov gameOver, 1
		jmp SelfCollisionEnd

	NotThisSegment:
		inc r12
		jmp CheckSelfLoop

	SelfCollisionEnd:
		pop r12
		ret
	CheckSelfCollision ENDP

	; ConvertScoreToString - Convert score to string
	; Input: RAX = score
	; Output: scoreBuffer containing string
	; Returns: RCX = string length
	ConvertScoreToString PROC
		push rbx
		push rdi
		push r12
		push r13
		
		mov r13, rax ; SAVE the score value from RAX parameter
		
		; Clear the buffer
		mov rcx, 20
		lea rdi, scoreBuffer
		mov al, 0
		rep stosb
		
		; When score = 0
		test r13, r13  ; Use saved value not global score
		jnz NotZero
		
		lea rdi, scoreBuffer
		mov byte ptr [rdi], '0'
		mov rcx, 1
		jmp ConvertDone

	NotZero:
		; Convert number to string
		lea rdi, scoreBuffer
		mov rbx, 10 ; Divisor
		xor r12, r12 ; Digit counter
		
		mov rax, r13  ; Use saved value not global score

	ConvertLoop:
		xor rdx, rdx
		div rbx ; Divide by 10 (remainder in RDX)
		add dl, '0' ; Convert to ASCII
		mov [rdi + r12], dl ; Store digit
		inc r12 ; Count digit
		
		test rax, rax ; Check if done
		jnz ConvertLoop
		
		; Reverse the string
		mov rcx, r12 ; String length
		shr r12, 1 ; Divide by 2
		lea rdi, scoreBuffer
		lea rsi, scoreBuffer
		add rsi, rcx
		dec rsi ; Point to last char
		
	ReverseLoop:
		test r12, r12
		jz ConvertDone
		
		; Swap characters
		mov al, [rdi]
		mov bl, [rsi]
		mov [rdi], bl
		mov [rsi], al
		
		inc rdi
		dec rsi
		dec r12
		jmp ReverseLoop

	ConvertDone:
		pop r13
		pop r12
		pop rdi
		pop rbx
		ret
	ConvertScoreToString ENDP

	; DisplayScore - Display current score
	DisplayScore PROC
		mov rcx, 82
		mov rdx, 1
		call SetCursorPosition
		
		; Write score label
		sub rsp, 40
		
		mov rcx, consoleHandle
		lea rdx, scoreLabel
		mov r8, scoreLabelLen
		lea r9, bytesWritten
		mov qword ptr [rsp+32], 0
		
		call WriteConsoleA
		
		add rsp, 40
		
		; Convert score to string
		mov rax, score
		call ConvertScoreToString
		
		; Write the score number
		sub rsp, 40
		
		mov r8, rcx ; move length

		mov rcx, consoleHandle
		lea rdx, scoreBuffer
		lea r9, bytesWritten
		mov qword ptr [rsp+32], 0
		
		call WriteConsoleA
		
		add rsp, 40
		
		ret
	DisplayScore ENDP

	; UpdateScore - Update score when snake moves
	UpdateScore PROC
		; Score = snake length * number of steps taken
		mov rax, snakeDim
		add score, rax
		ret
	UpdateScore ENDP

	; ClearScreen - Clear entire console screen
	ClearScreen PROC
		push r12
		push r13
		
		mov r12, 0 ; Y counter
		
	ClearScreenRowLoop:
		cmp r12, 25
		jge ClearScreenDone
		
		mov r13, 0 ; X counter
		
	ClearScreenColLoop:
		cmp r13, 80
		jge ClearScreenRowDone
		
		; Write space character at each position
		mov rcx, r13
		mov rdx, r12
		call SetCursorPosition
		
		lea rcx, spaceChar
		call DrawChar
		
		inc r13
		jmp ClearScreenColLoop
		
	ClearScreenRowDone:
		inc r12
		jmp ClearScreenRowLoop
		
	ClearScreenDone:
		pop r13
		pop r12
		ret
	ClearScreen ENDP

	; WriteStringAt - Write string at position
	; Params: RCX = X position, RDX = Y position, R8 = address of string
	WriteStringAt PROC
		push r12
		push r13
		push r14
		
		; Save params
		mov r12, rcx
		mov r13, rdx
		mov r14, r8
		
		; Position cursor
		mov rcx, r12
		mov rdx, r13
		call SetCursorPosition
		
		; Calculate string length
		mov rdi, r14
		xor rcx, rcx
		
	StrLenLoop:
		mov al, byte ptr [rdi + rcx]
		test al, al
		jz StrLenDone
		inc rcx
		jmp StrLenLoop
		
	StrLenDone:
		; RCX now has length
		
		; Write string
		sub rsp, 40
		
		mov r8, rcx ; Length
		mov rcx, consoleHandle
		mov rdx, r14 ; String address
		lea r9, bytesWritten
		mov qword ptr [rsp+32], 0
		
		call WriteConsoleA
		
		add rsp, 40
		
		pop r14
		pop r13
		pop r12
		ret
	WriteStringAt ENDP

	; DrawMenu - Draw the menu screen
	DrawMenu PROC
		call ClearScreen
		
		; Draw title
		mov rcx, 0
		mov rdx, 2
		lea r8, titleLine1
		call WriteStringAt
		
		mov rcx, 0
		mov rdx, 3
		lea r8, titleLine2
		call WriteStringAt
		
		; Check if first time or next game
		mov rax, hasPlayedOnce
		test rax, rax
		jnz DrawPostGameMenu
		
		; Draw initial menu
		mov rcx, 0
		mov rdx, 5
		lea r8, groupTitle
		call WriteStringAt
		
		mov rcx, 0
		mov rdx, 6
		lea r8, member1
		call WriteStringAt
		
		mov rcx, 0
		mov rdx, 7
		lea r8, member2
		call WriteStringAt
		
		mov rcx, 0
		mov rdx, 8
		lea r8, member3
		call WriteStringAt
		
		; Draw menu options
		call DrawMenuOptions
		jmp DrawMenuEnd
		
	DrawPostGameMenu:
		; Draw scores
		mov rcx, 0
		mov rdx, 5
		lea r8, highScoreText
		call WriteStringAt
		
		; Draw high score number
		mov rax, highScore
		call ConvertScoreToString
		mov r10, rcx
		
		sub rsp, 40
		mov rcx, consoleHandle
		lea rdx, scoreBuffer
		mov r8, r10
		lea r9, bytesWritten
		mov qword ptr [rsp+32], 0
		call WriteConsoleA
		add rsp, 40
		
		; Draw your score label
		mov rcx, 0
		mov rdx, 6
		lea r8, yourScoreText
		call WriteStringAt
		
		; Draw your score number
		mov rax, lastScore
		call ConvertScoreToString
		mov r10, rcx
		
		sub rsp, 40
		mov rcx, consoleHandle
		lea rdx, scoreBuffer
		mov r8, r10
		lea r9, bytesWritten
		mov qword ptr [rsp+32], 0
		call WriteConsoleA
		add rsp, 40
		
		; Draw menu options
		call DrawMenuOptions
		
	DrawMenuEnd:
		; Draw navigation help
		mov rcx, 0
		mov rdx, 15
		lea r8, navHelp
		call WriteStringAt
		
		ret
	DrawMenu ENDP

	; DrawMenuOptions - Draw menu options
	DrawMenuOptions PROC
		push r12
		push r13
		
		; Determine Y starting position based on hasPlayedOnce
		mov rax, hasPlayedOnce
		test rax, rax
		jz FirstTimeMenu
		
		; Next game menu position
		mov r12, 9
		jmp DrawOptions
		
	FirstTimeMenu:
		; Initial menu position
		mov r12, 11
		
	DrawOptions:
		; Option 1: PLAY / PLAY AGAIN
		mov r13, r12 ; save Y pos
		
		; Draw arrow or space
		mov rcx, 0
		mov rdx, r13
		mov rax, menuSelection
		test rax, rax
		jnz NotPlaySelected
		lea r8, menuArrow
		jmp DrawPlayArrow
	NotPlaySelected:
		lea r8, menuSpace
		
	DrawPlayArrow:
		call WriteStringAt
		
		; Draw PLAY or PLAY AGAIN
		mov rcx, 6 ; X position after arrow/space
		mov rdx, r13 ; Same Y
		mov rax, hasPlayedOnce
		test rax, rax
		jz DrawPlay
		lea r8, menuPlayAgain
		jmp DrawPlayText
	DrawPlay:
		lea r8, menuPlay
	DrawPlayText:
		call WriteStringAt
		
		; Option 2: HOW TO PLAY
		inc r12
		mov r13, r12
		
		; Draw arrow or space
		mov rcx, 0
		mov rdx, r13
		mov rax, menuSelection
		cmp rax, 1
		jne NotInstSelected
		lea r8, menuArrow
		jmp DrawInstArrow
	NotInstSelected:
		lea r8, menuSpace
		
	DrawInstArrow:
		call WriteStringAt
		
		; Draw HOW TO PLAY
		mov rcx, 6
		mov rdx, r13
		lea r8, menuInstructions
		call WriteStringAt
		
		; Option 3: EXIT
		inc r12
		mov r13, r12
		
		; Draw arrow or space
		mov rcx, 0
		mov rdx, r13
		mov rax, menuSelection
		cmp rax, 2
		jne NotExitSelected
		lea r8, menuArrow
		jmp DrawExitArrow
	NotExitSelected:
		lea r8, menuSpace
		
	DrawExitArrow:
		call WriteStringAt
		
		; Draw EXIT
		mov rcx, 6
		mov rdx, r13
		lea r8, menuExit
		call WriteStringAt
		
		pop r13
		pop r12
		ret
	DrawMenuOptions ENDP

	; WaitForKeyRelease - Wait until specific key is released
	; Params: RCX = key code
	WaitForKeyRelease PROC
		push r12
		mov r12, rcx ; Save key code
		
	WaitReleaseLoop:
		sub rsp, 32
		mov rcx, r12 ; Use saved key code
		call GetAsyncKeyState
		add rsp, 32
		
		test ax, 8000h ; Check if still pressed
		jnz WaitReleaseLoop ; If yes keep waiting
		
		pop r12
		ret
	WaitForKeyRelease ENDP

	; MenuInput - Handle menu input
	; Returns: RAX = 1 if Enter pressed, 0 if not
	MenuInput PROC
		sub rsp, 32
		
		; Check Down arrow
		mov rcx, 28h
		call GetAsyncKeyState
		test ax, 8000h
		jz CheckUpArrow
		
		; Move selection down
		mov rax, menuSelection
		inc rax
		cmp rax, 3 ; Wrap around (0, 1, 2)
		jl NoWrapDown
		xor rax, rax ; Wrap to 0
	NoWrapDown:
		mov menuSelection, rax
		
		; Wait for key release to prevent scrolling through whole menu milion times
		mov rcx, 28h
		call WaitForKeyRelease
		
		; Redraw menu with new selection
		call DrawMenuOptions
		
		xor rax, rax ; Return 0 (not Enter)
		jmp MenuInputEnd
		
	CheckUpArrow:
		; Check Up arrow
		mov rcx, 26h
		call GetAsyncKeyState
		test ax, 8000h
		jz CheckEnter
		
		; Move selection up
		mov rax, menuSelection
		dec rax
		cmp rax, 0
		jge NoWrapUp
		mov rax, 2 ; Wrap to 2
	NoWrapUp:
		mov menuSelection, rax
		
		; Wait for key release
		mov rcx, 26h
		call WaitForKeyRelease
		
		; Redraw menu
		call DrawMenuOptions
		
		xor rax, rax ; Return 0 (not Enter)
		jmp MenuInputEnd
		
	CheckEnter:
		; Check Enter key
		mov rcx, 0Dh
		call GetAsyncKeyState
		test ax, 8000h
		jz NoInput
		
		; Wait for release
		mov rcx, 0Dh
		call WaitForKeyRelease
		
		mov rax, 1 ; Return 1 (Enter pressed)
		jmp MenuInputEnd
		
	NoInput:
		xor rax, rax ; Return 0
		
	MenuInputEnd:
		add rsp, 32
		ret
	MenuInput ENDP

	; ShowInstructions - Display instructions
	ShowInstructions PROC
		call ClearScreen
		
		; Draw title
		mov rcx, 0
		mov rdx, 5
		lea r8, instTitle
		call WriteStringAt
		
		mov rcx, 0
		mov rdx, 6
		lea r8, titleLine2
		call WriteStringAt
		
		; Draw instruction lines
		mov rcx, 0
		mov rdx, 8
		lea r8, instLine1
		call WriteStringAt
		
		mov rcx, 0
		mov rdx, 9
		lea r8, instLine2
		call WriteStringAt
		
		mov rcx, 0
		mov rdx, 10
		lea r8, instLine3
		call WriteStringAt
		
		mov rcx, 0
		mov rdx, 12
		lea r8, instLine4
		call WriteStringAt
		
		; Wait for any key press
	WaitForKey:
		sub rsp, 32
		mov rcx, 10
		call Sleep
		add rsp, 32
		
		; Check for any key
		; I did not have time to check every key so just few common ones
		sub rsp, 32 
		mov rcx, 0Dh ; Enter
		call GetAsyncKeyState
		add rsp, 32
		test ax, 8000h
		jnz KeyPressed
		
		sub rsp, 32
		mov rcx, 1Bh ; Escape
		call GetAsyncKeyState
		add rsp, 32
		test ax, 8000h
		jnz KeyPressed
		
		sub rsp, 32
		mov rcx, 20h ; Space
		call GetAsyncKeyState
		add rsp, 32
		test ax, 8000h
		jnz KeyPressed
		
		jmp WaitForKey
		
	KeyPressed:
		; Wait for release
		sub rsp, 32
		mov rcx, 200
		call Sleep
		add rsp, 32
		
		ret
	ShowInstructions ENDP

	; InitGame - Initialize/reset game state for new game
	InitGame PROC
		; Reset game variables
		mov gameOver, 0
		mov direction, 3 ; Start moving right
		
		; Reset snake position
		mov snakeHeadX, 40
		mov snakeHeadY, 12

		; Rendom initial direction
		sub rsp, 32
		call rand
		add rsp, 32

		and rax, 3
		mov direction, rax

		mov rax, startSpeed
		mov gameSpeed, rax

		; Reset score
		mov score, 0
		
		; Reset snake
		call InitSnake
		
		ret
	InitGame ENDP

	; DisplayLength - Display current snake length
	DisplayLength PROC
		mov rcx, 82
		mov rdx, 2
		call SetCursorPosition
		
		; Write "Length: " label
		sub rsp, 40
		
		mov rcx, consoleHandle
		lea rdx, lengthLabel
		mov r8, lengthLabelLen
		lea r9, bytesWritten
		mov qword ptr [rsp+32], 0
		
		call WriteConsoleA
		
		add rsp, 40
		
		; Convert snake length to string
		mov rax, snakeDim
		call ConvertScoreToString
		
		; Write the length number
		sub rsp, 40
		
		mov r8, rcx ; Length of string
		mov rcx, consoleHandle
		lea rdx, scoreBuffer ; Reuse score buffer
		lea r9, bytesWritten
		mov qword ptr [rsp+32], 0
		
		call WriteConsoleA
		
		add rsp, 40
		
		ret
	DisplayLength ENDP
END
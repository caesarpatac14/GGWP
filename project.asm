TITLE PROJECT_131 (GGWP)
.MODEL MEDIUM

;--------------------------------------

.DATA
	GAME_TITLE DB 'title.txt$', 00H
	HELP_FILE DB 'help.txt', 00H
	GAME_SCREEN_FILE DB 'screen.txt', 00H
	DICTIONARY DB 'words.txt', 00H
	END_GAME DB 'over.txt', 00H
	;PICTURE_FILE DB 'images.txt', 00H
	;ANSWER_FILE DB 'answers.txt', 00H

	;PICTURES DB 2 DUP ('$'), 00H
	;ANSWERS DB 20 DUP ('$'), 00H
	PICTURES DB 'A', 00H
	ANSWER DB 'BUTTERFLY$'
	GUESS DB 20 DUP ('$')

	TITLE_FULL DB 'G u e s s i n g  G a m e  W i t h  P i c t u r e$'
	START_GAME DB 'START$'
	HELP_GAME DB 'HELP$'
	QUIT_GAME DB 'QUIT$'
	BACK_MAIN DB 'BACK$'
	CREDIT_VIEW DB 'CREDITS$'
	ARROW DB '>>>$'
	REV_ARROW DB '<<<$'
	PHASE_ARROW DB 'V$'
	CREATOR DB 'By: jcpatac$'
	
	TITLE_HEADING DB 501 DUP ('$')
	TITLE_POS DW 0300H
	TITLE_POS2 DW 0B10H
	TITLE_LEN DW 500
	HELP_TXT DB 901 DUP ('$')
	HELP_LEN DW 900
	GAME_SCR DB 1111 DUP ('$')
	GAME_SCR_LEN DW 1110
	FINISH DB 601 DUP ('$')
	TEXT DB 100 DUP ('$')
	TEXT_CPY DB 100 DUP ('$')
	CHAR DB ?
	WORD_POS DW ?
	LEN DB 0
	PICTURE DB 1001 DUP ('$')

	PICTURE_COVER1 DW 0300H
	PICTURE_COVER2 DW 104FH

	START_POS DW 0F26H
	HELP_POS DW 1126H
	QUIT_POS DW 1326H
	ARROW_POS DW 0F21H
	HIDE_CURSOR DW 2052H
	INPUT_CURSOR1 DW 160CH
	INPUT_CURSOR2 DW 170CH
	HIDE DB '$'

	PLAYER_IN DB 2 DUP ('$')
	WORD_IN DB 50 DUP ('$')
	SEARCH DB 50 DUP ('$')

	KEY_INPUT DB 0
	SELECTION DB 0
	SCREEN_STATUS DB 0

	SCORE DW 0
	SCORE_STR DB 7 DUP ('$')
	SCORE_ADDER DW 100

	LIFE DB '3$'

	FILEHANDLE DW ?

;--------------------------------------

.CODE

DISPLAY MACRO ARGS
	MOV AH, 09H
	LEA DX, ARGS
	INT 21H
ENDM

;--------------------------------------

CURSOR_SET MACRO POS, MSG
	MOV DX, POS
	PUSH DX
	CALL SET_CURSOR
	DISPLAY MSG
ENDM

;--------------------------------------

CLEAR_SCREEN MACRO UL, LR
	MOV AX, 0600H
	MOV BH, 02H
	;MOV BH, E2H
	MOV CX, UL
	MOV DX, LR
	INT 10H
ENDM

;--------------------------------------

OPEN_FILE MACRO FILE_NAME
	MOV AH, 3DH
	MOV AL, 00
	LEA DX, FILE_NAME
	INT 21H
	MOV FILEHANDLE, AX
ENDM

READ_FILE MACRO FILE, DEST, LEN
	OPEN_FILE FILE

	MOV AH, 3FH
	MOV BX, FILEHANDLE
	MOV CX, LEN
	LEA DX, DEST
	INT 21H

	MOV AH, 3EH
	MOV BX, FILEHANDLE
	INT 21H
ENDM

;--------------------------------------

RANDOMIZE MACRO LOWERBOUND, UPPERBOUND, CONTAINER
	MOV AH, 00H ;interrupt to get system time 
	INT 1AH

	MOV AX, DX ;set seed (declared as global var) to dl

	XOR DX, DX ;clear dx
	XOR CH, CH ;clear ch
	MOV CX, UPPERBOUND ;set cl to upperbound parameter initially
	SUB CX, LOWERBOUND ;subtract cl to get the range of possible values
	DIV CX ;finally, divide ax with cx

	MOV AX, DX ;dl contains the remainder of the division
	ADD AX, LOWERBOUND ;add the lowerbound to al to include it in the chances of selection
	MOV CONTAINER, AX ;store to the container the randomized number
ENDM

;--------------------------------------

MAIN PROC FAR
	MOV AX, @data
	MOV DS, AX

	CALL MAIN_MENU

MAIN ENDP

;--------------------------------------

MAIN_MENU PROC NEAR
	MOV AL, 3
	ADD AL, '0'
	MOV LIFE, AL
	MOV SCORE, 0
	MOV SCREEN_STATUS, 0 ; SET THE SCREEN STATUS AS MAIN MENU (0)
	CLEAR_SCREEN 0000H, 184FH ; CLEAR WHOLE SCREEN

	READ_FILE GAME_TITLE, TITLE_HEADING, TITLE_LEN
	CURSOR_SET TITLE_POS, TITLE_HEADING
	CURSOR_SET TITLE_POS2, TITLE_FULL

	CURSOR_SET ARROW_POS, ARROW
	CURSOR_SET START_POS, START_GAME
	CURSOR_SET HELP_POS, HELP_GAME
	CURSOR_SET QUIT_POS, QUIT_GAME

	CURSOR_SET 1843H, CREATOR ; SET THE CURSOR TO THE BOTTOM LEFT

	LOOP_MAIN:
		CALL GET_KEY
		CALL CHECK_KEY
		CURSOR_SET HIDE_CURSOR, HIDE
		JMP LOOP_MAIN

MAIN_MENU ENDP

;--------------------------------------

GET_KEY PROC NEAR
	MOV AH, 01H
	INT 16H

	JZ IGNORE_THIS

	MOV AH, 00H
	INT 16H

	MOV KEY_INPUT, AH

	IGNORE_THIS:
		RET
GET_KEY ENDP

;--------------------------------------
IN_HELP PROC NEAR
	CMP KEY_INPUT, 4BH ; CHECK IF KEY IS LEFT ARROW
	JE GO_LEFT

	CMP KEY_INPUT, 4DH ; CHECK IF KEY IS RIGHT ARROW
	JE GO_RIGHT

	CMP KEY_INPUT, 1CH ; CHECK IF KEY IS RETURN (ENTER)
	JE HELP_OPT

	JMP STOP

	GO_LEFT:
		MOV AL, SCREEN_STATUS
		CMP AL, 1 ; CHECK IF SCREEN_STATUS IS VIEW_HELP (1)
		JL STOP
		CLEAR_SCREEN 0141H, 0144H ; CKEAR WHOLE SCREEN
		MOV SELECTION, 3 ; SET THE CURRENT SELECTION TO BACK TO MAIN (3)
		CURSOR_SET 0108H, REV_ARROW ; SET THE ARROW INDICATOR TO THE LEFT
		MOV KEY_INPUT, 0 ; RESET TO DEFAULT (NULL)
		JMP STOP

	GO_RIGHT:
		MOV AL, SCREEN_STATUS
		CMP AL, 1 ; CHECK IF SCREEN STATUS IS IN VIEW HELP (1)
		JL STOP
		CLEAR_SCREEN 0108H, 010BH ; CLEAR A PART OF SCREEN FOR ARROW INDICATOR
		MOV SELECTION, 4 ; SET THE CURRENT SELECTION TO VIEW CREDIT (4)
		CURSOR_SET 0141H, ARROW ; PLACE THE INDICATOR TO THE RIGHT PART
		MOV KEY_INPUT, 0
		JMP STOP

	TO_MAIN:
		MOV KEY_INPUT, 0 ; RESET KEY (NULL)
		MOV SELECTION, 0 ; RESET SELECTION
		CALL RESET
		JMP MAIN_MENU

	HELP_OPT:
		MOV AL, SELECTION
		CMP AL, 3 ; CHECK IF CURRENT SELECTION IS BACK TO MAIN (3)
		JE TO_MAIN

	STOP:
		RET
IN_HELP ENDP

;--------------------------------------

CHECK_KEY PROC NEAR
	CALL IN_HELP

	CMP KEY_INPUT, 48H ; CHECK IF KEY IS ARROW UP
	JE GO_UP

	CMP KEY_INPUT, 50H ; CHECK IF KEY IS ARROW DOWN
	JE GO_DOWN

	CMP KEY_INPUT, 1CH ; CHECK IF PRESSED KEY IS RETURN (ENTER)
	JE SELECT_OPT

	JMP RETURN

	GO_UP:
		MOV AL, SELECTION
		CMP AL, 0 ; CHECK IF CURRENT SELECTION IS IN PLAY GAME (0)
		JE RETURN
		MOV AL, SCREEN_STATUS
		CMP AL, 0 ; CHECK IF SCREEN STATUS IS IN MAIN MENU (0)
		JG RETURN
		CLEAR_SCREEN 0F21H, 1324H ; CLEAR SPECIFIC AREA IN SCREEN FOR INDICATOR POSITIONING
		SUB ARROW_POS, 0200H ; USEFUL FOR INDICATOR MOVEMENTS
		DEC SELECTION
		CURSOR_SET ARROW_POS, ARROW
		MOV KEY_INPUT, 0 ; SET THE INPUT KEY TO NULL (0)

	RETURN:
		RET

	GO_DOWN:
		MOV AL, SELECTION
		CMP AL, 2
		JE RETURN
		MOV AL, SCREEN_STATUS
		CMP AL, 0
		JG RETURN
		CLEAR_SCREEN 0F21H, 1324H ; CLEAR SPECIFIC AREA IN SCREEN FOR INDICATOR POSITIONING
		ADD ARROW_POS, 0200H ; USEFUL FOR INDICATOR MOVEMENTS
		INC SELECTION
		CURSOR_SET ARROW_POS, ARROW
		MOV KEY_INPUT, 0 ; SET THE INPUT KEY TO NULL (0)
		JMP RETURN

	CALL_RETURN:
		JMP RETURN

	SELECT_OPT:
		MOV AL, SELECTION
		CMP AL, 2 ; COMPARE IF SELECTION IS QUIT (2)
		JE CALL_EXIT
		CMP AL, 1 ; COMPARE IF SELECTION IS VIEW HELP (1)
		JE VIEW_HELP
		CALL GAME_LOOP

	CALL_EXIT:
		JMP EXIT_PROG

	VIEW_HELP:
		MOV SCREEN_STATUS, 1 ; STATUS FOR VIEW HELP
		MOV SELECTION, 3 ; SELECTION IS SET TO BACK TO MAIN (3)
		CLEAR_SCREEN 0000H, 184FH ; CLEAR WHOLE SCREEN
		READ_FILE HELP_FILE, HELP_TXT, HELP_LEN
		CURSOR_SET 0000H, HELP_TXT
		CURSOR_SET 0103H, BACK_MAIN ; POSITION OF BACK TO MAIN HUD
		CURSOR_SET 0145H, CREDIT_VIEW ; POSITION OF VIEW CREDIT HUD
		CURSOR_SET 0108H, REV_ARROW ; DEFAULT POSTION OF STATE INDICATOR
		MOV KEY_INPUT, 0
		JMP CALL_RETURN

	EXIT_PROG:
		CALL EXIT
CHECK_KEY ENDP

;--------------------------------------

RESET PROC NEAR
	MOV ARROW_POS, 0F21H

	RET
RESET ENDP

;--------------------------------------

GUESS_PIC PROC NEAR
	HERE:
	LEA DI, GUESS
	ASK:
		MOV AH, 01H
		INT 21H
		CMP AL, 0DH
		JE ENTER
		MOV [DI], AL
		INC DI
		MOV AL, '$'
		MOV [DI], AL
		JMP ASK

	ENTER:
		;CURSOR_SET 172AH, ANSWER
		LEA SI, ANSWER
		LEA DI, GUESS
		CHECKING:
				MOV AL, [SI]
				MOV AH, [DI]
				CMP AH, '$'
				JE OKAY
				CMP AL, '$'
				JE WRONG
				CMP AH, AL
				JNE WRONG
				INC SI
				INC DI
				JMP CHECKING

	OKAY:
		CMP AL, '$'
		JNE WRONG

	CORRECT:
		MOV AX, SCORE_ADDER
		ADD SCORE, AX ; ADD CURRENT SCORE WITH CURRENT SCORE ADDER
		MOV SCORE_ADDER, 100 ; RESET SCORE ADDER TO 100
		MOV PICTURE_COVER1, 0300H ; RESET THE PICTURE COVER TO ORIG
		MOV PICTURE_COVER2, 104FH
		CALL GAME_LOOP
		JMP OOPS

	WRONG:
		DEC LIFE
		CLEAR_SCREEN 1632H, 164AH ; CLEAR A PART OF THE SCREEN
		CLEAR_SCREEN 0128H, 0129H
		CURSOR_SET 0128H, LIFE
		CURSOR_SET INPUT_CURSOR1, HIDE
		MOV SCREEN_STATUS, 2
		CMP LIFE, '0'
		JNE OOPS

	OVER:
		CLEAR_SCREEN 0000H, 184FH
		READ_FILE END_GAME, FINISH, 600
		CURSOR_SET 0600H, FINISH
		MOV KEY_INPUT, 0
		TURN:
			CALL GET_KEY
			CMP KEY_INPUT, 0
			JE TURN
			CALL MAIN_MENU
	
	OOPS:
		CALL INPUT_CHECK
GUESS_PIC ENDP

;--------------------------------------

INPUT_CHECK PROC NEAR ; CHECKS IF USER INPUT EXIST IN LETTER POOL OR A FUNCTIONALITY
	ASK_IN:
		MOV AH, 01H
		INT 21H
		MOV PLAYER_IN, AL
		LEA SI, TEXT_CPY
	L_STR:
		MOV AL, [SI]
		CMP AL, '$'
		JE CALL_INTERR
		MOV DL, PLAYER_IN
		CMP DL, 0DH
		JE SEARCH_WORD
		CMP DL, 09H
		JE SWITCH_VIEWS
		CMP AL, DL
		JE EQUAL
		JMP NOT_EQUAL

	SWITCH_VIEWS:
		CALL PHASE_CHECKER
		JMP ASK_IN

	CALL_INTERR:
		JMP INTERRUPT

	EQUAL:
		CLEAR_SCREEN INPUT_CURSOR1, INPUT_CURSOR2
		CURSOR_SET INPUT_CURSOR1, HIDE
		DISPLAY PLAYER_IN
		MOV BL, '*'
		MOV [SI], BL
		MOV BH, PLAYER_IN
		MOV [DI], BH
		INC DI
		MOV BH, '$'
		MOV [DI], BH
		INC INPUT_CURSOR1
		INC INPUT_CURSOR2
		JMP INTERRUPT

	SEARCH_WORD:
		CLEAR_SCREEN 1603H, 1625H ; CLEAR A PART OF THE SCREEN
		MOV INPUT_CURSOR1, 160CH
		MOV INPUT_CURSOR2, 170CH
		CALL WORD_SEARCH
		CURSOR_SET INPUT_CURSOR1, HIDE
		LEA SI, TEXT
		LEA DI, TEXT_CPY
		CALL COPY_TEXT
		LEA DI, WORD_IN
		MOV AL, '$'
		MOV [DI], AL
		JMP INTERRUPT

	NOT_EQUAL:
		CLEAR_SCREEN INPUT_CURSOR1, INPUT_CURSOR2
		CURSOR_SET INPUT_CURSOR1, HIDE
		INC SI
		JMP L_STR		

	INTERRUPT:
		RET
INPUT_CHECK ENDP

;--------------------------------------

PHASE_CHECKER PROC NEAR ; CHECK IF PHASE IS FORM WORD / GUESS PIC
	CMP SCREEN_STATUS, 3 ; CHECK IF PHASE IS GUESS WORD
	JE TO_LEFT

	CMP SCREEN_STATUS, 2 ; CHECK IF PHASE IS FORM WORD
	JE TO_RIGHT

	TO_LEFT:
		MOV SCREEN_STATUS, 2 ; SET PHASE TO FORM WORD
		CURSOR_SET INPUT_CURSOR1, HIDE
		JMP CEASE

	TO_RIGHT:
		MOV SCREEN_STATUS, 3 ; SET PHASE TO GUESS PIC
		CURSOR_SET 1632H, HIDE
		CALL GUESS_PIC

	CEASE:
		RET
PHASE_CHECKER ENDP

;--------------------------------------

GAME_LOOP PROC NEAR
	MOV SCREEN_STATUS, 2 ; SET SCREEN STATUS TO PLAYING (2)
	CLEAR_SCREEN 0000H, 184FH ;CLEAR FULLSCREEN
	READ_FILE GAME_SCREEN_FILE, GAME_SCR, GAME_SCR_LEN
	CURSOR_SET 0000H, GAME_SCR ;SET THE CURSOR TO TOP-LEFT (0:0)

	CURSOR_SET 0129H, LIFE

	CALL STR_SCORE
	CURSOR_SET 0149H, SCORE_STR ; RENDER SCORE

	CALL GET_WORD
	CURSOR_SET 140CH, TEXT ; SET THE TEXT TO ROW: 20 ; COL: 12
	CURSOR_SET 160CH, HIDE ; SET THE CURSOR TO ROW: 22 ; COL: 12
	
	LEA SI, TEXT
	LEA DI, TEXT_CPY
	CALL COPY_TEXT

	LEA DI, WORD_IN
	G_LOOP:
		CALL INPUT_CHECK
		JMP G_LOOP

	RET
GAME_LOOP ENDP

;--------------------------------------

WORD_SEARCH PROC NEAR ; SEARCH USER WORD IN DICTIONARY
	OPEN_FILE DICTIONARY
	LEA SI, SEARCH
	LINE_READ:
		MOV AH, 3FH ; READ FILE
		MOV BX, FILEHANDLE
		LEA DX, CHAR
		MOV CX, 1
		INT 21H

		CMP AX, 0
		JE END_F

		MOV AL, CHAR
		CMP AL, 0AH
		JE LF

		MOV [SI], AL
		INC SI

		JMP LINE_READ

		END_F:
			JMP EOF

	LF:
		LEA DX, SEARCH
		MOV AL, '$'
		MOV [SI], AL ; ADD A DELIMETER TO THE END OF THE WORD
		LEA SI, SEARCH
		LEA DI, WORD_IN
		ITERATE:
			MOV AL, [SI]
			MOV AH, [DI]
			CMP AH, '$'
			JE VALID
			CMP AL, '$'
			JE PROCEED
			CMP AH, AL
			JL HALT_
			JG PROCEED
			INC SI
			INC DI
			JMP ITERATE
			JMP SCORE_

		HALT_:
			JMP EOF

		PROCEED:
			MOV SI, DX ; START FROM THE BEGINNING OF BUFFER
			JMP LINE_READ

	VALID:
		INC SI
		MOV AL, [SI]
		CMP AL, '$'
		JNE PROCEED

	SCORE_:
		ADD SCORE, 2 ; ADD SCORE BY 2 EVERYTIME A WORD IS CORRECT
		SUB SCORE_ADDER, 5 ; BUT SUBTRACT SCORE ADDER BY 5
		CLEAR_SCREEN 0148H, 014FH ; CLEAR A PART OF SCREEN
		CALL STR_SCORE
		CURSOR_SET 0149H, SCORE_STR ; RENDER SCORE
		ADD PICTURE_COVER1, 0103H ; ADJUST THIS FOR REVEALING PICTURE
		SUB PICTURE_COVER2, 0103H ; ADJUST THIS FOR REVEALING PICTURE
		READ_FILE PICTURES, PICTURE, 1000 ; READ THE PICTURE WITH CHARACTERS OF ABOUT 1000
		CURSOR_SET 0300H, PICTURE
		CLEAR_SCREEN PICTURE_COVER1, PICTURE_COVER2 ; REVEAL PARTS OF PICTURE

	EOF:
		RET
WORD_SEARCH ENDP

;--------------------------------------

GET_WORD PROC NEAR
	RAND_WORD:
		RANDOMIZE 1, 58109, WORD_POS ; GENERATE A RANDOM NUMBER FROM 1-58109 (NUMBER OF WORDS IN DICTIONARY)
		;MOV WORD_POS, 3
		CALL READ_DICTIONARY
		LEA SI, TEXT
		CALL GET_LEN
		MOV AL, LEN
		CMP AL, 6 ; COMPARE TO MINIMUM NUMBER OF LETTERS
		JL RAND_WORD

	RET
GET_WORD ENDP

;--------------------------------------

READ_DICTIONARY PROC NEAR ; FILE READING LINE BY LINE (THROUGH EVERY CHAR)
	OPEN_FILE DICTIONARY
	LEA SI, TEXT
	READ_LINE:
		MOV AH, 3FH ; READ FILE
		MOV BX, FILEHANDLE
		LEA DX, CHAR
		MOV CX, 1
		INT 21H

		CMP WORD_POS, 0 ; CHECK IF COUNTER IS 0
		JE EO_FILE

		CMP AX, 0 ; CHECK IF EOF
		JE EO_FILE

		MOV AL, CHAR

		CMP AL, 0AH ; CHECK IF NEWLINE
		JE LINE_FEED

		MOV [SI], AL
		INC SI

		JMP READ_LINE

	LINE_FEED:
		DEC WORD_POS ; DECREMENT COUNTER
		LEA DX, TEXT
		MOV AL, '$'
		MOV [SI], AL ; ADD A DELIMETER TO THE END OF THE WORD
		MOV SI, DX ; START FROM THE BEGINNING OF BUFFER
		JMP READ_LINE

	EO_FILE:
		RET
READ_DICTIONARY ENDP

;--------------------------------------

STR_SCORE PROC NEAR ; CONVERT INT TO STRING
	LEA SI, SCORE_STR
	MOV AX, SCORE
	MOV BX, 10 ; DIVISOR
	MOV CX, 0
	CYCLE1:
		MOV DX, 0
		DIV BX
		PUSH DX
		INC CX
		CMP AX, 0
		JNE CYCLE1

	CYCLE2:
		POP DX
		ADD DL, '0' ; ADD STRING 0 TO CONVERT
		MOV [SI], DL
		INC SI
		LOOP CYCLE2

	RET
STR_SCORE ENDP

;--------------------------------------

GET_LEN PROC NEAR
	MOV LEN, 0
	STR_LOOP:
		MOV AL, [SI]
		CMP AL, '$' ; COMPARE IF CURRENT CHAR IS END OF THE WORD
		JE STOP_LOOP

		INC SI
		INC LEN
		JMP STR_LOOP

	STOP_LOOP:
		SUB LEN, 1 ; SUBTRACT 1 FOR THE DELIMETER
		RET
GET_LEN ENDP

;--------------------------------------

SET_CURSOR PROC NEAR
	POP BX
	POP DX
	PUSH BX
	MOV AH, 02H
	MOV BH, 00
	INT 10H

	RET
SET_CURSOR ENDP

;--------------------------------------

COPY_TEXT PROC NEAR
	ITER:
		MOV AL, [SI]
		CMP AL, '$'
		JE BREAK
		MOV [DI], AL
		INC SI
		INC DI
		JMP ITER
	BREAK:
		RET
COPY_TEXT ENDP

;--------------------------------------

EXIT PROC NEAR
	CLEAR_SCREEN 0000H, 1847H ; CLEAR WHOLE SCREEN
	CURSOR_SET 0000H, HIDE ; SET THE POSITION OF CURSOR
	MOV AH, 4CH ; EXIT
	INT 21H
EXIT ENDP

;--------------------------------------

END MAIN

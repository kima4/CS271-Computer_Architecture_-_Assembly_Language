TITLE Low-Level I/O Procedures     (Proj6_kima4.asm)

; Author: Alexander Kim
; Last Modified: 12/05/2020
; OSU email address: kima4@oregonstate.edu
; Course number/section:   CS271 Section 401
; Project Number: 6                Due Date: 12/06/2020
; Description: This is a program that prompts the user for 10 32-bit integers, processes the numbers, and displays the results.
;			   The program is introduced by displaying the names of the program and programmer, extra credit statement, 
;			   instructions, and description. The user is then prompted to enter a 32-bit integer. The program then determines
;			   whether or not the input is a valid number that can fit in a 32-bit integer. If not, the program reprompts the 
;			   user to enter another value. The prompts are numbered by number of valid inputs and the running subtotal of input
;			   values is diplayed after each valid input, as required by extra credit 1. After the user has entered 10 valid 
;			   numbers, the program displays the numbers in a list, as well as the sum of the numbers and average of the numbers.
;			   A parting message is then displayed and the program terminates.

INCLUDE Irvine32.inc


;---------------------------------------------------------------------------------------------------
; Name: mGetString
;
; Prompts the user for a string and saves the input
;
; Preconditions: EAX, ECX, and EDX should not be used as arguments
;
; Receives: prompt			= reference to the string to prompt the user
;			saveTo			= address where the input is to be saved
;			bufferSize		= number of characters to read from the user input
;			strLen			= number of characters the user entered
;
; Returns: saveTo			= user input string
;		   strLen			= number of character the user entered
;
;---------------------------------------------------------------------------------------------------
mGetString macro prompt, saveTo, bufferSize, strLen
	push	eax
	push	ecx
	push	edx

	;print the prompt
	mov		edx, prompt
	call	writestring

	;set up and call ReadString
	mov		edx, saveTo
	mov		ecx, bufferSize
	call	readstring

	;save the string length
	mov		strLen, eax

	pop		edx
	pop		ecx
	pop		eax
endm

;---------------------------------------------------------------------------------------------------
; Name: mDisplayString
;
; Prints the given string 
;
; Preconditions: EDX should not be used as the argument
;
; Receives: numAddress		= reference to the string to be printed
;
; Returns: none
;
;---------------------------------------------------------------------------------------------------
mDisplayString macro numAddress
	push	edx

	;set up and call WriteString
	mov		edx, numAddress
	call	writestring

	pop		edx
endm


;values for the maximum number of digits to be read from the user input and the number of entries the user is prompted for
MAXDIGITS		= 14
NUMENTRIES		= 10

.data
	
	;arrays for storing and manipulating user inputs
	userNum		byte	MAXDIGITS dup(?)
	numList		sdword	NUMENTRIES dup(?)
	
	;strings for program introduction and extra credit
	progTitle	byte	"Low-Level I/O Procedures by Alexander Kim",13,10,0
	extraC1		byte	"**EC: This program numbers each user input line and displays a running subtotal of the valid inputs.",13,10,0
	instruct	byte	"Please enter 10 signed decimal integers that are small enough to fit inside a 32-bit register.",13,10,0
	descript	byte	"The program will then display the list of entered numbers, their sum, and their average value.",13,10,0

	;strings for user prompts 
	prompt		byte	". Please enter a signed integer: ",0
	error		byte	"ERROR: The entered value was not a 32-bit signed integer.",13,10,0
	reprompt	byte	". Please try again: ",0

	;strings for displaying information about the inputs
	subtotalStr	byte	"The total value of the numbers so far is: ",0
	numListStr	byte	"You entered the following numbers:",13,10,0
	delim		byte	", ",0
	numSumStr	byte	"The sum of these numbers is: ",0
	numAvgStr	byte	"The rounded average of these numbers is: ",0
	
	;string for farewell message
	goodbye		byte	"Goodbye, an thank you for using this program.",13,10,0

.code
main PROC
	
	;print introduction statements
	push	offset progTitle
	push	offset extraC1
	push	offset instruct
	push	offset descript
	call	introduction

	;get user input data
	push	offset numList
	push	offset prompt
	push	offset error
	push	offset reprompt
	push	offset subtotalStr
	push	offset userNum
	push	MAXDIGITS
	push	NUMENTRIES
	call	getUserVals

	;maniupulate and display user input data
	push	offset numListStr
	push	offset delim
	push	offset numSumStr
	push	offset numAvgStr
	push	offset numList
	push	offset userNum
	push	NUMENTRIES
	call	processVals

	;print goodbye statement
	push	offset goodbye
	call	farewell

	Invoke ExitProcess,0	; exit to operating system
main ENDP


;---------------------------------------------------------------------------------------------------
; Name: introduction
;
; Prints the introduction statement containing the name of the program and programmer
;	as well as the extra credit statements and description of the program
;
; Preconditions: none
;
; Postconditions: none
;
; Receives: [ebp+20]		= reference to introduction string with program and programmer names
;			[ebp+16]		= reference to extra credit 1 string
;			[ebp+12]		= reference to instruction string
;			[ebp+8]			= reference to description string
;
; Returns: none
;
;---------------------------------------------------------------------------------------------------
introduction proc
	
	push	ebp
	mov		ebp, esp

	;print program and programmer names
	mDisplayString [ebp+20]
	call	crlf

	;print extra credit 1 statment
	mDisplayString [ebp+16]
	call	crlf

	;print program description and instructions
	mDisplayString [ebp+12]
	mDisplayString [ebp+8]
	call	crlf

	pop		ebp
	ret		16

introduction endp

;---------------------------------------------------------------------------------------------------
; Name: getUserVals
;
; Prompts the user for ten inputs and reprompts if the input is invalid. Displays number lining next to the prompts and the running subtotal of valid inputs.
;
; Preconditions: the array for storing user input is type SDWORD
;
; Postconditions: userNum may be modified
;
; Receives: [ebp+36]		= address of array to store user input
;			[ebp+32]		= reference to string for initial user prompt
;			[ebp+28]		= reference to string for error message for invalid inputs
;			[ebp+24]		= reference to string for user reprompt
;			[ebp+20]		= reference to string for displaying running subtotal
;			[ebp+16]		= address of empty string to manipulate user input
;			[ebp+12]		= maximum number of digits to pick up from user input
;			[ebp+8]			= number of inputs to get from user
;
; Returns: user inputs are stored in the provided array
;
;---------------------------------------------------------------------------------------------------
getUserVals proc uses eax ebx ecx edx esi edi
	
	;inputNum - the number of inputs the user is prompted for to use for line numbers
	;subtotal - the running subtotal of valid user inputs
	local inputNum:dword, subtotal:sdword
	pushfd

	;set loop counter and the destination and source registers
	mov		edi, [ebp+36]
	mov		esi, [ebp+16]
	mov		ecx, [ebp+8]

	;initialize local variables
	mov		subtotal, 0
	mov		inputNum, 0


_GetEntries:
	
	;increment the line number by 1 and print the number
	inc		dword ptr inputNum
	push	inputNum
	push	[ebp+16]
	call	writeVal

	;prompt the user for an input with the default prompt message
	push	[ebp+36]
	push	[ebp+32]
	push	esi
	push	[ebp+12]
	push	[ebp+8]
	call	readVal

	jmp		_GotVal

_NotValidEntry:
	
	;print error message
	mDisplayString [ebp+28]

	;reprint line number without incrementing
	push	inputNum
	push	[ebp+16]
	call	writeVal

	;reprompt the user for an input with the alternate prompt message
	push	[ebp+36]
	push	[ebp+24]
	push	[ebp+16]
	push	[ebp+12]
	push	[ebp+8]
	call	readVal

_GotVal:
	
	;-----------------------------------------------------------
	; the readVal process replaces the first byte of the userNum string with a question mark (?) if 
	;	the user input is invalid - this allows getUserVals to determine whether or not to reprompt
	;	the user with the error message and alternate prompt message
	;-----------------------------------------------------------
	mov		al, [esi]
	cmp		al, '?'
	je		_NotValidEntry

_ValidEntry:
	
	;determines if the program is on its last loop - if so, skip the last subtotal since the total is given anyways
	dec		ecx
	cmp		ecx, 0
	je		_FinishReading

	;print string for subtotal
	mDisplayString [ebp+20]

	;add the previous subtotal and new user input value to get the new subtotal
	mov		eax, [edi]
	mov		edx, subtotal
	add		edx, eax
	mov		subtotal, edx

	;print the new subtotal
	push	subtotal
	push	[ebp+16]
	call	writeVal
	call	crlf
	call	crlf

	;move to fill the next cell in the array and return to get user input
	add		edi, 4
	jmp		_GetEntries

_FinishReading:

	popfd
	ret		32

getUserVals endp


;---------------------------------------------------------------------------------------------------
; Name: readVal
;
; Prompts the user for input and determines whether the input is valid or not
;
; Preconditions: the array for storing user input is type SDWORD
;
; Postconditions: userNum may be modified
;
; Receives: [ebp+24]		= address of array cell to store user input
;			[ebp+20]		= reference to string for user prompt
;			[ebp+16]		= address of empty string to manipulate user input
;			[ebp+12]		= maximum number of digits to pick up from user input
;			[ebp+8]			= number of inputs to get from user
;
; Returns: user input is stored in the provided array cell
;
;---------------------------------------------------------------------------------------------------
readVal proc uses eax ebx ecx edx esi edi
	
	;strLen - length of the string the user input
	;convNum - the converted number
	;sign - used to allow for using the same process for positive and negative numbers
	local	strLen:dword, convNum:sdword, sign:sdword
	pushfd

	;initialize local variables
	mov		convNum, 0
	mov		sign, 1

	;print user prompt
	mGetString [ebp+20], [ebp+16], [ebp+12], strLen

	;save the beginning of the string
	push	esi

	;set loop counter and source register
	mov		esi, [ebp+16]
	mov		ecx, strLen
	
	;determine if the user input begins with a negative sign - if so, the value is negative and the negative sign should be ignored for processing numbers
	cmp		[esi], byte ptr '-'
	jne		_NoMinusSign
	mov		sign, -1
	lodsb
	dec		ecx
	jmp		_StrToNum

_NoMinusSign:

	;determines if the user input begins with a positive sign - if so, the value is positive and the positive sign should be ignored for processing numbers
	cmp		[esi], byte ptr '+'
	jne		_StrToNum
	lodsb
	dec		ecx

_StrToNum:

	;-----------------------------------------------------------
	; multiplies the current converted number by 10 to allow the next digit to be added
	;	if the value overflows, the user input is too large to fit in a 32-bit signed integer
	;	and is therefore not valid
	;-----------------------------------------------------------	
	mov		edx, 10
	mov		eax, convNum
	imul	edx
	jo		_NotValidEntry

	;store the new value
	mov		convNum, eax

	;subtract 48 from the ASCII value of the next character to get the numerical value of the character
	mov		ebx, 48
	sub		[esi], ebx

	;zero out EAX and make sure that the character is a number and not another symbol
	mov		eax, 0
	cmp		[esi], byte ptr 9
	jg		_NotValidEntry
	cmp		[esi], byte ptr 0
	jl		_NotValidEntry

	;-----------------------------------------------------------
	; load the number into AL and multiply it by 1 or -1, depending on the sign of the whole number
	;	add the number to the total converted number
	;-----------------------------------------------------------
	lodsb	
	mov		edx, sign
	imul	edx
	add		convNum, eax

	;repeat until the end of the string is reached
	loop	_StrToNum


	;-----------------------------------------------------------
	; multiplies the converted number by 1 or negative 1 and looks for overflows
	;	used to catch edge cases such as 2147483648 no being valid, but -2147483648 being valid
	;-----------------------------------------------------------;
	mov		eax, convNum
	mov		edx, sign
	imul	edx
	jo		_ValidEntry
	cmp		eax, 0
	jnge	_NotValidEntry

_ValidEntry:
	
	;pops ESI as required for the push at the beginning of this procedure
	pop		esi

	;stores the newly converted number in the designated array cell
	mov		eax, convNum
	mov		[edi], eax
	jmp		_FinishReading

_NotValidEntry:
	
	;inserts a question mark at the beginning of the string to alert getUserVals that the input was invalid
	pop		esi
	mov		[esi], byte ptr '?'

_FinishReading:

	popfd
	ret		20

readVal endp


;---------------------------------------------------------------------------------------------------
; Name: processVal
;
; Processes the user input to display the list of user inputs, as well as the sum and average of all of the numbers
;
; Preconditions: the array for storing user input is type SDWORD
;
; Postconditions: userNum may be modified
;
; Receives: [ebp+32]		= reference to string for displaying list of user input
;			[ebp+28]		= deliminators to insert between list elements
;			[ebp+24]		= reference to string for displaying sum of inputs
;			[ebp+20]		= reference to string for displaying average of inputs
;			[ebp+16]		= address of array to store user input
;			[ebp+12]		= address of empty string to manipulate strings
;			[ebp+8]			= number of inputs received from user
;
; Returns: none
;
;---------------------------------------------------------------------------------------------------
processVals proc uses eax ebx ecx edx esi edi
	
	;sum - the total sum of all valid user inputs
	local	sum:sdword
	pushfd

	;set loop counter and the destination and source registers
	mov		ecx, [ebp+8]
	mov		esi, [ebp+16]
	mov		edi, [ebp+32]

	;initialize sum
	mov		sum, 0

	;print string for listing valid user input values
	call	crlf
	mDisplayString [ebp+32]

_ListValues:
	
	;add the next number to the sum
	mov		eax, sum
	add		eax, [esi]
	mov		sum, eax

	;write the value of the next number
	push	[esi]
	push	[ebp+12]
	call	writeVal

	;determines if the program is on its last loop - if so, do not print the deliminator and proceed to displaying the sum
	cmp		ecx, 1
	je		_DisplaySum

	;print deliminator, move to next value in the array, and repeat
	mDisplayString [ebp+28]
	add		esi, 4
	loop	_ListValues

_DisplaySum:
	
	;print string for displaying sum
	call	crlf
	call	crlf
	mDisplayString [ebp+24]

	;print sum
	push	sum
	push	[ebp+12]
	call	writeVal

	;print string for displaying average
	call	crlf
	call	crlf
	mDisplayString [ebp+20]

	;calculate average by dividing the sum by the total number of user inputs
	mov		eax, sum
	mov		ebx, [ebp+8]
	cdq
	idiv	ebx

	;print average
	push	eax
	push	[ebp+12]
	call	writeVal
	call	crlf
	call	crlf

	popfd
	ret		28

processVals endp


;---------------------------------------------------------------------------------------------------
; Name: writeVal
;
; Writes a number stored as a 32-bit signed integer as a string
;
; Preconditions: the value given is a 32-bit signed integer
;
; Postconditions: none
;
; Receives: [ebp+12]		= value of the 32-bit integer to be converted
;			[ebp+8]			= reference to string for writing to
;
; Returns: integer is written as a string in the given reference
;
;---------------------------------------------------------------------------------------------------
writeVal proc uses eax ebx ecx edx esi edi

	;sign - used to allow for using the same process for positive and negative numbers
	local	sign:sdword


	;initialize sign
	mov		sign, 1
	
	;set up destination register and value to be converted
	mov		edi, [ebp+8]
	mov		eax, [ebp+12]



	;counter to determine length of string
	mov		ecx, 0

	;determines if the number is negative - if so, add 1 to the counter to make room for the negative sign
	cmp		eax, 0
	jnl		_NumToStr
	mov		sign, -1
	inc		ecx


_NumToStr:
	
	;divide number by 10 to get value of ones place
	mov		ebx, 10
	cdq
	idiv	ebx

	;save quotient
	push	eax

	;convert remainder to positive value and add 48 to get ASCII representation of numerical value and store in string
	mov		eax, edx
	imul	sign
	add		eax, 48
	stosb

	;retrieve quotient
	pop		eax

	;increment the counter
	inc		ecx

	;determine if there is no more to convert
	cmp		eax, 0
	jne		_NumToStr

	;if the number is negative, append a negative sign to the string
	cmp		sign, -1
	jne		_NoNegativeSign
	mov		al, '-'
	stosb

_NoNegativeSign:
	
	;append a null terminator to the string to prevent contamination from previous values
	mov		al, 0
	stosb

	;decrement ECX to exclude the null terminator
	dec		ecx

	;reverse the string since it is backwards
	push	[ebp+8]
	push	ecx
	call	reverseString

	;print the string
	mDisplayString [ebp+8]
	
	ret		8

writeVal endp


;---------------------------------------------------------------------------------------------------
; Name: reverseString
;
; Swaps the elements in a string to reverse the order
;
; Preconditions: the array is type BYTE
;
; Postconditions: none
;
; Receives: [ebp+12]		= address of first element in the string
;			[ebp+8]			= length of the string in bytes
;
; Returns: the elements in the string are in reversed order
;
;---------------------------------------------------------------------------------------------------
reverseString proc uses eax esi edi
	
	;value1 - holder for switching values
	local	value1:byte

	;set up pointers at the front and back of the string
	mov		esi, [ebp+12]
	mov		edi, [ebp+12]
	add		edi, [ebp+8]


_reverseLoop:
	
	;finish looping when the two pointers pass each other or are on the same value
	cmp		esi, edi
	jnl		_reverseFinish

	;move the front value to the holder variable
	mov		al, [esi]
	mov		value1, al

	;move the back value to the front
	mov		al, [edi]
	mov		[esi], al

	;move the front value from the holder variable to the back
	mov		al, value1
	mov		[edi], al

	;move pointers as appropriate
	add		esi, 1
	sub		edi, 1

	jmp		_reverseLoop

_reverseFinish:
	
	ret		8

reverseString endp


;---------------------------------------------------------------------------------------------------
; Name: farewell
;
; Prints the farewell statement
;
; Preconditions: none
;
; Postconditions: none
;
; Receives: [ebp+8]
;
; Returns: none
;
;---------------------------------------------------------------------------------------------------
farewell proc
	
	push	ebp
	mov		ebp, esp

	;print goodbye message
	mDisplayString [ebp+8]

	pop		ebp
	ret		4

farewell endp

END main

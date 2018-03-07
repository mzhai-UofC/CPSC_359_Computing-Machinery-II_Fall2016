.section    .init
.globl     _start

_start:
    b       main
    
.section .text

main:
    	mov     	sp, #0x8000 // Initializing the stack pointer
	bl		EnableJTAG // Enable JTAG
	bl		InitUART    // Initialize the UART
	
	ldr  r0, =creat               // print out the authors
	mov  r1, #41
	bl   WriteStringUART

loop:
	ldr  r0, =enterSize         
	mov  r1, #44
	bl   WriteStringUART

	ldr   r0, =ABuff            //Getting the size of the list from user
	mov   r1, #256	
	bl    ReadLineUART          
	
	cmp  r0, #1                  //check if the string is only one byte
	bne  invsize
	
	ldr	r0, =ABuff          // transfer the string to number
	ldrb	r9,[r0]
//--------------------check "q" or "Q"
	cmp r9, #81
	beq exit
	cmp r9, #113
	beq exit
//------------------------
   	sub	r9, #48
    
	cmp r9, #1                  //check if the size of the list is between 1 and 9
	blt  invsize
	cmp r9, #9
	bgt  invsize
	mov r3, #0            	// loop variable(loop counter)
	mov r4, #0          	 //store the user's input (individual number)

loop1:
	cmp  r3, r9                   
	bge  sort 

loop2:                         
//--------------------------  the loop enter all the numbers
	ldr  r0, =enterNumber    
	mov  r1, #26
	bl   WriteStringUART
  
	ldr	r0, =ABuff          //enter the number
	mov	r1, #256	
	bl	ReadLineUART

//-------------------------- check if the number is between 1 and 3 bytes
        cmp r0, #0                  
    	ble  invGrade
    	cmp r0, #3 
    	bgt invGrade
//-------------------------- 
    	ldr r1, =ABuff              // if the number is only one byte, transfer it to number
    	cmp  r0, #1
    	bne  else1  
	ldrb r5,[r1]
    	
//--------------------check "q" or "Q"
	cmp r5, #81
	beq exit
	cmp r5, #113
	beq exit

	sub  r5, #48
        cmp  r5, #0
        blt  Invformat              // check if the input numbers are number(right format)
        cmp  r5, #9
        bgt  Invformat
    	b    compare
 
else1:
    	cmp  r0, #2                 // if the number is two bytes, transfer it to integer number
    	bne  else2
    	ldrb r5,[r1]
   	sub r5, #48
        cmp  r5, #0
        blt  Invformat              // check if the input numbers are int number(right format)
        cmp  r5, #9
        bgt  Invformat
   	ldrb r6, [r1, #1]
    	sub  r6, #48
        cmp  r6, #0
        blt  Invformat              // check if the input numbers are int number(right format)
        cmp  r6, #9
        bgt  Invformat
    	mov  r7, #10
    	mul  r5, r7
    	add  r5, r6
    	b    compare

else2:
    	ldrb r5,[r1]                  // if the number is three bytes,transfer it to int number
    	sub r5, #48
        cmp  r5, #0
        blt  Invformat              // check if the input numbers are int number(right format)
        cmp  r5, #9
        bgt  Invformat
    	ldrb r6, [r1, #1]
    	sub  r6, #48
        cmp  r6, #0
        blt  Invformat              // check if the input numbers are  int number(right format)
        cmp  r6, #9
        bgt  Invformat
    	ldrb r7, [r1, #2]
    	sub  r7, #48
        cmp  r7, #0
        blt  Invformat              // check if the input numbers are int number(right format)
        cmp  r7, #9
        bgt  Invformat
    	mov  r8, #100 
    	mul  r5, r8
    	mov  r8, #10
    	mul  r6, r8
    	add  r5, r6
    	add  r5, r7
//-------------------------- 
compare:
	cmp  r5, #0                 // check if the number is between 0 and 100
	blt  invGrade
	cmp  r5, #100
	bgt  invGrade
	//b test
//-------------------------- 	   //store all the user's input into a initialized array numbers	
store:
	ldr  r1, =numbers	
	strb r5,[r1,r3]            //the input number is in r5, each time store r5 into a different address in r1 
	add	r3, #1		   //r3 is the loop counter(inc. r3)
	b  loop1		   //after store the value, go to loop1 to check if we need a new input

//-------------------------- error msg 
invGrade:
	ldr  r0, =invaildNumber       // print out the invalid information
	mov  r1, #57
	bl   WriteStringUART
	b    loop2
//-------------------------- sort method
sort:
	ldr r1, =numbers
	mov r4, #0		//r4 is a loop conter inside the sort loop	
Loop31:
	cmp r4, r9		//size stored in r9
	blt Loop41		
	b printLoop
Increase:
	add r4, #1
	b Loop31	
Loop41:	
	mov r5,	#0
	add r5, r4,#1 		//r5=r4+1
Loop21:
	cmp r5, r9
	bge Increase

	ldrb r2, [r1,r4]
	ldrb r3, [r1,r5]
	cmp r2,r3		//if r2 is biger than r3, swap their position
	bgt exchange
	add r5, #1
	b Loop21
//------------------------------swap the positions of the 2 registers
exchange:
	mov r7,r2
	mov r2,r3
	mov r3,r7
	strb r2,[r1,r4]
	strb r3,[r1,r5]
	add r5, #1
	b Loop21
//-------------------------- print out array
printLoop:
        ldr r4, =numbers
        mov r3, #0             //r3 is a loop counter inside the print loop
	ldr  r0, =printsort    //print the sentence "the sorted list is:"
	mov  r1, #23
	bl   WriteStringUART

        b print
printLoop1:  
       cmp r3, r9
       blt print
       b   Median

//-------------------------- print out array
print: 

	ldr r4, =numbers
	ldrb r5, [r4,r3]        //load the number stored in r4 to r5
//---------------------------Firstly, Transfer numbers into string
	mov r4, r5  
	mov r8,#0   
        sub  r2, r4, #100       //the number is in r4 (one number inputed from user each time)         
        cmp  r2, #0
        blt  done1
        mov  r5, r4
        mov  r8, #0
//--------------------------transfer the 3 bytes number into string and print out 
loop4:                           
        sub  r5, #100
        add  r8, #1
        cmp  r5, #0
        bge  loop4
        sub  r8, #1             //the first byte is in r8
        mov  r5, #100
        mul  r5, r8,r5
        sub  r2, r4, r5
        mov  r7, r2
        add  r8, #48  
        mov  r6, #0
loop5:
        sub  r2, #10
        add  r6, #1
        cmp  r2, #0
        bge  loop5
        sub  r6, #1            //the second byte is in r6
        mov  r5, #10
        mul  r5, r6, r5
        sub  r2, r7, r5
        add  r6, #48  
        add  r2, #48  
        mov  r7, r2            // the third byte is in r7       
           
        ldr  r0, =Buffer       //load the 3 bytes numbers into r0 in the correct order         
        strb r8,[r0]           //first byte in r0   
        strb r6,[r0, #1]       //second byte in r0+1
        strb r7,[r0, #2]       //third byte in r0+2     
        mov  r1, #3
        bl   WriteStringUART 
        
        mov  r5, #32           //creat a blank after every output number
        ldr  r0, =Buffer       //blank's ascii code is 32
        strb r5,[r0]	
        mov  r1, #1
        bl   WriteStringUART
       
        add r3, #1		//loop counter adds one
        b  printLoop1		//go back to printLoop1 to check if we have a new number to transfer
        
 //---------------------------transfer the two bytes number into string and print out 
done1:                           
        sub r2, r4, #10
        cmp r2, #0
        blt done2
        mov r5, r4
        mov r8, #0

loop6:
        sub  r5, #10
        add  r8, #1
        cmp  r5, #0
        bge  loop6
        sub  r8, #1               // the first byte is in r8           
        mov  r5, #10
        mul  r5, r8, r5
        sub  r2, r4, r5
        add  r8, #48 
        add  r2, #48  
        mov  r6, r2               // the second byte is in r6
        
	ldr  r0, =Buffer           //load the 3 bytes numbers into r0 in the correct order and print out the number
        strb r8,[r0]		   //first byte in r0 
        strb r6,[r0, #1]           //second byte in r0+1
        mov  r1, #2		   //the number's length
        bl   WriteStringUART 
        
        mov  r5, #32		   //creat a blank after every output number
        ldr  r0, =Buffer	   //blank's ascii code is 32
        strb r5,[r0]
        mov  r1, #1
        bl   WriteStringUART
        
        add  r3, #1 		  //loop counter adds one
        b printLoop1		  //go back to printLoop1 to check if we have a new number to transfer
//----------------------------transfer the one byte number into string and print out 
done2:	add  r5,  #48  	
        ldr  r0, =Buffer
        strb r5,[r0]
        mov  r1, #1
        bl   WriteStringUART


	mov  r5, #32	
        ldr  r0, =Buffer
        strb r5,[r0]
        mov  r1, #1
        bl   WriteStringUART

        add  r3, #1     		//loop counter adds one
        b  printLoop1			//go back to printLoop1 to check if we have a new number to transfer

//-------------------------- calculate the median
Median:
   ldr r4, =numbers
   tst r9, #1
   bne odd
   
   lsr r9, r9, #1
   ldrb r2, [r4,r9]
   sub  r9, #1
   ldrb r3, [r4,r9]
   add r2, r3

   //-----------------------if the sum of the two median numbers is odd, go to the branch printing the floating poaint
   lsr r5, r2, #1
   tst r2, #1
   bne printF
//--------------------------print out the median
printM:
	mov r4, r5  
	mov r8,#0   
        sub  r2, r4, #100       // median is in r4       
        cmp  r2, #0
        blt  doneM1
        mov  r5, r4
        mov  r8, #0
loopM4:                           // transfer the 3 bytes number into string and print out the sort
        sub  r5, #100
        add  r8, #1
        cmp  r5, #0
        bge  loopM4
        sub  r8, #1              // the first byte is in r8
        mov  r5, #100
        mul  r5, r8,r5
        sub  r2, r4, r5
        mov  r7, r2
        add  r8, #48  
        mov  r6, #0
loopM5:
        sub  r2, #10
        add  r6, #1
        cmp  r2, #0
        bge  loopM5
        sub  r6, #1            //the second byte is in r6
        mov  r5, #10
        mul  r5, r6, r5
        sub  r2, r7, r5
        add  r6, #48  
        add  r2, #48  
        mov  r7, r2            // the third byte is in r7       
             
       
        ldr  r0, =printMedian1
	mov  r1, #18
	bl   WriteStringUART 
	
	ldr  r0, =Buffer          //print out the median
        strb r8,[r0]
        strb r6,[r0, #1]
        strb r7,[r0, #2]        
        mov  r1, #3
        bl   WriteStringUART 
       
        b branch
 //----------------------------------------------------------- transfer the two bytes number into string and print out
doneM1:                           
        sub r2, r4, #10
        cmp r2, #0
        blt doneM2
        mov r5, r4
        mov r8, #0
loopM6:
        sub  r5, #10
        add  r8, #1
        cmp  r5, #0
        bge  loopM6
        sub  r8, #1               // the first byte is in r8           
        mov  r5, #10
        mul  r5, r8, r5
        sub  r2, r4, r5
        add  r8, #48 
        add  r2, #48  
        mov  r6, r2               // the second byte is in r6
        ldr  r0, =printMedian1
	mov  r1, #18
	bl   WriteStringUART 
	
	ldr  r0, =Buffer           //print out the median
        strb r8,[r0]
        strb r6,[r0, #1]        
        mov  r1, #2
        bl   WriteStringUART 
            
        b branch
//------------------------------------------------transfer the one byte number into string and print out
doneM2:	ldr  r0, =printMedian1
	mov  r1, #18
	bl   WriteStringUART 

	add  r5,  #48  	
        ldr  r0, =Buffer
        strb r5,[r0]
        mov  r1, #1
        bl   WriteStringUART

	
	
	b branch
//-------------------------------------the method for print the floating point
//-------------------------------------only if the size of the input number is even
//-------------------------------------and the sum of the two numbers in the middle is odd
printF:
	mov r4, r5  
	mov r8,#0   
        sub  r2, r4, #100       // median is in r4       
        cmp  r2, #0
        blt  doneF1
        mov  r5, r4
        mov  r8, #0
loopF4:                           // transfer the 3 bytes number into string and print out the sort
        sub  r5, #100
        add  r8, #1
        cmp  r5, #0
        bge  loopF4
        sub  r8, #1              // the first byte is in r8
        mov  r5, #100
        mul  r5, r8,r5
        sub  r2, r4, r5
        mov  r7, r2
        add  r8, #48  
        mov  r6, #0
loopF5:
        sub  r2, #10
        add  r6, #1
        cmp  r2, #0
        bge  loopF5
        sub  r6, #1            //the second byte is in r6
        mov  r5, #10
        mul  r5, r6, r5
        sub  r2, r7, r5
        add  r6, #48  
        add  r2, #48  
        mov  r7, r2            // the third byte is in r7  
	mov  r4, #46		//r4 and r5 are the floating point part
	mov  r5, #53   
             
        ldr  r0, =printMedian1
	mov  r1, #18
	bl   WriteStringUART 
	
	ldr  r0, =Buffer          //print out the median
        strb r8,[r0]
        strb r6,[r0, #1]
        strb r7,[r0, #2]  
	strb r4,[r0, #3]	//r4 and r5 are the floating point part
	strb r5,[r0, #4]  	//load r4 and r5 into the register r0
	     
        mov  r1, #5
        bl   WriteStringUART 
       
        b branch
 //----------------------------------------------------------- transfer the two bytes number into string and print out
doneF1:                           
        sub r2, r4, #10
        cmp r2, #0
        blt doneF2
        mov r5, r4
        mov r8, #0
loopF6:
        sub  r5, #10
        add  r8, #1
        cmp  r5, #0
        bge  loopF6
        sub  r8, #1               // the first byte is in r8           
        mov  r5, #10
        mul  r5, r8, r5
        sub  r2, r4, r5
        add  r8, #48 
        add  r2, #48  
        mov  r6, r2               // the second byte is in r6
	mov  r4, #46		//r4 and r5 are the floating point part
	mov  r5, #53     	//load r4 and r5 into the register r0
             

        ldr  r0, =printMedian1
	mov  r1, #18
	bl   WriteStringUART 
	
	ldr  r0, =Buffer           //print out the median
        strb r8,[r0]
        strb r6,[r0, #1] 
	strb r4,[r0, #2]	//r4 and r5 are the floating point part
	strb r5,[r0, #3]         
        mov  r1, #4
        bl   WriteStringUART 
            
        b branch
//------------------------------------------------transfer the one byte number into string and print out
doneF2:	ldr  r0, =printMedian1
	mov  r1, #18
	bl   WriteStringUART 

	add  r5,  #48 
	mov  r4, #46
	mov  r5, #53  
 	
        ldr  r0, =Buffer
        strb r5,[r0]
	strb r4,[r0, #1]
	strb r5,[r0, #2]
        mov  r1, #3
        bl   WriteStringUART
	
	b branch
//-------------------------------------------------if the size of the list is odd
odd:
   ldrb r2, [r4,r9]
   sub r9, #1
   lsr r9, r9 ,#1
   ldrb r5, [r4,r9]
   b printM  
        
//--------------------------branch is for reset the loop counter and go back to the starting stage
branch:
	mov r3, #0
        mov r5, #0
        b loop

//-------------------------- error msg
invsize:
	ldr  r0, =invalidSize       // print out the invalid information
	mov  r1, #68
	bl   WriteStringUART
	b    loop

//-------------------------- error msg
Invformat:
       ldr  r0, =invalidformat       // print out the invalid information
       mov  r1, #24
       bl   WriteStringUART
       b    loop2

//--------------------------when user input an "q" or "Q", exit the program

exit:  ldr  r0, =printExit       // print out the exit information
       mov  r1, #44
       bl   WriteStringUART
       b stop
//--------------------------stop the loop
stop:
		b stop
//--------------------------end
haltLoop$:
	b	haltLoop$

.section .data
//-----------------------initialize a space to store the input numbers
numbers:
      .skip 9*4
	
creat:
      .ascii	"\n\rCreated by: Muzhou,Zhai and Mingkun,He\n" 		

enterSize:
      .ascii	"\n\rPlease enter the size of the number list:\n"

enterNumber:
       .ascii	"\n\rPlease enter the number:\n"

invaildNumber:
       .ascii	"\n\rInvalid number! The number should be between 0 and 100.\n"

invalidSize:
       .ascii	"\n\rInvalid number! The size of number list should be between 1 and 9.\n"

invalidformat:
       .ascii   "\n\rWrong number format! \n"

printsort:
       .ascii	"\n\rThe sorted list is: \n"

printMedian1:
       .ascii	"\n\rThe median is: \n "

printExit:
       .ascii   "\n\r----Program exit. Thanks for using!----- \n"

//-------------------------------for the UART get user's information
ABuff:
       .rept  256
       .byte 0
       .endr
//-------------------------------for the UART get user's information
Buffer:
       .rept  256
       .byte 0
       .endr


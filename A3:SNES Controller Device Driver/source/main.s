.section    .init
.globl     _start
 
_start:
    b       main
 
.section .text
main:
        mov     sp, #0x8000 // Initializing the stack pointer
        bl      EnableJTAG // Enable JTAG
        bl      InitUART    // Initialize the UART
	bl		InitFrameBuffer
//---------------------------clear screen
menu:	mov		r11, #0
	bl		ClearScreen
		
		
/*//---------------------------menu	

	  mov		r10, #0
	   ldr		r0, =Cover
		
	   mov		r4, #768//Width of  image
	   mov		r5, #1024//height of image
	
	  bl		DrawImage*/

		mov		r2, #600
		mov		r1, #200
		bl		ClearImage
		
		ldr		r0, =t1
		mov		r2, #484
		mov		r1, #200
		
		mov		r4, #96//Width of  image
		mov		r5, #96//height of image
		bl		DrawImage
 
        //creator names
        mov     r2, #12
        bl      printMsg     
        mov     r2, #13	   
        bl      printMsg
     
//--------------Initializing the 3 lines(latch line/clock line/data line)
        mov     r0, #9
        mov     r1, #1             //LATCH TO OUTPUT
        bl      Init_GPIO
     
        mov     r0, #11
        mov     r1, #1             //CLOCK TO OUTPUT
        bl      Init_GPIO
     
        mov     r0, #10
        mov     r1, #0             //DATA TO INPUT
        bl      Init_GPIO

//--------------The loop controls the program 
bigLoop:
        bl      Read_SNES
        //print the list of buttons pressed here
        bl      printList
        b       bigLoop

//--------------The loop that print strings declaring which button the user pressed
//--------------The user can press 2 more more buttons at a time
printList:
        push    {lr}
        mov     r5, #0			//r5 is the loop counter, initialize r5 with 0 before enter the printLoop
        printLoop:
        cmp     r5, #16			//compare the counter with the buttons size 16
        bgt     donePrint		//if the counter exceeds (equal to) the size, the loop finished
        ldr     r0, =buttons		//load buttons(user's input) tp r0
        ldr     r11, =isButtonHeld	//load the isButtonHeld to r11, 
					//the memory isButtonHeld is for thecase if user press 2 or more buttons at one time
       
        mov     r8, r5, lsl #2 		//r3 is the index, r3 = r5 * 4
        ldrb    r1, [r0, r8]		// load 0 to r1 from the certain address	
        cmp     r1, #0			//if r1 = 0, branch goto notPressed
        beq     notPressed		
        cmp     r5, #3 			//if user pressed start button, branch goto exitProgram
        beq     exitProgram		//the program will be terminated
        ldrb    r12, [r11, r8]		//load r12 from the index of r11		
        cmp     r12, #1			//if r12 = 1, the button is held, branch goto continue
        beq     continue
        mov     r12, #1			//if not, move 1 to r12
        strb    r12, [r11, r8]		//stroe the value back
        mov     r2, r5			//let r2 = r5
        bl      printMsg		//print the button that the user has pressed
        mov     r2, #13 		//print "please press a button..."
        bl      printMsg
        b       continue		//branch goto continue
 
        notPressed:			//if the button is not held, the user pressed one button at a time
        mov     r12, #0			//let r12 = 0
        strb    r12, [r11, r8]		//store the value back to r11(isButtonHeld)
        b       continue		//branch goto continue	

        continue:
        add     r5, #1			//r5(loop counter)+=1
        b       printLoop
 
        donePrint:     
        pop     {lr} 
 
Read_SNES:
        push    {lr}
     
        mov     r1, #1			//write GPIO (Write 1 to the clock)
        bl      Write_Clock
     
        mov     r1, #1
        bl      Write_Latch		//write GPIO (write 1 to the latch)
     
        mov     r1, #12			//the program has to wait for 12 us, that is the time signal from SENS to sample button
        bl      Wait
     
        mov     r1, #0			//write GPIO (write 0 to the latch)
        bl      Write_Latch
     
        mov     r5, #0			//r5 is the counter for the pulseLoop, so we set r5 to 0 each time before enter the loop

//--------------Start pulsing to read from SNES
pulseLoop:
        cmp     r5, #16                 //compare it with 16 (we have 16 buttons store in the data list)
        bge     donePulse		// if it is bigger or equal to 16, the loop done (branch go to donePulse) 
         
        mov     r1, #6			//the program has to wait for 6 us, that is the time for the half period of the CLOCK
        bl      Wait
     
        mov     r1, #0			//write GPIO (Write 0 to the clock)
        bl      Write_Clock
     
        mov     r1, #6			//the program has to wait for 6 us, that is the time for the half period of the CLOCK
        bl      Wait
         
        bl      Read_Data		//branch goto Read_Data

//------------- Read GPIO(data, buttons)
dataRead:     
        ldr     r0, =buttons		//buttons is a initialized memory stores the buttons value (16 linked with the buttons on SENS)
        mov     r6, r5, lsl #2		//r6=r5*4, 4 stands for 4 bytes for each integer, r5 is the counter 
        strb    r4, [r0, r6]		//store the input signal(number) 
     
        mov     r1, #1			//write GPIO (write 1 to the latch)
        bl      Write_Clock
     
        add     r5, #1			//r5+=1 after each loop

     
        b       pulseLoop		//branch goto pluseLoop

//-------------finish the pulseLoop    
donePulse:     
        pop {lr}
        bx    lr
 
//-------------function that read from the GPIO data line (pin #10)
Read_Data: 
        push    {r5,r6,r7,lr}
        ldr     r2, =0x3F200000		//base GPIO reg
        ldr     r1, [r2, #52]		//GPLEV0
        mov     r3, #1			//r3 = 1
        lsl     r3, #10			//align pin 10 bit
        and     r1, r3			//mask everything else
        cmp     r1, #0			//compare if r1 = 0
        moveq   r4, #1			//if equal, return 1 to r4
        movne   r4, #0			// if not equal, retuen 0 to r4
        pop     {r5,r6,r7,lr}
        bx      lr
 
//--------------function to initialize the GPIO lines     
//r0 contains the lineNumber
//r1 contains the function code
Init_GPIO:
        push {lr}
        mov     r2, r0  		//move pin# to r2
        ldr     r0, =0x3F200000 	//load r0 with base register
        //--------------find the address accrording to the pin
        loopReg:
                cmp     r2, #9		//compare the pin with 9
                subhi   r2, #10		//if r2 is smaller, substract 10 from r2
                addhi   r0, #4		//if r2 is greater, add 4 to the address
                bhi     loopReg		
 
        donereg:
        ldr     r4, [r0]		//copy GPFSEL into r4
        mov     r3, #7			//r3 = 111
        add     r2, r2, lsl #1		//r2 = r2 + r2 * 2, now r2 is the index number of 1st bit for the pin
        lsl     r3, r2			//align r3 for r2 bits 
        bic     r4, r3			//do the bit clear in r4 (in 3 bits)
        lsl     r1, r2			//align r1 for r2 bits
        orr     r4, r1			//set the pin's function in r1	
        str     r4, [r0]		//write back to GPFSEL
        pop     {lr}
        bx      lr
 
 
//--------------writing pin number 11
Write_Clock:
        push    {r4,r5,r6,r7,lr}
        ldr     r2, =0x3F200000		//load r2 with base register
        mov     r3, #1			//r3 = 1
        lsl     r3, #11			//align bit for pin#11
        cmp     r1, #0			//compare r1 with 0
        streq   r3, [r2, #40] 		//GPCLR0: write 0 to the clock
        strne   r3, [r2, #28] 		//GPCLR0: write 0 to the clock
        pop     {r4,r5,r6,r7,lr}
        bx      lr
 
//--------------writting pin number 9
Write_Latch:    
        push    {r4,r5,r6,r7,lr}
        ldr     r2, =0x3F200000		//load r2 with base register
        mov     r3, #1			//r3 = 1
        lsl     r3, #9			//align bit for pin#9
        cmp     r1, #0			//compare r1 with 0
        streq   r3, [r2, #40] 		//GPCLR0: write 0 to the latch
        strne   r3, [r2, #28] 		//GPCLR0: write 0 to the latch
        pop     {r4,r5,r6,r7,lr}
        bx      lr
 
 
 
//---------------This function is for setting a delay time
//Takes in amount of time to wait in r1
Wait:
        push     { lr }
        ldr      r0, =0x3F003004	//load the address for CLO
        ldr      r2, [r0]		//read CLO	
        ldr      r3, [r0]        	//r3 is current clock
        add      r2, r1         	//r2 is the upper clock  
 
     	//-------This loop is to make sure the current time is at least equal to the delay time we set
        loopWait:
        cmp      r3, r2			//if the current clock is smaller than the upper clock
        ldr      r3, [r0]		//branch goto the loopWait again
        blt      loopWait		
        pop      { lr }
        bx       lr
 
 
 
//--------------This function takes in 1 argument in r2. This is the index of the message to print.
printMsg:
        push    {r4, r5, r6, r7, lr}
        ldr     r0, =MsgList		//load the string list to r0
        ldr     r4, =MsgSizes		//load the list of each string's length to r4
        ldrb    r1, [r4]		//write GPFSEL into r1
        mov     r3, #0			//r3 is the counter inside this loop

 	//---------------This is a loop made to print each string accroding to the pressed buttons
        loopMsg:                
        cmp     r3, r2
        beq     reachedProperIndex	//if r3 = r2,goto print
        add     r0, r1			//r0 += r1
        add     r4, #1			//r4 += 1
        ldrb    r1, [r4]		//write GPFSEL into r1
        add     r3, #1			//add 1 to r3 after each loop
        b       loopMsg			//go back to the loop

 	//-----------------This is a function made to print by calling UART
        reachedProperIndex:        
        bl      WriteStringUART
         
     
        pop {r4, r5, r6, r7, lr}
        bx lr
//------when the user press the button "start", it print"The program will now terminate..." and exit     
exitProgram:
        mov     r2, #3			//"You have pressed the select button..."
        bl      printMsg		
        mov     r2, #14			//"The program will now terminate..."
        bl      printMsg		
        b       haltLoop$		//exit the program

//-------end of the program
haltLoop$:
        b       haltLoop$


 
 
     
.section .data // data goes in the data section
.align // align to word boundaries
//-------The list for every output string according to the buttons order in the data line 
MsgList:
        .ascii  "You have pressed B...\n\r",
        .ascii  "You have pressed Y...\n\r",
        .ascii  "You have pressed the select button...\n\r",
        .ascii  "You have pressed the start button...\n\r",
        .ascii  "You have pressed joy-pad UP...\n\r",
        .ascii  "You have pressed joy-pad DOWN...\n\r",
        .ascii  "You have pressed joy-pad LEFT...\n\r",
        .ascii  "You have pressed joy-pad RIGHT...\n\r",
        .ascii  "You have pressed A...\n\r",
        .ascii  "You have pressed X...\n\r",
        .ascii  "You have pressed L...\n\r",
        .ascii  "You have pressed R...\n\r",
        .ascii  "\n\n\rCreated by Ali Kamran, Muzhou Zhai, Alejandro Garcia\n\r",
        .ascii  "\n\n\rPlease press a button...\n\r",
        .ascii  "The program will now terminate...\n\n\r"
                 
                                
//-------the list of each string's length 
MsgSizes:
        .byte 23, 23, 39, 38, 32, 34, 34, 35, 23, 23, 23, 23, 57, 29, 36
     
//-------a memory to store the 16 button's value     
buttons:  
        .int    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

ABuff:
    .rept    256   			 // use repeat (.rept / .endr)
    .byte 0				 // to define large areas of
    .endr				 // repeated data
 
isButtonHeld:
	.int 	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0



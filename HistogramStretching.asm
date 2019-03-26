.data
.half 12
header: .space 54

filename: .space 128
inputMessage: .asciiz "Podaj nazwe pliku \n"





.text
.globl main 
main:

	la $a0,inputMessage
	li $v0,4
	syscall

	li $v0,8
	la $a0,filename
	la $a1,128
	syscall
	
	jal removeEndLine
	
	
	
	li $v0,13
	la $a0, filename
	li $a1, 0
	li $a2,0    
	syscall
	
	move $s0, $v0        # save file descriptor 	
	
	##load header
	move $a0,$s0
	li $v0,14
	la $a1,header
	li $a2,54     # allocate space for the bytes loaded
	syscall
	
	##test
	##lw $s7,header+18
	##mul $s7,$s7,3
	##lw $s4,he4ader+22
	
	
	
	
	##addi $a1,$a1,2
		##la $t1,header+
		lw $s1,header+2 ## file size
	
	##alocate memory for bmp data
	li $v0,9
	move $a0,$s1
	syscall
	move $s2,$v0
	
	
	move $a0,$s0
	li $v0,14
	move $a1,$s2
	addu $a2,$s1,$zero     # allocate space for the bytes loaded
	syscall
	
	move $a0,$s0
	li $v0, 16  # $a0 already has the file descriptor
    	syscall
	
	saveToFile:
	
		la $a0,inputMessage
		li $v0,4
		syscall

		li $v0,8
		la $a0,filename
		la $a1,128
		syscall
	
		jal removeEndLine
		
		li $v0,13
		la $a0, filename
		li $a1, 1
		li $a2,0 
		syscall
		
		
		
		move $a0, $v0        # load file descriptor 	
		li $v0,15
		la  $a1,header
		li $a2,54     # allocate space for the bytes to save  
		syscall
		
		li $v0, 16  # $a0 already has the file descriptor
    		syscall
    		
		li $v0,13
		la $a0, filename
		li $a1, 9
		li $a2,0 
		syscall
		
		move $a0, $v0        # load file descriptor 	
		li $v0,15
		move $a1,$s2
		addu $a2,$s1,$zero     # allocate space for the bytes to save  
		syscall
		
		li $v0, 16  # $a0 already has the file descriptor
    		syscall
    		
    		
	li  $v0,10
	syscall 
	
	removeEndLine: ##removing newlines ymbol from the filename

		lbu $t1,0($a0)
		addi $a0,$a0,1
		bne $t1,'\n',removeEndLine
	
		addi $a0,$a0,-1
		sb $0,0($a0)	
		jr $ra

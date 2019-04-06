.data
.half 12
header: .space 54

filename: .space 128
inputMessage: .asciiz "Write filename to stretch its histogram \n"
outputMessage: .asciiz "Write fiilename to save image with streached histogram \n"
errorMessage: .asciiz "File doesn't exist\n "



.text
.globl main 
main:

	la $a0,inputMessage
	li $v0,4
	syscall
loadFile:
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
 	bltz $v0,loadError
	move $s0, $v0        # save file descriptor 	
	
	##load header
	move $a0,$s0
	li $v0,14
	la $a1,header
	li $a2,54     # allocate space for the bytes loaded
	syscall
	
	
	
	
	
	
	##addi $a1,$a1,2
		##la $t1,header+
		lw $s1,header+2 ##  load file size
	
		lw $s2,header+18 ## load bitmap width
		lw $s3,header+22  ## load bitmap height
		lhu $s4,header+28 ## load bits per pixel (number of colors)
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
	
	la $a0,outputMessage
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
loadError:
li $v0,4
la $a0,errorMessage
syscall
li $v0,4
la $a0,inputMessage
syscall
j loadFile
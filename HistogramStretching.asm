.data

input: .space 1024000
output: .space 1024000
filedata: .space 1024000
inputMessage: .asciiz "Podaj nazwe pliku \n"
filename: .space 128

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
	la $a2,0    
	syscall
	
	move $a0, $v0        # load file descriptor 	
	li $v0,14
	la $a1,input
	la $a2,1024000     # allocate space for the bytes loaded
	syscall
	
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
		la $a2,0 
		syscall
		
		move $a0, $v0        # load file descriptor 	
		li $v0,15
		la $a1,input
		la $a2,1024000     # allocate space for the bytes to save  
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
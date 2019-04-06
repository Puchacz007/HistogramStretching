.data
.half 12
header: .space 138


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
	li $a2,138     # allocate space for the bytes loaded
	syscall
	
	
	
	
	
	
	#addi $a1,$a1,2
		
		#lw $s1,header+2 # load file size
		lw $s7,header+10 ## load offset
		##lw $s1,header+18 # load bitmap width
		##lw $s3,header+22  # load bitmap height
		lhu $s4,header+28 # load bits per pixel (number of colors)
		srl $s4,$s4,3 ## change value to number of bytes per pixel
		srl $s6,$s4,2 ## change value to number of bytes per color 
		lw $s5,header+34 #load size of the data section
	#alocate memory for bmp data
	li $v0,9 # allocate heap memory for pixel data
	move $a0,$s5 
	syscall
	move $s2,$v0 #  pixel array save to $s2
	
	
	move $a0,$s0 #load file descriptor
	li $v0,14
	move	$a1, $s2 # load base adress of pixel array
	move	$a2, $s5  # load size of data section
	syscall
	
	move $a0,$s0
	li $v0, 16  # $a0 already has the file descriptor
    	syscall
#makeHistogram
	li $t0,255 #size of blue min
	li $t1,255 # size of green min
	li $t2,255 # size of red min
	li $t3,0 #size of blue max
	li $t4,0 # size of green max
	li $t5,0 # size of red max
	move $t6,$s2 ## load pixel array adress
	
	move $t9,$s5 ## load size of data
	# $s4 number of bits per color
findMinMax:				
	lbu $t7,0($t6)			
	addi $t6,$t6,1
	bge $t7,$t0,blueMax
	addu $t0,$t7,$zero
blueMax:					
	ble $t7,$t3,greenMin
	addu $t3,$t7,$zero
greenMin:
	lbu $t7,0($t6)			
	addi $t6,$t6,1
	bge $t7,$t1,greenMax
	addu $t1,$t7,$zero					
greenMax:					
	ble $t7,$t4,redMin
	addu $t4,$t7,$zero
redMin:
	lbu $t7,0($t6)			
	addi $t6,$t6,1
	bge $t7,$t2,redMax
	addu $t2,$t7,$zero	
					
redMax:	
	ble $t7,$t5,alpha
	addu $t5,$t7,$zero	
	
alpha:
	addu $t6,$t6,$s6
	subu $t9,$t9,$s4 
	bgtz $t9,findMinMax
	
	
	
	
	# $t0 size of blue min
	# $t1 size of green min
	# $t2 size of red min
	# $t3 size of blue max
	# $t4 size of green max
	# $t5 size of red max	
	move $t6,$s2 ## load pixel array adress
	move $t9,$s5 ## load size of data
	
	sll $t8,$s4,3 
	subi $t8,$t8,1 ## bigest color posible value
	
	subu $t3,$t3,$t0  ## max blue - min Blue
	divu $t3,$t8,$t7 ## blue to multiply
	
	subu $t7,$t4,$t1  ## max green - min green
	divu $t4,$t8,$t7 ## green to multiply
	
	subu $t7,$t5,$t2  ## max red - min red
	divu $t5,$t8,$t7 ## red to multiply
	
stretchHistogram:

#blue
	lbu $t7,0($t6)	 ## load color value		
	subu $t7,$t7,$t0
	mul $t7,$t7,$t3
	sb $t7,0($t6)
	addi $t6,$t6,1	
#green
	lbu $t7,0($t6)	 ## load color value		
	subu $t7,$t7,$t1
	mul $t7,$t7,$t4
	sb $t7,0($t6)
	addi $t6,$t6,1	
#red
	lbu $t7,0($t6)	 ## load color value		
	subu $t7,$t7,$t2
	mul $t7,$t7,$t5
	sb $t7,0($t6)
	addi $t6,$t6,1	
	
#alpha
	addu $t6,$t6,$s6
	subu $t9,$t9,$s4 
	bgtz $t9,stretchHistogram
																																																																																	
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
	move $a2,$s7     # allocate space for the bytes to save  
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
	addu $a2,$s5,$zero   # allocate space for the bytes to save  
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

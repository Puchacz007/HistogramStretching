.data
.half 12
bmpFileHeader: .space 14
DIBHeader: .space 124

filename: .space 128
inputMessage: .asciiz "Write filename to stretch its histogram \n"
outputMessage: .asciiz "Write fiilename to save image with streached histogram \n"
errorMessage: .asciiz "File doesn't exist\n"
badFileErrorMessage: .asciiz "Error with loading file\nPlease select bmp 24 bit file\n"


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
	
	removeEndLineLoad: ##removing newlines symbol from the filename
	lbu $t1,0($a0)
	addi $a0,$a0,1
	bne $t1,'\n',removeEndLineLoad
	
	addi $a0,$a0,-1
	sb $zero,0($a0)	
	
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
	la $a1,bmpFileHeader
	li $a2,14     # allocate space for the bytes loaded
	syscall
	
	
	lw $s7,bmpFileHeader+10 ## load offset
	subi $s7,$s7,14 ## remove  bmp header from offset to find DIB header size
	
	move $a0,$s0 #load file descriptor
	li $v0,14
	la $a1,DIBHeader # load DIB header
	move $a2,$s7
	syscall
	lw $s3,DIBHeader+4 #load width of the image
	lw $s4,DIBHeader+8 #load height of the image
	beqz $s4,badFile
	beqz $s3,badFile
	
	mul $s5,$s3,$s4 ## number of pixels (width * height) each pixel is 3 byte 1 for each color for 24 bit image
	#alocate memory for bmp data
	andi $s1,$s3,3 ## rest of division by 4 from row size
	li $v0,9 # allocate heap memory for pixel data
	move $a0,$s5
	mul $a0,$a0,3 
	mul $t8,$s1,$s4
	addu $a0,$a0,$t8
	syscall
	move $s2,$v0 #  pixel array save to $s2
	
	
	move $a0,$s0 #load file descriptor
	li $v0,14
	move	$a1, $s2 # load base adress of pixel array
	move	$a2, $s5  # load size of data section
	mul $a2,$a2,3 
	mul $t8,$s1,$s4
	addu $a2,$a2,$t8
	syscall
	
	move $a0,$s0 #load file descriptor
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
	# $s3 - width 
	# $s4 - height
	li $s6, 1 ## pixel number in row
findMinMax:	
				
	lbu $t7,0($t6) ## load color value	
	addi $t6,$t6,1 ## go to next byte
	bge $t7,$t0,blueMax ## check if loaded blue value is min
	addu $t0,$t7,$zero ## set new min blue
blueMax:					
	ble $t7,$t3,greenMin ## check if loaded blue value is max
	addu $t3,$t7,$zero ## set new max blue
greenMin:
	lbu $t7,0($t6)	## load color value	
	addi $t6,$t6,1 ## go to next byte
	bge $t7,$t1,greenMax## check if loaded green value is min
	addu $t1,$t7,$zero ## set new min green
greenMax:					
	ble $t7,$t4,redMin ## check if loaded green value is max
	addu $t4,$t7,$zero## set new max green	
redMin:
	lbu $t7,0($t6)	## load color value	
	addi $t6,$t6,1 ## go to next byte		
	bge $t7,$t2,redMax ## check if loaded red value is min
	addu $t2,$t7,$zero ## set new min red
redMax:	
	ble $t7,$t5,padding1 ## check if loaded red value is max
	addu $t5,$t7,$zero	## set new max red
padding1:
	bne $s6, $s3, decreasePixels	# jesli licznik pikseli w wierszu != width
	addu $t6,$t6,$s1 ## append padding 
	li $s6,0 ## go to next line
decreasePixels:	
	subi $t9,$t9,1	## decrease number of pixels
	addi $s6, $s6, 1 # increase pixel number

	bgtz $t9,findMinMax ## check if we checked all pixels from pixel data
	
	# $t0 size of blue min
	# $t1 size of green min
	# $t2 size of red min
	# $t3 size of blue max
	# $t4 size of green max
	# $t5 size of red max	
	move $t6,$s2 ## load pixel array adress
	move $t9,$s5 ## load size of data
	subu $t3,$t3,$t0  ## max blue - min Blue
	subu $t4,$t4,$t1  ## max green - min green
	subu $t5,$t5,$t2  ## max red - min red
	li $s6, 1 ## pixel number in row
stretchHistogram:

	#blue
	lbu $t7,0($t6)	 ## load color value	
	##histogram streching
	subu $t7,$t7,$t0
	mul $t7,$t7,255
	divu $t7,$t7,$t3 ## blue to divide
	
	sb $t7,0($t6) ## save normalized byte
	addi $t6,$t6,1 ## go to next byte
green:
	lbu $t7,0($t6)	 ## load color value
	
	##histogram streching		
	subu $t7,$t7,$t1
	mul $t7,$t7,255
	divu $t7,$t7,$t4 ## green to divide

	sb $t7,0($t6) ## save normalized byte
	addi $t6,$t6,1 ## go to next byte
red:
	lbu $t7,0($t6)	 ## load color value		
	
	##histogram streching	
	subu $t7,$t7,$t2
	mul $t7,$t7,255
	divu $t7,$t7,$t5 ## red to divide

	sb $t7,0($t6) ## save normalized byte
	addi $t6,$t6,1 ## go to next byte
	

	#padding2:
	bne $s6, $s3, decreasePixels2	# jesli licznik pikseli w wierszu != width
	addu $t6,$t6,$s1 ## append padding 
	li $s6,0 ## go to next line
decreasePixels2:	
	subi $t9,$t9,1	## decrease number of pixels
	addi $s6, $s6, 1 # increase pixel number	
	bgtz $t9,stretchHistogram  ## check if we streched all bytes from pixel data																																																																															
saveToFile:
  	
	la $a0,outputMessage
	li $v0,4
	syscall

	li $v0,8
	la $a0,filename
	la $a1,128
	syscall
	
	removeEndLineSave: ##removing newlines symbol from the filename
	lbu $t1,0($a0)
	addi $a0,$a0,1
	bne $t1,'\n',removeEndLineSave
	
	addi $a0,$a0,-1
	sb $zero,0($a0)	
		
	li $v0,13
	la $a0, filename
	li $a1, 1
	li $a2,0 
	syscall
		
	 # $t7 size of DIB header	
		
	move $a0, $v0        # load file descriptor 	
	li $v0,15
	la  $a1,bmpFileHeader
	li $a2,14    # allocate space for the bytes to save  
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
	la $a1,DIBHeader
	move $a2,$s7   # allocate space for the bytes to save  
	syscall	
				
	##move $a0, $v0        # load file descriptor 	
	#file descriptor is the same
	li $v0,15
	move $a1,$s2
	addu $a2,$s5,$zero   # allocate space for the bytes to save  
	mul $a2,$a2,3 
	mul $t8,$s1,$s4
	addu $a2,$a2,$t8
	syscall
		
	li $v0, 16  # $a0 already has the file descriptor
    	syscall
    			
	li  $v0,10
	syscall 
loadError:
	li $v0,4
	la $a0,errorMessage
	syscall
	li $v0,4
	la $a0,inputMessage
	syscall
	j loadFile
badFile:
	li $v0,4
	la $a0,badFileErrorMessage
	syscall
	li $v0,4
	la $a0,inputMessage
	syscall
	j loadFile
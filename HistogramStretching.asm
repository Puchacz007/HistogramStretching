.data
.half 12
bmpFileHeader: .space 14
DIBHeader: .space 124

filename: .space 128
inputMessage: .asciiz "Write filename to stretch its histogram \n"
outputMessage: .asciiz "Write fiilename to save image with streached histogram \n"
errorMessage: .asciiz "File doesn't exist\n"



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
	
	## bits per pixet 1,2,4,8,16,24,32
	##lhu $s4,DIBHeader+14 # load bits per pixel (number of colors)
		
		
	#srl $s4,$s4,2 ## change value to number of bits per color
	#li $s1,8
	#div $s3,$s1,$s4 ##number of color per byte
	#subu $s1,$s1,$s4 ## number bits to shift left logical
	#addi $s1,$s1,24 # increase to full register size
		##srl $s6,$s4,2 ## change value to number of bytes per color  //temp
	lw $s3,DIBHeader+4 #load width of the image
	lw $s4,DIBHeader+8 #load height of the image
	##lw $s5,DIBHeader+20 #load size of the data section
	mul $s5,$s3,$s4 ## number of pixels (width * height) each pixel is 3 byte 1 for each color for 24 bit image
	#alocate memory for bmp data
	li $v0,9 # allocate heap memory for pixel data
	move $a0,$s5
	mul $a0,$a0,3 
	syscall
	move $s2,$v0 #  pixel array save to $s2
	
	
	move $a0,$s0 #load file descriptor
	li $v0,14
	move	$a1, $s2 # load base adress of pixel array
	move	$a2, $s5  # load size of data section
	mul $a2,$a2,3 
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
	#li $t8,0 ## number of used bits in byte
	# $s3 - width 
	# $s4 - height
	#srl $t8, $s3, 2 

	andi $t8,$s3,3 ## rest of division by 4 from row size
	li $s6, 1 ## pixel number in row
	# $s4 number of bits per color
findMinMax:	
				
	lbu $t7,0($t6) ## load color value	
	addi $t6,$t6,1 ## go to next byte
	#srlv $t7,$t7,$t8 ## shift blue color bits to be least important
	#sllv $t7,$t7,$s1 ## remove other bits
	#srlv $t7,$t7,$s1 ## leave only important bits
	#addu $t8,$t8,$s4 ## increase number of already used bits from loaded byte
	bge $t7,$t0,blueMax ## check if loaded blue value is min
	addu $t0,$t7,$zero ## set new min blue
blueMax:					
	ble $t7,$t3,greenMin ## check if loaded blue value is max
	addu $t3,$t7,$zero ## set new max blue
#increaseBlue:	
#	bne $t8,8,greenMin ##check if it's time to load next byte
#	addi $t6,$t6,1 ## go to next byte
#	li $t8,0 ## number of used bits in byte
#	subi $t9,$t9,1 ## decrease number of bytes in pixel data 

greenMin:
	lbu $t7,0($t6)	## load color value	
	addi $t6,$t6,1 ## go to next byte
#	srlv $t7,$t7,$t8 ## shift blue color bits to be least important
#	sllv $t7,$t7,$s1 ## remove other bits
#	srlv $t7,$t7,$s1 ## leave only important bits
#	addu $t8,$t8,$s4 ## increase number of already used bits from loaded byte	
	bge $t7,$t1,greenMax## check if loaded green value is min
	addu $t1,$t7,$zero ## set new min green
greenMax:					
	ble $t7,$t4,redMin ## check if loaded green value is max
	addu $t4,$t7,$zero## set new max green
#increaseGreen:	
#	bne $t8,8,redMin ##check if it's time to load next byte
#	addi $t6,$t6,1 ## go to next byte
#	li $t8,0	## number of used bits in byte
#	subi $t9,$t9,1	## decrease number of bytes in pixel data 		
redMin:
	lbu $t7,0($t6)	## load color value	
	addi $t6,$t6,1 ## go to next byte		
#	srlv $t7,$t7,$t8 ## shift blue color bits to be least important
#	sllv $t7,$t7,$s1 ## remove other bits
#	srlv $t7,$t7,$s1 ## leave only important bits
#	addu $t8,$t8,$s4 ## increase number of already used bits from loaded byte
	bge $t7,$t2,redMax ## check if loaded red value is min
	addu $t2,$t7,$zero ## set new min red
redMax:	
	ble $t7,$t5,padding1 ## check if loaded red value is max
	addu $t5,$t7,$zero	## set new max red
#increaseRed:	
#	bne $t8,8,increaseAlpha ##check if it's time to load next byte
#	addi $t6,$t6,1 ## go to next byte
#	li $t8,0	## number of used bits in byte
#	subi $t9,$t9,1	## decrease number of bytes in pixel data 			
#increaseAlpha:	
#	addu $t8,$t8,$s4 ## increase number of already used bits from loaded byte
#	bne $t8,8,alpha ##check if it's time to load next byte
#	addi $t6,$t6,1 ## go to next byte
#	li $t8,0 ## number of used bits in byte
#	subi $t9,$t9,1 ## decrease number of bytes in pixel data 
padding1:
	bne $s6, $s3, decreasePixels	# jesli licznik pikseli w wierszu != width
	addu $t6,$t6,$t8 ## append padding 
	li $s6,0 ## go to next line
decreasePixels:	
	subi $t9,$t9,1	## decrease number of pixels
	addi $s6, $s6, 1 # increase pixel number

	bgtz $t9,findMinMax ## check if we checked all bytes from pixel data
	
	# $t0 size of blue min
	# $t1 size of green min
	# $t2 size of red min
	# $t3 size of blue max
	# $t4 size of green max
	# $t5 size of red max	
	move $t6,$s2 ## load pixel array adress
	move $t9,$s5 ## load size of data
	#li $t8,255 ## bigest color value for one color using 8 bits
	#srlv $s3,$s3,$s1 ## bigest color posible value
	subu $t3,$t3,$t0  ## max blue - min Blue
	subu $t4,$t4,$t1  ## max green - min green
	subu $t5,$t5,$t2  ## max red - min red
	andi $t8,$s3,3 ## rest of division by 4 from row size
	li $s6, 1 ## pixel number in row
	#li $s6,0 ## byte to save
	#li $t8,0 ## number of used bits in byte
stretchHistogram:

	#blue
	lbu $t7,0($t6)	 ## load color value	
	#srlv $t7,$t7,$t8 ## shift blue color bits to be least important
	#sllv $t7,$t7,$s1 ## remove other bits
	#srlv $t7,$t7,$s1 ## leave only important bits
	

	##histogram streching
	subu $t7,$t7,$t0
	mul $t7,$t7,255
	divu $t7,$t7,$t3 ## blue to divide
	
	#sllv $t7,$t7,$t8 ## shift to good color position in byte
	#addu $s6,$s6,$t7 ## add color number to save
	#addu $t8,$t8,$s4 ## increase number of used bits in byte
	#bne $t8,8,green ## check if byte to save is full
	sb $t7,0($t6) ## save normalized byte
	addi $t6,$t6,1 ## go to next byte
	#li $t8,0 ## number of used bits in byte
	#li $s6,0 ## byte to save
	#subi $t9,$t9,1 ## decrease number of bytes to normalize from pixel data
green:
	lbu $t7,0($t6)	 ## load color value
	#srlv $t7,$t7,$t8 ## shift blue color bits to be least important
	#sllv $t7,$t7,$s1 ## remove other bits
	#srlv $t7,$t7,$s1 ## leave only important bits
	
	
	##histogram streching		
	subu $t7,$t7,$t1
	mul $t7,$t7,255
	divu $t7,$t7,$t4 ## green to divide
	
	#sllv $t7,$t7,$t8 ## shift to good color position in byte
	#addu $s6,$s6,$t7 ## add color number to save
	#addu $t8,$t8,$s4 ## increase number of used bits in byte
	#bne $t8,8,red ## check if byte to save is full
	sb $t7,0($t6) ## save normalized byte
	addi $t6,$t6,1 ## go to next byte
	#li $t8,0 ## number of used bits in byte
	#li $s6,0 ## byte to save
	#subi $t9,$t9,1
	
red:
	lbu $t7,0($t6)	 ## load color value		
	#srlv $t7,$t7,$t8 ## shift blue color bits to be least important
	#sllv $t7,$t7,$s1 ## remove other bits
	#srlv $t7,$t7,$s1 ## leave only important bits
	
	##histogram streching	
	subu $t7,$t7,$t2
	mul $t7,$t7,255
	divu $t7,$t7,$t5 ## red to divide
	
	#sllv $t7,$t7,$t8 ## shift to good color position in byte
	#addu $s6,$s6,$t7 ## add color number to save
	#addu $t8,$t8,$s4 ## increase number of used bits in byte
	#bne $t8,8,alphaSave ## check if byte to save is full
	sb $t7,0($t6) ## save normalized byte
	addi $t6,$t6,1 ## go to next byte
	#li $t8,0 ## number of used bits in byte
	#li $s6,0 ## byte to save
	#subi $t9,$t9,1 ## decrease number of bytes to normalize from pixel data
	
#alphaSave:
#	lbu $t7,0($t6)	 ## load alpha value		
#	srlv $t7,$t7,$t8 ## shift blue color bits to be least important
#	sllv $t7,$t7,$s1 ## remove other bits
#	srlv $t7,$t7,$s1 ## leave only important bits
	

#	sllv $t7,$t7,$t8 ## shift to good color position in byte
#	addu $s6,$s6,$t7 ## add color number to save
#	addu $t8,$t8,$s4 ## increase number of used bits in byte
#	bne $t8,8,end ## check if byte to save is full
#	sb $s6,0($t6) ## save normalized byte
#	addi $t6,$t6,1 ## go to next byte
#	li $t8,0 ## number of used bits in byte
#	li $s6,0 ## byte to save
#	subi $t9,$t9,1 ## decrease number of bytes to normalize from pixel data
	
#end:
padding2:
	bne $s6, $s3, decreasePixels2	# jesli licznik pikseli w wierszu != width
	addu $t6,$t6,$t8 ## append padding 
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

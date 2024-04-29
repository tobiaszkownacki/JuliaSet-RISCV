	.data
HeaderBuf:	.space 56
InputPath: 	.asciz "C:\\Users\\Tobiasz\\Desktop\\studia\\2sem\\arko_lab\\RISC-V\\PROJEKT\\example.bmp"
ErrorMsg1: 	.asciz "File not found\n"
ErrorMsg2:	.asciz "File BMP must be 24 bits per pixel\n"
AskMsg1:	.asciz "Enter int part of real part of constant multiplied by 2^13\n"
AskMsg2:	.asciz "Enter int part of imaginary part of constant multiplied by 2^13\n"
.eqv	BITS_ON_FRACTION	13
.eqv	WHITE	0xFF
.eqv	BLACK	0x00
.eqv	MAX_ITERATIONS	40
	.text
	.globl main

main:
	# --START OF ASK USER TO INPUT DATA--#
	la a0, AskMsg1
	jal print_message
	jal read_int

	mv s5, a0		# assign real part of constant to s5

	la a0, AskMsg2
	jal print_message
	jal read_int

	mv s6, a0		# assign imaginary part of constant to s6

	# ---STOP OF ASK USER TO INPUT DATA-#
	# ---START OF READING FILE----------#
	li a7, 1024
	li a1, 0
	la a0, InputPath
	ecall				# open file

	mv t2, a0			# save file description in t2

	la a0, ErrorMsg1		# load error message
	blt t2, zero, print_error	# check if found file


	li a7, 63
	mv a0, t2
	la a1, HeaderBuf  	# load HeaderBuf address in a1
	addi a1, a1, 2     	# add 2 becasue signiature has only 2, dont have padding
	li a2, 54          	# 54 if typical size of header
	ecall             	# read BMP header to HeaderBuff

	lw s1, 18(a1)     	# assign width to s1
	lw s0, 22(a1)      	# assign height to s0
	lw t1, 2(a1)       	# assign file size to t1
	lw s2, 10(a1)     	# assign file offset to pixdel array to s2
	lh t3, 28(a1)      	# assign to t3 pixelperBits

	li t0, 24
	la a0, ErrorMsg2
	bne t0, t3, print_error # check if BMP is 24 bits per pixel

	sub s3, t1, s2      	# assign size of pixel array to s3

	li a7, 9
	mv a0, s3
	ecall             	# allocate memmory for pixel arrey

	mv s11, a0         	# save address to allocated memmory in s11

	li a7, 63
	mv a0, t2
	mv a1, s11
	mv a2, s3
	ecall            	# read BMP pixel array to heap (t0)

	li a7, 57
	mv a0, t2        	# close opened file
	ecall

	# ---- END OF READING FILE--------------#
	# ---START OF CALCULATE IMPORTANT FIGURE#
	andi s4, s1, 3   	# padding = width % 4  (andi is faster mr Niespodziany method. More on his github)

	li t0, 3                # 2 * 1,5
	slli t0, t0, BITS_ON_FRACTION

	div s7, t0, s1    	# assign width scale to s7
	div s8, t0, s0   	# assign height scale to s8

	li a5, BITS_ON_FRACTION
	addi a5, a5, -1		# assgin BITS_ON_FRACTION - 1 to a5

	li s9, -3		# assign to s9 -1,5 * 2
	sll s9, s9, a5  	# assign to s9 starting real part of pixel
	mv t2, s9		# assign to t2 starting value of imaginary part
	add t2, t2, s8          # add one scale becasue in height_loop it subtract at once

	mv t0, s0        	# assign temporary height to t0
	addi t0, t0, 1   	# add one because in height_loop it subtract one and comapre at once


	li a7, BLACK    	# assign to a7 black color of pixel
	li a6, WHITE    	# assign to a6 white color

	li t4, MAX_ITERATIONS	# assign number of iterations to t4
	li a4, 4		# assign max complex modul ^2
	slli a4, a4, BITS_ON_FRACTION

	mv s10, s11       	# move heap address to s10 (used in changing pixels)

	# ---END OF CALCULATE IMPORTANT FIGURE#
#--------------------- START OF height_looop Function------------------------------------#
height_loop:

	mv t1, s1          	# assign temporary width in t1
	mv t3, s9        	# assgin real part of complex number on -2

	addi t0, t0, -1   	# subtract one height
	add t2, t2, s8

 	beqz t0, write_to_file
#--------------------- END OF height_looop Function--------------------------------------#
#-------------------- START OF preapare_to_pixel_check Function--------------------------#
prepare_to_pixel_check:
	li t4, MAX_ITERATIONS	# assign number of iterations to t4

	mv t5, t2		# assign imaginary part of complex number to t5
	mv t6, t3		# assign real part of complex number to t6

#-------------------- END OF preapare_to_pixel_check Function---------------------------#
#--------------------- START OF pixel_check Function------------------------------------#
pixel_check:
      #      newRe = oldRe * oldRe - oldIm * oldIm + cRe;
      #		newIm = 2 * oldRe * oldIm + cIm;
      #		if((newRe * newRe + newIm * newIm) > 4) break;

      # ---Calculate new Real part----#
      mul a3, t6, t6   		# oldRe * oldRe
      srai a3, a3, BITS_ON_FRACTION

      mul a2, t5, t5   		# oldIm * oldIm
      srai a2, a2, BITS_ON_FRACTION
      sub a3, a3, a2   		# oldRe * oldRe - oldIm * oldIm
      add a3, a3, s5   		# oldRe * oldRe - oldIm * oldIm + cRe;

      # ---Calculate new imaginary part---#
      mul t5, t5, t6 		# oldIm * oldRe
      sra t5, t5, a5 		# 2 * oldRe * oldIm
      add t5, t5, s6 		# 2 * oldRe * oldIm + cIm

      mv t6, a3      		# assign new Re to t6

      # ---Calculate modul ----#

      mul a2, t6, t6 		# newRe * newRe
      srai a2, a2, BITS_ON_FRACTION
      mul a3, t5, t5		# newIm * newIm
      srai a3, a3, BITS_ON_FRACTION
      add a3, a3, a2		# newRe * newRe + newIm * newIm

      bgt a3, a4, non_julia_pixel  # if sqrt(complex modul) > 4 go to non_julia_pixel

      addi t4, t4, -1

      bnez t4, pixel_check


#--------------------- END OF pixel_check Function--------------------------------------#
#-------------------- START OF julia_pixel Function-------------------------------------#
julia_pixel:
	sb a7, (s10)
	sb a7, 1(s10)
	sb a7, 2(s10)

	addi s10, s10, 3	# set heap address to next pixel (pixel has 3 Bytes)
	b width_loop
#-------------------- END OF julia_pixel Function------------------------------------#
#------------------- START OF non_julia_pixel Function-------------------------------#
non_julia_pixel:

	sb a6, (s10)
	sb a6, 1(s10)
	sb a6, 2(s10)

	addi s10, s10, 3	# set heap address to next pixel (pixel has 3 Bytes)

#------------------- END OF non_julia_pixel Function------------------------------------#
#--------------------- START OF width_loop Function-------------------------------------#
width_loop:
	addi t1, t1, -1        # subtract one width
	add t3, t3, s7         # add width scale

	bnez t1, prepare_to_pixel_check     # if temporary width != 0 go to preapre_to_pixel_check else go to padding

#--------------------- END OF width_loop Function--------------------------------------#
#--------------------- START OF add_padding Function-------------------------------------#
add_padding:
	add s10, s10, s4    	# add padding to heap address

	b height_loop

#-------------------- END OF add_padding Function----------------------------------------#
# -------------------START OF write_to_file FUNCTION-----------------------------------#
write_to_file:
	li a7, 1024
	li a1, 1
	la a0, InputPath
	ecall			# open file

	mv t0, a0		# save file id to t0

	li a7, 64		# write in the header header because lSeek does not work
	la a1, HeaderBuf
	addi a1, a1, 2
	mv a2, s2
	ecall

	li a7, 64		# Write pixel array to the file
	mv a0, t0
	mv a1, s11
	mv a2, s3
	ecall

	li a7, 57
	mv a0, t0		# close opened file
	ecall

# -------------------END OF write_to_file FUNCTION--------------------------------------#
# -------------------START of end FUNCTION----------------------------------------------#
end:
	li a7, 10
	ecall			# end pogram
# -------------------END OF end FUNCTION------------------------------------------------#
# -------------------- START OF print_error Function------------------------------------#
print_error:
	jal print_message

	b end			# go ot end
# -------------------- END OF print_error Function-------------------------------------#
#--------------------START OF print_message--------------------------------------------#
print_message:
	li a7, 4
	ecall

	ret
#---------------------END OF print_message---------------------------------------------#
#---------------------START OF read_int------------------------------------------------#
read_int:
	li a7, 5
	ecall

	ret
#--------------------END OF read_int---------------------------------------------------#


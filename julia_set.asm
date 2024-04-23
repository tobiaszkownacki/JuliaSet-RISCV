	.data
HeaderBuf:	.space 56
InputPath: 	.asciz "C:\\Users\\Tobiasz\\Desktop\\studia\\2sem\\arko_lab\\RISC-V\\PROJEKT\\example.bmp"
ErrorMsg: 	.asciz "File not found"
.eqv	COLOR 0xAA
	.text
	.globl main

main:
	# ---START OF READING FILE---
	li a7, 1024
	li a1, 0
	la a0, InputPath
	ecall       # open file

	mv s11, a0   # save file description in s11

	li t0, -1
	la a0, ErrorMsg
	beq t0, s11, print_error   # check if found file


	li a7, 63
	mv a0, s11
	la a1, HeaderBuf   # load HeaderBuf address in a1
	addi a1, a1, 2     # add 2 becasue signiature has only 2, dont have padding
	li a2, 54
	ecall              # read BMP header to HeaderBuff

	lw s0, 18(a1)      # assign width to s0
	lw s1, 22(a1)      # assign height to s1
	lw t1, 2(a1)       # assign file size to t1
	lw s2, 10(a1)      # assign file offset to pixdel array to s2

	sub s3, t1, s2      # assign size of pixdel array to s3

	li a7, 9
	mv a0, s3
	ecall              # allocate memmory for pixel arrey

	mv s10, a0          # save address to allocated memmory in s10

	li a7, 63
	mv a0, s11
	mv a1, s10
	mv a2, s3
	ecall             # read BMP pixel array to heap (t0)

	li a7, 57
	mv a0, s11        # close opened file
	ecall

	# ---- END OF READING FILE--------
	# ---START OF MODYFING PIXEL ARRAY------
	mv t2, s1        # assign temporary height to t2
	addi t2, t2, 1   # add one because in height_loop it subtract one and comapre at once

	mv t0, s10       # move heap address to t0 (used in changing pixels)
	b calculate_padding

	# ---END OF MODYFING PIXEL ARRAY------
# -------------------START OF write_to_file FUNCTION------------------------------------------
write_to_file:
	li a7, 1024
	li a1, 1
	la a0, InputPath
	ecall       # open file


	mv t0, a0   # save file id to t0

	#li a7, 62   # LSeek to pizel array
	#mv a0, t0
	#li a1, 2   # TODO
	#li a2, 1
	#ecall

	li a7, 64     # write in the header header because lSeek does not work
	mv a0, t0
	la a1, HeaderBuf
	addi a1, a1, 2
	mv a2, s2
	ecall

	li a7, 64    # Write pixel array to the file
	mv a0, t0
	mv a1, s10
	mv a2, s3
	ecall

	li a7, 57
	mv a0, t0        # close opened file
	ecall

# -------------------END OF write_to_file FUNCTION------------------------------------------
# -------------------START of end FUNCTION------------------------------------------------
end:
	li a7, 10
	ecall # end pogram
# -------------------END OF end FUNCTION------------------------------------------
# -------------------- START OF print_error Function---------------------------------
print_error:
	li a7, 4
	ecall # print error which is in a0

	li a7, 10
	ecall # exit
# -------------------- END OF print_error Function---------------------------------
#-------------------- START OF calculate_padding Function------------------------
calculate_padding:
	andi s4, s0, 3       # padding = width % 4  (andi is faster mr Niespodziany method. More on his github)

	b height_loop       # start height loop

#------------------- END OF calculate_padding Function---------------------------
#--------------------- START OF add_padding Function--------------------------
add_padding:
	add t0, t0, s4    # add padding to heap address

	b height_loop      # return to heigght loop

#-------------------- END OF add_padding Function-----------------------------
#--------------------- START OF height_looop Function------------------------------
height_loop:
	mv t3, s0          # assign temporary width

	addi t2, t2, -1   # subtract one height

 	beqz t2, write_to_file
#--------------------- END OF height_looop Function------------------------------
#--------------------- START OF pixel_calculations Function------------------------------
pixel_calculations:
	beqz t3, add_padding     # if temporary width == 0 go to padding

	lb t4, (t0)   # load first RGP Byte
	lb t5, 1(t0)  # load second RGP Byte
	lb t6, 2(t0)  # load third RGP Byte

	li t4, COLOR
	li t5, COLOR
	li t6, COLOR

	sb t4, (t0)
	sb t5, 1(t0)
	sb t6, 2(t0)

	addi t0, t0, 3   # shift register to another pixel

#--------------------- END OF pixel_calculations Function------------------------------
#--------------------- START OF width_loop Function------------------------------
width_loop:
	#beqz t3, height_loop   # check if width is zero then return to height_loop
	addi t3, t3, -1        # subtract one width

	b pixel_calculations   # go to pixel_calculations
#--------------------- END OF width_loop Function------------------------------
	
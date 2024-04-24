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

	mv t2, a0   # save file description in t2

	li t0, -1
	la a0, ErrorMsg
	beq t0, t2, print_error   # check if found file


	li a7, 63
	mv a0, t2
	la a1, HeaderBuf   # load HeaderBuf address in a1
	addi a1, a1, 2     # add 2 becasue signiature has only 2, dont have padding
	li a2, 54          # 54 if typical size of header
	ecall              # read BMP header to HeaderBuff

	lw s1, 18(a1)      # assign width to s1
	lw s0, 22(a1)      # assign height to s0
	lw t1, 2(a1)       # assign file size to t1
	lw s2, 10(a1)      # assign file offset to pixdel array to s2

	sub s3, t1, s2      # assign size of pixdel array to s3

	li a7, 9
	mv a0, s3
	ecall              # allocate memmory for pixel arrey

	mv s11, a0          # save address to allocated memmory in s11

	li a7, 63
	mv a0, t2
	mv a1, s11
	mv a2, s3
	ecall             # read BMP pixel array to heap (t0)

	li a7, 57
	mv a0, t2        # close opened file
	ecall

	# ---- END OF READING FILE--------
	# ---START OF MODYFING PIXEL ARRAY------
	andi s4, s1, 3   # padding = width % 4  (andi is faster mr Niespodziany method. More on his github)

	mv t0, s0        # assign temporary height to t0
	addi t0, t0, 1   # add one because in height_loop it subtract one and comapre at once

	mv s10, s11       # move heap address to s10 (used in changing pixels)
	b height_loop

	# ---END OF MODYFING PIXEL ARRAY------
#--------------------- START OF add_padding Function--------------------------
add_padding:
	add s10, s10, s4    # add padding to heap address

#-------------------- END OF add_padding Function-----------------------------
#--------------------- START OF height_looop Function------------------------------
height_loop:
	mv t1, s1          # assign temporary width in t1

	addi t0, t0, -1   # subtract one height

 	beqz t0, write_to_file
#--------------------- END OF height_looop Function------------------------------
#--------------------- START OF pixel_calculations Function------------------------------
pixel_calculations:
	beqz t1, add_padding     # if temporary width == 0 go to padding

	lb t3, (s10)   # load first RGP Byte
	lb t4, 1(s10)  # load second RGP Byte
	lb t5, 2(s10)  # load third RGP Byte

	li t3, COLOR
	li t4, COLOR
	li t5, COLOR

	sb t3, (s10)
	sb t4, 1(s10)
	sb t5, 2(s10)

	addi s10, s10, 3   # shift register to another pixel

#--------------------- END OF pixel_calculations Function------------------------------
#--------------------- START OF width_loop Function------------------------------
width_loop:
	addi t1, t1, -1        # subtract one width

	b pixel_calculations   # go to pixel_calculations
#--------------------- END OF width_loop Function------------------------------
# -------------------- START OF print_error Function---------------------------------
print_error:
	li a7, 4
	ecall 	 	# print error which is in a0

	b end 		# got ot end
# -------------------- END OF print_error Function---------------------------------
# -------------------START OF write_to_file FUNCTION------------------------------------------
write_to_file:
	li a7, 1024
	li a1, 1
	la a0, InputPath
	ecall       # open file

	mv t0, a0   # save file id to t0

	li a7, 64     # write in the header header because lSeek does not work
	mv a0, t0
	la a1, HeaderBuf
	addi a1, a1, 2
	mv a2, s2
	ecall

	li a7, 64    # Write pixel array to the file
	mv a0, t0
	mv a1, s11
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
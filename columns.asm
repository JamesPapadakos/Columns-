################# CSC258 Assembly Final Project ###################
# This file contains our implementation of Columns.
#
# Student 1: James Papadakos, 1011589657
#
# We assert that the code submitted here is entirely our own 
# creation, and will indicate otherwise when it is not.
#
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       8
# - Unit height in pixels:      8
# - Display width in pixels:    256
# - Display height in pixels:   256
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

.data
##############################################################################
# Immutable Data
##############################################################################
grey: .word 0x808080
red: .word 0xFF0000
orange: .word 0xFFA500
yellow: .word 0xFFFF00
green: .word 0x00FF00
blue: .word 0x0000FF
purple: .word 0x800080
black: .word 0x000000
white: .word 0xFFFFFF

boardHeight: .word 21
boardWidth: .word 6

board: .space 504 #(21 * 6) * 4 bytes
matchFound: .word 0 


# The address of the bitmap display. Don't forget to connect it!
displayAddress: .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000

##############################################################################
# Mutable Data
##############################################################################
columnX: .word 5 #initial horizontal pos of gem column
columnY: .word 2 #initial y pos of top of gem column 
gem1Colour: .word 0
gem2Colour: .word 0
gem3Colour: .word 0
nextGem1Colour: .word 0 
nextGem2Colour: .word 0 
nextGem3Colour: .word 0 
gravityCounter: .word 0 
gravityValue: .word 20
paused: .word 0 
gameOver: .word 0
score: .word 0
highScore: .word 0 
clearedThisTurn: .word 0
chainDepth: .word 0 
##############################################################################
# Code
##############################################################################
.text
j main
DRAW_SQUARE: 
#Draws a single square pixel given x, y and colou
#Has arguments $a0 = x, $a1 = y, $a2 = colour
   lw $t0, displayAddress
   addi $t1, $zero, 32
   mult $a1, $t1
   mflo $t2
   add $t2, $t2, $a0
   sll $t2, $t2, 2 #multiply index by 4 to account for bytes 
   add $t3, $t0, $t2
   sw $a2, 0($t3)
   jr $ra
  
DRAW_GEM_COL: 
#Drawing the initial column of 3 gems that drops
    addi $sp, $sp, -4
    sw   $ra, 0($sp)
    #Gem 1: 
    lw $s3, columnX
    lw $s4, columnY
    lw $a2, gem1Colour
    add $a0, $s3, $zero
    add $a1, $s4, $zero
    jal DRAW_SQUARE
    
    #Gem 2: 
    lw $s3, columnX
    lw $s4, columnY
    lw $a2, gem2Colour
    add $a0, $s3, $zero
    addi $a1, $s4, 1 #Moving down 1 in y direction for 2nd gem
    jal DRAW_SQUARE
	
	#Gem 3: 
	lw $s3, columnX
    lw $s4, columnY
    lw $a2, gem3Colour
    add $a0, $s3, $zero
    addi $a1, $s4, 2 #Moving down 2 from Gem 1 for 3rd gem 
    jal DRAW_SQUARE
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    
SET_BLACK:
    #Set the entire display to black for reset 
    addi $sp, $sp, -4
    sw   $ra, 0($sp)
    addi $s0, $zero, 0 #set y = 0 
clear_y: 
    addi $s1, $zero, 32
    beq $s0, $s1, clear_done #branch when y == 32 (end of display) 
    
    addi $s2, $zero, 0 #Set x = 0 
clear_x: #clearing an entire row
    addi $s3, $zero, 32 
    beq $s2, $s3, next_row #branch when x == 32 (end of row)
    add $a0, $s2, $zero
    add $a1, $s0, $zero
    lw $a2, black
    jal DRAW_SQUARE
    addi $s2, $s2, 1 #move x to the right by 1 
    j clear_x
next_row: #move to next row or check if we were on the last row. 
    addi $s0, $s0, 1
    j clear_y #checks if we just cleared the last row, if not reset the new row. 
clear_done:
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    
    
DRAW_BORDER: 
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    #putting in BOTTOM wall of grid
    addi $s0, $zero, 2 #left side of BOTTOM wall
    addi $s1, $zero, 10 #10 pixels wide
    addi $s2, $zero, 26 #Start of wall on the y axis
bottom_wall:
    beq $s0, $s1, bottom_done 
    add $a0, $s0, $zero
    add $a1, $s2, $zero
    lw $a2, grey
    jal DRAW_SQUARE
    addi $s0, $s0, 1
    j bottom_wall
bottom_done:

    #putting in LEFT wall of grid
    addi $s0, $zero, 5 #top of left wall
    addi $s1, $zero, 27 #bottom of wall height
    addi $s2, $zero, 2 #wall x-axis coordinate
left_wall:
    beq $s0, $s1, left_done 
    add $a0, $s2, $zero
    add $a1, $s0, $zero
    lw $a2, grey
    jal DRAW_SQUARE
    addi $s0, $s0, 1
    j left_wall
left_done:

    #putting in RIGHT wall of grid
    addi $s0, $zero, 5 #top of right wall
    addi $s1, $zero, 27 #23 pixels height
    addi $s2, $zero, 9 #wall x-axis coordinate
right_wall:
    beq $s0, $s1, right_done 
    add $a0, $s2, $zero
    add $a1, $s0, $zero
    lw $a2, grey
    jal DRAW_SQUARE
    addi $s0, $s0, 1
    j right_wall
right_done:
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    
RANDOM_GEM_COLOUR:
    #Generating random number from 0-5 for all 6 possible colours. 
    addi $v0, $zero, 42
    addi $a0, $zero, 0
    addi $a1, $zero, 6
    syscall

    addi $t4, $zero, 0
    beq  $a0, $t4, redGem #if random number is 0, gem is red
    addi $t4, $zero, 1
    beq  $a0, $t4, orangeGem #if random number is 1, gem is orange
    addi $t4, $zero, 2
    beq  $a0, $t4, yellowGem #if random number is 2, gem is yelllow
    addi $t4, $zero, 3
    beq  $a0, $t4, greenGem #if random number is 3, gem is green
    addi $t4, $zero, 4
    beq  $a0, $t4, blueGem #if random number is 4, gem is blue
    j purpleGem #random number must be 5, gem is purple
redGem:
    lw $v0, red
    jr $ra
orangeGem:
    lw $v0, orange
    jr $ra
yellowGem:
    lw $v0, yellow
    jr $ra
greenGem:
    lw $v0, green
    jr $ra
blueGem:
    lw $v0, blue
    jr $ra
purpleGem:
    lw $v0, purple
    jr $ra

    
STORE_GEM: 
    #INPUTS: 
    #$a0 = board x, $a1 = board y, $a2 = colour
    lw $t0, boardWidth #loading number of columns 
    mult $a1, $t0
    mflo $t1 #t1 = y * width
    add $t1, $t1, $a0 #t1 = t1 + x 
    sll $t1, $t1, 2 #t1 = t1 * 4
    la $t2, board
    add $t3, $t2, $t1
    sw $a2, 0($t3) #Store gem colour 
    jr $ra
    
LOCK_GEM_COL: 
    #Turns the falling column of gems into fixed gems on the display. 
    addi $sp, $sp, -4
    sw   $ra, 0($sp) #Saving return address
    
    #converting screen pos to board pos 
    lw $s0, columnX #loading x position of falling column
    lw $s1, columnY #loading y position of top gem in falling column 
    addi $s0, $s0, -3 #converting to board position 
    addi $s1, $s1, -5 #converting to board position
    
    #Gem1 
    add $a0, $s0, $zero #input for board x pos
    add $a1, $s1, $zero #input for board y pos
    lw $a2, gem1Colour #input for colour 
    jal STORE_GEM
    
    #Gem2
    add $a0, $s0, $zero #input for board x pos
    addi $a1, $s1, 1 #input for board y pos
    lw $a2, gem2Colour #input for colour
    jal STORE_GEM
    
    #Gem3
    add $a0, $s0, $zero #input for board x pos
    addi $a1, $s1, 2 #input for board y pos
    lw $a2, gem3Colour #input for colour
    jal STORE_GEM
    
    lw   $ra, 0($sp) #go back to original return address
    addi $sp, $sp, 4
    jr $ra #return 
    
CREATE_NEW_GEM_COL:
    #Sets up the next gem column after the previous one lands. 
    addi $sp, $sp, -4
    sw $ra, 0($sp) #save return address
    
    addi $t0, $zero, 5 #reset x position
    sw $t0, columnX
    addi $t0, $zero, 2 #reset y position
    sw $t0, columnY
    
    #move nextGems into the current column 
    lw $t1, nextGem1Colour
    sw $t1, gem1Colour
    lw $t1, nextGem2Colour
    sw $t1, gem2Colour
    lw $t1, nextGem3Colour
    sw $t1, gem3Colour
    
    #gem1
    jal RANDOM_GEM_COLOUR #generate random colour for the new gem1
    sw $v0, nextGem1Colour
    #gem2
    jal RANDOM_GEM_COLOUR #generate random colour for the new gem2
    sw $v0, nextGem2Colour
    #gem3
    jal RANDOM_GEM_COLOUR#generate random colour for the new gem3
    sw $v0, nextGem3Colour
    
    lw $ra, 0($sp) 
    addi $sp, $sp, 4
    jr $ra 

DRAW_BOARD: 
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    addi $s0, $zero, 0 #Set $s0 = y = 0 
board_row: 
    lw $s1, boardHeight 
    beq $s0, $s1, board_done #Branch when $s0 reaches the bottom of the board
    
    addi $s2, $zero, 0 #set $s2 = x = 0
board_col: 
    lw $s3, boardWidth
    beq $s2, $s3, next_row_board #Branch when $s2 reaches the end of the row 
    
    #board index with y * width + x 
    lw $t0, boardWidth
    mult $s0, $t0
    mflo $t1
    add $t1, $t1, $s2 
    sll $t1, $t1, 2 #account for bytes by multiplying by 4
    
    la $t2, board
    add $t3, $t2, $t1
    lw $t4, 0($t3) #colour value of cell 
    
    beq $t4, $zero, skip_cell #if board cell is empty, no need to draw anything 
    
    #now convert board pos to screen pos where sreenX = boardX + 3, screenY = boardY + 5
    addi $a0, $s2, 3
    addi $a1, $s0, 5
    add $a2, $t4, $zero
    jal DRAW_SQUARE

skip_cell: 
    addi $s2, $s2, 1 #move to next sell after drawing or skipping previous cell 
    j board_col
next_row_board: 
    addi $s0, $s0, 1 #move to next row by incrementing y by 1. 
    j board_row
board_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    
GEM_DETECTION: 
    #Checks if the space inputted a gem
    #INPUTS:
    #$a0 = board x, $a1 = board y
    #OUTPUTS: 
    #$v0 = 0 if clear, $v0 = 1 if occupied
    lw $t0, boardWidth
    mult $a1, $t0
    mflo $t1
    add $t1, $t1, $a0
    sll $t1, $t1, 2
    
    la $t2, board 
    add $t3, $t2, $t1 #base address of board + bytes from the start of board 
    lw $t4, 0($t3) #$t4 is 0 if empty. 
    
    beq $t4, $zero, space_empty
    
    addi $v0, $zero, 1 #return 1, since space is not empty
    jr $ra
space_empty: 
    addi $v0, $zero, 0 #return 0, since space is empty
    jr $ra
    
FALLING_GEM_DETECTION: 
    #Checks if space below the falling gems is occupied by a gem. 
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    lw $t0, columnX
    addi $a0, $t0, -3 #x of board = columnX - 3
    
    lw $t1, columnY
    addi $a1, $t1, -2 #y of board = columnY - 2
    
    jal GEM_DETECTION
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    
LEFT_GEM_DETECTION:
    #Checks if there are gems to the left of the current falling gem column
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    lw $t0, columnX
    lw $t1, columnY
    
    addi $a0, $t0, -4 #moving one over to the left of the column of gems 
    addi $a1, $t1, -3 #checking on the level of the bottom gem since thats where the gems will collide first.
    
    jal GEM_DETECTION

    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    
RIGHT_GEM_DETECTION:
    #Checks if there are gems to the right of the current falling gem column
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    lw $t0, columnX
    lw $t1, columnY
    
    addi $a0, $t0, -2 #looking over over the the right of the column of gems
    addi $a1, $t1, -3 #checking at the bottom level of the column 
    
    jal GEM_DETECTION

    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    
VERTICAL_MATCH:
    #Check the entire board for 3 gems of the same colour lining up vertically. 
    #for every cell, check the 2 cells below it and see if the colours of the gems in the cells match. 
    addi $sp, $sp, -16
    #Saving registers
    sw $ra, 0($sp)
    sw $s2, 4($sp)
    sw $s3, 8($sp)
    sw $s4, 12($sp)
    
    addi $s0, $zero, 0 #set y = 0 
outer_y: 
    addi $t0, $zero, 19 #Stop at y = 18 since you dont need to check the bottom 2 rows.
    beq $s0, $t0, done_match 
    
    addi $s1, $zero, 0 #set x = 0 
outer_x: 
    lw $t1, boardWidth
    beq $s1, $t1, next_y #branch to next_y once you reach the end of a row
    
    #Now get colour at (x, y) 
    add $a0, $s1, $zero 
    add $a1, $s0, $zero
    jal GET_CELL 
    add $s2, $v0, $zero #$s2 = colour of gem at (x, y)
    
    beq $s2, $zero, skip_check #only check coloured cells  
    
    #get colour at (x, y+1) 
    add $a0, $s1, $zero
    addi $a1, $s0, 1
    jal GET_CELL 
    add $s3, $v0, $zero #$s3 = colour of gem at (x, y+1)
    
    #get colour at (x, y+2)
    add $a0, $s1, $zero
    addi $a1, $s0, 2
    jal GET_CELL 
    add $s4, $v0, $zero #$s4 = colour of gem at (x, y+2)
    
    #compare the 3 colours
    #goes to skip_check unless all 3 are the same
    bne $s2, $s3, skip_check 
    bne $s2, $s4, skip_check 
    
    addi $t2, $zero, 1
    sw $t2, matchFound 
    #Match found, so clear the 3 gems 
    add $a0, $s1, $zero
    add $a1, $s0, $zero
    jal CLEAR_CELL 

    add $a0, $s1, $zero
    addi $a1, $s0, 1
    jal CLEAR_CELL 

    add $a0, $s1, $zero
    addi $a1, $s0, 2
    jal CLEAR_CELL 
    
skip_check: 
    addi $s1, $s1, 1
    j outer_x 
next_y: 
    addi $s0, $s0, 1 #moving to next column
    j outer_y
done_match: 
    lw $ra, 0($sp)
    lw $s2, 4($sp)
    lw $s3, 8($sp)
    lw $s4, 12($sp)
    addi $sp, $sp, 16
    jr $ra
    
HORIZONTAL_MATCH:
    #Check for 3 gems of the same colour lined up horiztonally. 
    addi $sp, $sp, -16
    sw $ra, 0($sp)
    sw $s2, 4($sp)
    sw $s3, 8($sp)
    sw $s4, 12($sp)
    
    addi $s0, $zero, 0
horizontal_outer_y:
    lw $t0, boardHeight
    beq $s0, $t0, horizontal_done
    
    addi $s1, $zero, 0
horiztonal_outer_x: 
    addi $t1, $zero, 4 #stop at x = 3
    beq $s1, $t1, horizontal_next_y 
    
    #Checking (x, y)
    add $a0, $s1, $zero
    add $a1, $s0, $zero
    jal GET_CELL
    add $s2, $v0, $zero
    beq $s2, $zero, horizontal_skip_check  #skip if cell is empty 
    
    #Checking (x+1, y)
    addi $a0, $s1, 1
    add $a1, $s0, $zero
    jal GET_CELL 
    add $s3, $v0, $zero
    
    #Checking (x+2, y)
    addi $a0, $s1, 2
    add  $a1, $s0, $zero
    jal  GET_CELL
    add  $s4, $v0, $zero

    #go to horizontal_skip_check unless all 3 gems are the same colour. 
    bne $s2, $s3, horizontal_skip_check 
    bne $s2, $s4, horizontal_skip_check 
    
    addi $t2, $zero, 1
    sw $t2, matchFound 
    #Match found so clear gems 
    add $a0, $s1, $zero
    add $a1, $s0, $zero
    jal CLEAR_CELL 
    
    addi $a0, $s1, 1
    add  $a1, $s0, $zero
    jal  CLEAR_CELL

    addi $a0, $s1, 2
    add  $a1, $s0, $zero
    jal  CLEAR_CELL
    
horizontal_skip_check: 
    addi $s1, $s1, 1
    j horiztonal_outer_x
horizontal_next_y: 
    addi $s0, $s0, 1
    j horizontal_outer_y
horizontal_done: 
    lw $ra, 0($sp)
    lw $s2, 4($sp)
    lw $s3, 8($sp)
    lw $s4, 12($sp)
    addi $sp, $sp, 16
    jr $ra
    
RIGHT_DIAG_MATCH: 
    #Checks for 3 gems lined up diagonally, down to the right. 
    addi $sp, $sp, -16
    sw $ra, 0($sp)
    sw $s2, 4($sp)
    sw $s3, 8($sp)
    sw $s4, 12($sp)
    
    addi $s0, $zero, 0
right_diag_outer_y: 
    addi $t0, $zero, 19 #stops at y=18
    beq $s0, $t0, right_diag_done   
    
    addi $s1, $zero, 0
right_diag_outer_x: 
    addi $t1, $zero, 4 #stops at x=3
    beq $s1, $t1, right_diag_next_y
    
    add  $a0, $s1, $zero
    add  $a1, $s0, $zero
    jal  GET_CELL
    add  $s2, $v0, $zero #store the colour of the gem in $s2
    
    beq  $s2, $zero, right_diag_skip

    #move down 1 and right 1 for the next cell diagonally. 
    addi $a0, $s1, 1
    addi $a1, $s0, 1
    jal  GET_CELL
    add  $s3, $v0, $zero #store the colour of the gem in $s3

    #move down 2 and right 2 from the main cell for the next cell. 
    addi $a0, $s1, 2
    addi $a1, $s0, 2
    jal  GET_CELL
    add  $s4, $v0, $zero #store the colour of the gem in $s4

    #check for the matches across the diagonal
    bne $s2, $s3, right_diag_skip
    bne $s2, $s4, right_diag_skip
    
    addi $t2, $zero, 1
    sw $t2, matchFound 
    #clear the diagonal gems since match found 
    add  $a0, $s1, $zero
    add  $a1, $s0, $zero
    jal  CLEAR_CELL

    addi $a0, $s1, 1
    addi $a1, $s0, 1
    jal  CLEAR_CELL

    addi $a0, $s1, 2
    addi $a1, $s0, 2
    jal  CLEAR_CELL
    
right_diag_skip: 
    addi $s1, $s1, 1 #move to the next column 
    j right_diag_outer_x 
right_diag_next_y:
    addi $s0, $s0, 1 #move to the next row 
    j right_diag_outer_y 
right_diag_done:
    lw $ra, 0($sp)
    lw $s2, 4($sp)
    lw $s3, 8($sp)
    lw $s4, 12($sp)
    addi $sp, $sp, 16
    jr $ra
    
LEFT_DIAG_MATCH:
    #Checks for 3 gems to line up diagonally, down to the left. 
    addi $sp, $sp, -16
    sw $ra, 0($sp)
    sw $s2, 4($sp)
    sw $s3, 8($sp)
    sw $s4, 12($sp)
    
    addi $s0, $zero, 0
left_diag_outer_y: 
    addi $t0, $zero, 19 #stops at y=18
    beq $s0, $t0, left_diag_done   
    
    addi $s1, $zero, 2
left_diag_outer_x: 
    addi $t1, $zero, 6 #stops at x=5
    beq $s1, $t1, left_diag_next_y
    
    add  $a0, $s1, $zero
    add  $a1, $s0, $zero
    jal  GET_CELL
    add  $s2, $v0, $zero
    beq  $s2, $zero, left_diag_skip

    #moves down and left by 1 for the next cell in the diagonal
    addi $a0, $s1, -1
    addi $a1, $s0, 1
    jal  GET_CELL
    add  $s3, $v0, $zero

    #moves down and left by 2 from main cell for the next cell in the diagonal 
    addi $a0, $s1, -2
    addi $a1, $s0, 2
    jal  GET_CELL
    add  $s4, $v0, $zero

    #checks matches 
    bne $s2, $s3, left_diag_skip
    bne $s2, $s4, left_diag_skip
    
    addi $t2, $zero, 1
    sw $t2, matchFound 
    #clear the diagonal gems since match found 
    add  $a0, $s1, $zero
    add  $a1, $s0, $zero
    jal  CLEAR_CELL

    addi $a0, $s1, -1
    addi $a1, $s0, 1
    jal  CLEAR_CELL

    addi $a0, $s1, -2
    addi $a1, $s0, 2
    jal  CLEAR_CELL
    
left_diag_skip: 
    addi $s1, $s1, 1
    j left_diag_outer_x 
left_diag_next_y:
    addi $s0, $s0, 1
    j left_diag_outer_y 
left_diag_done:
    lw $ra, 0($sp)
    lw $s2, 4($sp)
    lw $s3, 8($sp)
    lw $s4, 12($sp)
    addi $sp, $sp, 16
    jr $ra

CHECK_ALL_MATCHES: 
    #Checks all possible match configurations over the entire board. 
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    sw $zero, matchFound
    
    jal VERTICAL_MATCH
    jal HORIZONTAL_MATCH
    jal RIGHT_DIAG_MATCH
    jal LEFT_DIAG_MATCH
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    
GET_CELL:
    #inputs: 
    #$a0 = x pos on board, #a1 = y pos on board 
    #returns 0 if cell is empty or colour of gem if not empty. 
    lw $t0, boardWidth
    mult $a1, $t0
    mflo $t1
    add $t1, $t1, $a0 
    sll $t1, $t1, 2 
    
    la $t2, board
    add $t3, $t2, $t1
    lw $v0, 0($t3) 
    
    jr $ra
    
CLEAR_CELL:
    #removes a gem from a cell 
    lw $t0, boardWidth
    mult $a1, $t0
    mflo $t1
    add $t1, $t1, $a0 
    sll $t1, $t1, 2 

    la $t2, board
    add $t3, $t2, $t1
    lw $t4, 0($t3)
    beq $t4, $zero, clear_cell_done 
    
    sw $zero, 0($t3) #removes the colour value of the cell and replaces with 0 to indicate empty for the re draws. 
    
    lw $t5, clearedThisTurn
    addi $t5, $t5, 1
    sw $t5, clearedThisTurn
clear_cell_done: 
    jr $ra
    
SET_GRAVITY:
    #allows the set gems to fall down once a match clears gems below it. 
    #start at the bottom row, and check one entire column at a time. 
    addi $sp, $sp, -12
    sw $ra, 0($sp)
    sw $s2, 4($sp)
    sw $s3, 8($sp)
    
    addi $s1, $zero, 0 #x = 0
gravity_x: 
    lw $t0, boardWidth
    beq $s1, $t0, gravity_done #done when you finish the last column 
    
    addi $s0, $zero, 20 #y = bottom 
gravity_y: 
    blez $s0, check_zero_y_gravity 
    j continue_y_gravity 
check_zero_y_gravity: 
    beq $s0, $zero, continue_y_gravity 
    j next_column 
continue_y_gravity: 
    add $a0, $s1, $zero
    add $a1, $s0, $zero
    jal GET_CELL 
    bne $v0, $zero, y_next #go to next cell if it has a gem.  
    
    addi $s2, $s0, -1 #if cell is empty go upwards 
    
search_up: 
    blez $s2, check_zero
    j continue_search 

check_zero:
    beq $s2, $zero, continue_search #if the cell above is empty go to continue_search to go up again.  
    j y_next

continue_search: 
    add $a0, $s1, $zero
    add $a1, $s2, $zero
    jal GET_CELL 
    beq $v0, $zero, search_next 
    
    #move gem down 
    add $s3, $v0, $zero 
    
    add $a0, $s1, $zero
    add $a1, $s0, $zero
    add $a2, $s3, $zero
    jal STORE_GEM
   
     #clear original gem 
    add $a0, $s1, $zero
    add $a1, $s2, $zero
    jal CLEAR_CELL 
    
    j y_next
search_next: 
    addi $s2, $s2, -1
    j search_up
y_next: 
    addi $s0, $s0, -1 #move up by 1. 
    j gravity_y
next_column: 
    addi $s1, $s1, 1
    j gravity_x 
gravity_done: 
    lw $ra, 0($sp)
    lw $s2, 4($sp)
    lw $s3, 8($sp)
    addi $sp, $sp, 12
    jr $ra

CHAIN_REACTION_MATCH: 
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    addi $t0, $zero, 1
    sw $t0, chainDepth
reaction: 
    sw $zero, clearedThisTurn
    jal CHECK_ALL_MATCHES
    lw $t0, matchFound
    beq $t0, $zero, reaction_done 
    
    #Account for chain depth
    #Points = clearedTHisTurn * 10 * chainDepth
    lw $t1, clearedThisTurn
    addi $t2, $zero, 10 
    mult $t1, $t2
    mflo $t3
    
    lw $t4, chainDepth
    mult $t3, $t4
    mflo $t5
    
    lw $t6, score
    add $t6, $t6, $t5
    sw $t6, score
    
    jal SET_GRAVITY
    lw $t4, chainDepth
    addi $t4, $t4, 1
    sw $t4, chainDepth
    j reaction
reaction_done: 
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    
CHECK_GAME_OVER: 
    #Checks if the gem column has reached the top of the grid
    #returns 1 if game is over 
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    addi $s0, $zero, 0 #set x = 0 
game_over_loop: 
    lw $t0, boardWidth
    beq $s0, $t0, game_not_over 
    
    add $a0, $s0, $zero 
    addi $a1, $zero, 0
    jal GET_CELL 
    
    bne $v0, $zero, game_is_over 
    addi $s0, $s0, 1
    j game_over_loop
game_is_over: 
    addi $v0, $zero, 1
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
game_not_over:
    addi $v0, $zero, 0
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

DROP_ONE_STEP:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    lw $t4, columnY
    addi $t5, $zero, 23
    beq $t4, $t5, drop_hit_bottom
    
    jal FALLING_GEM_DETECTION
    addi $t6, $zero, 1 
    beq $v0, $t6, drop_hit_existing_gem
    lw $t4, columnY
    addi $t4, $t4, 1
    sw $t4, columnY
    j drop_done

drop_hit_bottom: 
    jal LOCK_GEM_COL
    jal CHAIN_REACTION_MATCH
    jal CHECK_GAME_OVER
    addi $t0, $zero, 1
    beq $v0, $t0, set_game_over
    jal CREATE_NEW_GEM_COL
    j drop_done

drop_hit_existing_gem:
    lw $t7, columnY
    addi $t8, $zero, 5
    blt $t7, $t8, set_game_over
    
    jal LOCK_GEM_COL
    jal CHAIN_REACTION_MATCH
    jal CHECK_GAME_OVER
    addi $t0, $zero, 1
    beq $v0, $t0, set_game_over
    jal CREATE_NEW_GEM_COL
    j drop_done

set_game_over: 
    addi $t0, $zero, 1
    sw $t0, gameOver
    lw $t1, score
    lw $t2, highScore
    slt $t3, $t2, $t1 #$t3 = 1 if current score beats high score 
    beq $t3, $zero, drop_done
    sw $t1, highScore
    j drop_done

drop_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

DRAW_PAUSED_TEXT:
    addi $sp, $sp, -16
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    sw $s2, 12($sp)
    
    lw $s2, grey #colour of pause symbol
    
    addi $s0, $zero, 11 #y of start of pause symbol 
left_bar: 
    addi $a0, $zero, 13 #x of left bar
    add $a1, $s0, $zero #y 
    add $a2, $s2, $zero #colour 
    jal DRAW_SQUARE
    
    addi $s0, $s0, 1
    addi $s1, $zero, 18
    bne $s0, $s1, left_bar
    
    addi $s0, $zero, 11 #reset y back for right bar 
right_bar: 
    addi $a0, $zero, 16 #x of right bar 
    add $a1, $s0, $zero
    add $a2, $s2, $zero 
    jal DRAW_SQUARE
    
    addi $s0, $s0, 1
    addi $s1, $zero, 18
    bne $s0, $s1, right_bar
    
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    addi $sp, $sp, 16
    jr $ra

DRAW_GAME_OVER_SYMBOL: 
    addi $sp, $sp, -16
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    sw $s2, 12($sp)
    
    lw $s2, red #colour of X 
    
    addi $s0, $zero, 0
x: 
    addi $t0, $zero, 7
    add $a0, $t0, $s0
    addi $t1, $zero, 8
    add $a1, $t1, $s0
    add $a2, $s2, $zero
    jal DRAW_SQUARE
    
    addi $t2, $zero, 18
    sub $a0, $t2, $s0
    addi $t3, $zero, 8
    add $a1, $t3, $s0
    add $a2, $s2, $zero
    jal DRAW_SQUARE
    
    addi $s0, $s0, 1
    addi $s1, $zero, 12
    bne $s0, $s1, x 
    
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    addi $sp, $sp, 16
    jr $ra
    
BOARD_CLEAR: 
    la $t0, board
    addi $t1, $zero, 126 #there is 126 cells in the board 
clear_board: 
    beq $t1, $zero, clear_board_done 
    sw $zero, 0($t0) 
    addi $t0, $t0, 4
    addi $t1, $t1, -1 
    j clear_board
clear_board_done:
    jr $ra
    
DRAW_SCORE: 
    addi $sp, $sp, -8
    sw $ra, 0($sp)
    sw $s0, 4($sp) 
    lw $t0, score  
    addi $t1, $zero, 100
    div  $t0, $t1
    mflo $t2              # hundreds digit
    mfhi $t3              # remainder for the tens and ones digit 
    addi $t1, $zero, 10
    div  $t3, $t1
    mflo $t4              # tens digit 
    mfhi $t5              # remainder is the ones digit 
    addi $a0, $zero, 13 #Hundreds digit y value 
    addi $a1, $zero, 2 #hundreds digit x value 
    add  $a2, $t2, $zero #hundreds value 
    jal  DRAW_DIGIT 

    addi $a0, $zero, 17 #tens digit y value 
    addi $a1, $zero, 2 #tens digit x value
    add  $a2, $t4, $zero #tens digit value 
    jal  DRAW_DIGIT

    addi $a0, $zero, 21 #ones digit y value 
    addi $a1, $zero, 2 #ones digit x value 
    add  $a2, $t5, $zero #ones digit value 
    jal  DRAW_DIGIT

    lw $ra, 0($sp)
    lw $s0, 4($sp)
    addi $sp, $sp, 8
    jr $ra

#Helper functions each of the 7 segments in a number 
DRAW_TOP: 
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    addi $a0, $s0, 0
    addi $a1, $s1, 0
    lw $a2, white
    jal DRAW_SQUARE
    addi $a0, $s0, 1
    addi $a1, $s1, 0
    lw $a2, white
    jal DRAW_SQUARE
    addi $a0, $s0, 2
    addi $a1, $s1, 0
    lw $a2, white
    jal DRAW_SQUARE
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    
DRAW_MIDDLE:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    addi $a0, $s0, 0
    addi $a1, $s1, 2
    lw $a2, white
    jal DRAW_SQUARE
    addi $a0, $s0, 1
    addi $a1, $s1, 2
    lw $a2, white
    jal DRAW_SQUARE
    addi $a0, $s0, 2
    addi $a1, $s1, 2
    lw $a2, white
    jal DRAW_SQUARE
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    
DRAW_BOTTOM:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    addi $a0, $s0, 0
    addi $a1, $s1, 4
    lw $a2, white
    jal DRAW_SQUARE
    addi $a0, $s0, 1
    addi $a1, $s1, 4
    lw $a2, white
    jal DRAW_SQUARE
    addi $a0, $s0, 2
    addi $a1, $s1, 4
    lw $a2, white
    jal DRAW_SQUARE
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    
DRAW_UPPERLEFT:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    addi $a0, $s0, 0
    addi $a1, $s1, 1
    lw $a2, white
    jal DRAW_SQUARE
    addi $a0, $s0, 0
    addi $a1, $s1, 2
    lw $a2, white
    jal DRAW_SQUARE
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    
DRAW_LOWERLEFT:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    addi $a0, $s0, 0
    addi $a1, $s1, 2
    lw $a2, white
    jal DRAW_SQUARE

    addi $a0, $s0, 0
    addi $a1, $s1, 3
    lw $a2, white
    jal DRAW_SQUARE

    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    
DRAW_UPPERRIGHT:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    addi $a0, $s0, 2
    addi $a1, $s1, 1
    lw $a2, white
    jal DRAW_SQUARE

    addi $a0, $s0, 2
    addi $a1, $s1, 2
    lw $a2, white
    jal DRAW_SQUARE

    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

DRAW_LOWERRIGHT:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    addi $a0, $s0, 2
    addi $a1, $s1, 2
    lw $a2, white
    jal DRAW_SQUARE

    addi $a0, $s0, 2
    addi $a1, $s1, 3
    lw $a2, white
    jal DRAW_SQUARE

    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

DRAW_DIGIT: 
    addi $sp, $sp, -16
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    sw $s2, 12($sp)
    add $s0, $a0, $zero # x starting point 
    add $s1, $a1, $zero # y starting point 
    add $s2, $a2, $zero # digit
    
    addi $t0, $zero, 0
    beq $s2, $t0, digit_0
    addi $t0, $zero, 1
    beq $s2, $t0, digit_1 
    addi $t0, $zero, 2
    beq $s2, $t0, digit_2
    addi $t0, $zero, 3
    beq $s2, $t0, digit_3 
    addi $t0, $zero, 4
    beq  $s2, $t0, digit_4
    addi $t0, $zero, 5
    beq  $s2, $t0, digit_5
    addi $t0, $zero, 6
    beq  $s2, $t0, digit_6
    addi $t0, $zero, 7
    beq  $s2, $t0, digit_7
    addi $t0, $zero, 8
    beq  $s2, $t0, digit_8
    addi $t0, $zero, 9
    beq  $s2, $t0, digit_9
    j digit_done 

digit_0:
    jal DRAW_TOP
    jal DRAW_BOTTOM
    jal DRAW_UPPERLEFT
    jal DRAW_LOWERLEFT
    jal DRAW_UPPERRIGHT
    jal DRAW_LOWERRIGHT
    addi $a0, $s0, 0
    addi $a1, $s1, 2
    lw $a2, white
    jal DRAW_SQUARE
    addi $a0, $s0, 2
    addi $a1, $s1, 2
    lw $a2, white
    jal DRAW_SQUARE
    j digit_done

digit_1:
    addi $a0, $s0, 1
    addi $a1, $s1, 0
    lw $a2, white
    jal DRAW_SQUARE
    addi $a0, $s0, 1
    addi $a1, $s1, 1
    lw $a2, white
    jal DRAW_SQUARE
    addi $a0, $s0, 1
    addi $a1, $s1, 2
    lw $a2, white
    jal DRAW_SQUARE
    addi $a0, $s0, 1
    addi $a1, $s1, 3
    lw $a2, white
    jal DRAW_SQUARE
    addi $a0, $s0, 1
    addi $a1, $s1, 4
    lw $a2, white
    jal DRAW_SQUARE
    j digit_done

digit_2:
    jal DRAW_TOP
    jal DRAW_MIDDLE
    jal DRAW_BOTTOM
    jal DRAW_UPPERRIGHT
    jal DRAW_LOWERLEFT
    j digit_done
    
digit_3:
    jal DRAW_TOP
    jal DRAW_MIDDLE
    jal DRAW_BOTTOM
    jal DRAW_UPPERRIGHT
    jal DRAW_LOWERRIGHT
    j digit_done
    
digit_4:
    addi $a0, $s0, 0
    addi $a1, $s1, 0
    lw $a2, white
    jal DRAW_SQUARE
    addi $a0, $s0, 0
    addi $a1, $s1, 1
    lw $a2, white
    jal DRAW_SQUARE
    addi $a0, $s0, 0
    addi $a1, $s1, 2
    lw $a2, white
    jal DRAW_SQUARE

    addi $a0, $s0, 1
    addi $a1, $s1, 2
    lw $a2, white
    jal DRAW_SQUARE
    addi $a0, $s0, 2
    addi $a1, $s1, 2
    lw   $a2, white
    jal DRAW_SQUARE
    addi $a0, $s0, 2
    addi $a1, $s1, 0
    lw $a2, white
    jal DRAW_SQUARE
    addi $a0, $s0, 2
    addi $a1, $s1, 1
    lw $a2, white
    jal DRAW_SQUARE

    addi $a0, $s0, 2
    addi $a1, $s1, 2
    lw $a2, white
    jal DRAW_SQUARE
    addi $a0, $s0, 2
    addi $a1, $s1, 3
    lw $a2, white
    jal DRAW_SQUARE
    addi $a0, $s0, 2
    addi $a1, $s1, 4
    lw $a2, white
    jal DRAW_SQUARE
    j digit_done
    
digit_5:
    jal DRAW_TOP
    jal DRAW_MIDDLE
    jal DRAW_BOTTOM
    jal DRAW_UPPERLEFT
    jal DRAW_LOWERRIGHT
    j digit_done
    
digit_6:
    jal DRAW_TOP
    jal DRAW_MIDDLE
    jal DRAW_BOTTOM
    jal DRAW_UPPERLEFT
    jal DRAW_LOWERLEFT
    jal DRAW_LOWERRIGHT
    j digit_done
    
digit_7:
    jal DRAW_TOP
    jal DRAW_UPPERRIGHT
    jal DRAW_LOWERRIGHT
    j digit_done
    
digit_8:
    jal DRAW_TOP
    jal DRAW_MIDDLE
    jal DRAW_BOTTOM
    jal DRAW_UPPERLEFT
    jal DRAW_LOWERLEFT
    jal DRAW_UPPERRIGHT
    jal DRAW_LOWERRIGHT
    j digit_done
    
digit_9:
    jal DRAW_TOP
    jal DRAW_MIDDLE
    jal DRAW_BOTTOM
    jal DRAW_UPPERLEFT
    jal DRAW_UPPERRIGHT
    jal DRAW_LOWERRIGHT
    j digit_done

digit_done: 
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    addi $sp, $sp, 16
    jr $ra
    
UPDATE_GRAVITY_SPEED: 
    lw $t0, score
    addi $t1, $zero, 300
    slt $t2, $t0, $t1
    beq $t2, $zero, speed_8 
    addi $t1, $zero, 200 
    slt $t2, $t0, $t1
    beq $t2, $zero, speed_12 
    addi $t1, $zero, 100
    slt $t2, $t0, $t1
    beq $t2, $zero, speed_16 
speed_20: 
    addi $t3, $zero, 20 
    sw $t3, gravityValue
    jr $ra
speed_16: 
    addi $t3, $zero, 16 
    sw $t3, gravityValue
    jr $ra
speed_12: 
    addi $t3, $zero, 12
    sw $t3, gravityValue
    jr $ra
speed_8: 
    addi $t3, $zero, 8 
    sw $t3, gravityValue
    jr $ra
    
DRAW_NEXT_COLUMN: 
    #Draw a preview of the next falling column 
    addi $sp, $sp, -4 
    sw $ra, 0($sp)
    
    #top gem 
    addi $a0, $zero, 13
    addi $a1, $zero, 10 
    lw $a2, nextGem1Colour
    jal DRAW_SQUARE
    
    #middle gem 
    addi $a0, $zero, 13
    addi $a1, $zero, 11
    lw $a2, nextGem2Colour
    jal DRAW_SQUARE
    
    #bottom gem 
    addi $a0, $zero, 13
    addi $a1, $zero, 12
    lw $a2, nextGem3Colour
    jal DRAW_SQUARE
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

DRAW_HIGH_SCORE: 
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    lw $t0, highScore

    addi $t1, $zero, 100
    div  $t0, $t1
    mflo $t2              # hundreds digit
    mfhi $t3              # remainder for the tens and ones digit 
    addi $t1, $zero, 10
    div  $t3, $t1
    mflo $t4              # tens digit 
    mfhi $t5              # remainder is the ones digit 
    
    addi $a0, $zero, 13
    addi $a1, $zero, 16
    add $a2, $t2, $zero
    jal DRAW_DIGIT
    
    addi $a0, $zero, 17
    addi $a1, $zero, 16
    add $a2, $t4, $zero
    jal DRAW_DIGIT
    
    addi $a0, $zero, 21
    addi $a1, $zero, 16
    add $a2, $t5, $zero
    jal DRAW_DIGIT
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

.globl main

    # Run the game.
main:
    jal RANDOM_GEM_COLOUR
    sw $v0, gem1Colour
    
    jal RANDOM_GEM_COLOUR
    sw $v0, gem2Colour
    
    jal RANDOM_GEM_COLOUR
    sw $v0, gem3Colour
    
    
    jal RANDOM_GEM_COLOUR
    sw $v0, nextGem1Colour
    
    jal RANDOM_GEM_COLOUR
    sw $v0, nextGem2Colour
    
    jal RANDOM_GEM_COLOUR
    sw $v0, nextGem3Colour

game_loop:
    #KEYBOARD CHECKS: 
    lw $t0, ADDR_KBRD 
    lw $t1, 0($t0) 
    beq $t1, $zero, no_input #if no key is pressed then skip
    
    lw $t2, 4($t0)
    
    beq $t2, 0x71, exit_game #if q was pressed exit the game
    beq $t2, 0x72, reset_game #if r was pressed reset the game 
    
    lw $t4, gameOver
    bne $t4, $zero, no_input 
    
    beq $t2, 0x70, pause_game #if p was pressed, pause the game 
    
    lw $t3, paused 
    bne $t3, $zero, no_input
    
    beq $t2, 0x61, move_left #if a was pressed, move the gem column left by 1
    
    beq $t2, 0x64, move_right #if d was pressed, mvoe the gem column right by 1 
    
    beq $t2, 0x73, move_down #if s was pressed, move the gem column down by 1 
    
    beq $t2, 0x77, change_order #if w was pressed, change order of column  
    j no_input
exit_game: 
    addi $v0, $zero, 10
    syscall
    
move_left: 
    lw $t4, columnX
    addi $t5, $zero, 3 #cant move past this on x-axis due to border
    beq $t4, $t5, no_input #at the left edge of border so can't move further

    #if gems are blocking on the left, dont move
    jal LEFT_GEM_DETECTION
    addi $t6, $zero, 1
    beq $v0, $t6, no_input
    
    lw $t4, columnX
    addi $t4, $t4, -1 
    sw $t4, columnX 
    j no_input
    
move_right: 
    lw $t4, columnX
    addi $t5, $zero, 8 #cant move past this on x-axis due to border
    beq $t4, $t5, no_input #at the right edge of border so can't move further

    #if gems are blocking on the right, dont move
    jal RIGHT_GEM_DETECTION
    addi $t6, $zero, 1
    beq $v0, $t6, no_input
    
    lw $t4, columnX
    addi $t4, $t4, 1 
    sw $t4, columnX 
    j no_input
    
move_down: 
    jal DROP_ONE_STEP
    j no_input
    
change_order:
    #rotate the order of the colours down by 1. 
    lw $t4, gem1Colour
    lw $t5, gem2Colour
    lw $t6, gem3Colour
    
    sw $t6, gem1Colour
    sw $t4, gem2Colour
    sw $t5, gem3Colour
    
    j no_input

pause_game: 
    lw $t3, paused
    xori $t3, $t3, 1 
    sw $t3, paused
    j no_input
    
reset_game: 
    jal BOARD_CLEAR
    addi $t0, $zero, 5
    sw $t0, columnX 
    addi $t0, $zero, 2
    sw $t0, columnY
    sw $zero, paused
    sw $zero, gameOver
    sw $zero, gravityCounter
    addi $t0, $zero, 20
    sw $t0, gravityValue
    sw $zero, matchFound 
    sw $zero, score
    sw $zero, clearedThisTurn
    sw $zero, chainDepth
    jal RANDOM_GEM_COLOUR
    sw $v0, gem1Colour
    jal RANDOM_GEM_COLOUR
    sw $v0, gem2Colour
    jal RANDOM_GEM_COLOUR
    sw $v0, gem3Colour
    jal RANDOM_GEM_COLOUR
    sw $v0, nextGem1Colour
    jal RANDOM_GEM_COLOUR
    sw $v0, nextGem2Colour
    jal RANDOM_GEM_COLOUR
    sw $v0, nextGem3Colour
    j no_input

no_input:
    lw $t4, gameOver
    bne $t4, $zero, redraw
    
    lw $t0, paused
    bne $t0, $zero, redraw
    
    jal UPDATE_GRAVITY_SPEED
    
    lw $t0, gravityCounter
    addi $t0, $t0, 1
    sw $t0, gravityCounter
    lw $t1, gravityValue
    slt $t2, $t0, $t1 #set $t2 to 1 if gravityCounter < gravityValue 
    bne $t2, $zero, redraw 
    sw $zero, gravityCounter
    jal DROP_ONE_STEP
    
redraw:
    jal SET_BLACK
    jal DRAW_BORDER
    jal DRAW_BOARD
    jal DRAW_SCORE
    jal DRAW_NEXT_COLUMN
    jal DRAW_HIGH_SCORE
    
    lw $t4, gameOver
    bne $t4, $zero, draw_game_over_symbol 
    
    jal DRAW_GEM_COL
    
    lw $t0, paused
    beq $t0, $zero, after_pause_draw
    jal DRAW_PAUSED_TEXT
    j after_pause_draw
    
draw_game_over_symbol:
    jal DRAW_GAME_OVER_SYMBOL 

after_pause_draw:
    addi $v0, $zero, 32
    addi $a0, $zero, 50
    syscall
    j game_loop

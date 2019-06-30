   .data #data segment for static addressing directly on memory
    triangle: .asciiz "*"
    empty:    .asciiz " "
    newline:  .asciiz "\n"

   .text #text segment for code
   .globl main
   
main:  
	
	#Here is the depth-of-recursion (order) value for the fractal. Set between 1-6.
	li $s0, 5
	
	jal calc_length
	
	jal generate_array
	move $s2, $v0 		#Save array address in s2
	
	#####INITIALIZE THE AUTOMATON#######################
	addi $t0, $s1, 1
	srl $a0, $t0, 1 #Middle element of the array (initialize step 1 of automaton)
	
	jal get_address
	move $t0, $v0   #Address of middle number
	
	li $t1, 1
	sw $t1, 0($t0)  #Set true in middle of triangle
	####################################################
	
	#Calculate the height of the fractal
	addi $s3, $s1, 1
	srl $s3, $s3, 1
	
	#Print first generation
	jal print_automaton
	addi $s3, $s3, -1
	
	bne $s3, $zero, printer
	j terminate #quit if we do not make child automata
	
	#Generate the next stage and print
	printer:
		#generate fractal
		jal generate_automaton
		#print generation
		jal print_automaton
		
		addi $s3, $s3, -1
		bne $s3, $zero, printer	
		
	terminate:
	li $v0, 10
	syscall
	
	get_address:
		move $t0, $a0        #get input index [i]
		move $t1, $s2 
		next_add:
			beq $t0, $zero, return_add
			addi $t1, $t1, 4 #next word
			addi $t0, $t0, -1
			j next_add
		return_add:
			move $v0, $t1    #resulting address
			j $ra
	
	calc_length: #calculate the character length (width of triangle) needed for your fractal. store result in $s1.
		addi $t0, $s0, 1 #size is order + 1
		li $s1, 1  	 	 #default size
		
		bne $t0, $zero, shf_size
		
		j $ra
		
		shf_size:
			sll $s1, $s1, 1 			#multiply by 2
			addi $t0, $t0, -1 			#subtract iter
			bne $t0, $zero, shf_size
			
		j $ra
	
	generate_array:
		#dynamically allocate memory, size of print array
		li $v0, 9
		addi $t0, $s1, 1 #add 1 since triangle is odd
		sll $a0, $t0, 2  #multiply by 4 (word size)
		syscall
		
		move $t1, $v0 	 #get address of array
		bne $t0, $zero, fill_array
		
		j $ra
		
		fill_array:
			sw $zero, 0($t1) #set zero in array
			addi $t0, $t0, -1
			addi $t1, $t1, 4 #next word
			bne $t0, $zero, fill_array
		
		j $ra
	
	print_automaton: #Print the value of the array of your automaton
		
		move $t0, $s1 #get array size
		move $t1, $s2 #get array address
		
		li $v0, 4
		
		bne $t0, $zero, print_num
		
		j $ra
			
		print_num:
			lw $t2, 0($t1) #get number at address
			
			beq $t2, $zero, space
				la $a0, triangle
				j after_tri
			space:
				la $a0, empty
			
			after_tri:
				syscall
				
				addi $t1, $t1, 4 #go to next word
				addi $t0, $t0, -1 
				bne $t0, $zero, print_num
				
				la $a0, newline
				syscall
				
				j $ra
	
	generate_automaton: #Generate next step of fractal generation
		
		addi $sp, $sp, -4 #make room on stack
		
		sw $ra, 0($sp)    #save return address to stack
		jal generate_array
		lw $ra, 0($sp)    #restore return address
		addi $sp, $sp, 4
		
		move $t0, $v0     #clone address of array
		move $t1, $s1     #clone width of array for use below
		
		#now need to generate automaton based on RULE 90 (https://en.wikipedia.org/wiki/Rule_90)
		
		retrieve_num:
			lw $t2, 0($s2) #get number at address
			bne $t2, $zero, setter
				
			j next_num
			
			setter:
				#[i-1] = [i-1] ^ true
				lw $t5, -4($t0)
				xori $t5, $t5, 1
				sw $t5, -4($t0)
				#[i+1] = [i+1] ^ true
				lw $t5, 4($t0)
				xori $t5, $t5, 1
				sw $t5, 4($t0)
			
			next_num:	
			
				addi $t0, $t0, 4 #go to next word in new automaton
				addi $s2, $s2, 4 #go to next word in old automaton
				
				addi $t1, $t1, -1 
				bne $t1, $zero, retrieve_num
				
				move $s2, $v0 #set old automaton address to beginning of new automaton
				
				j $ra
# CS271-Computer_Architecture_-_Assembly_Language
Portfolio project for CS271 at Oregon State University


The primary purpose of this assignment was to reinforce concepts related to string primitive instructions and macros.


The requirements for this project were to write and test a MASM program to perform the following tasks:
  Implement and test two macros for string procesing:
    mGetString - Display a prompt, then get the user's keyboard input into a memory location.
    mDisplayString - Print the string stored in a specified memory location.
    
  Implement and test two procedures for signed integers which use string primitive instructions:
    ReadVal - Invoke the mGetString macro to get a string of digits, validate the digits and convert the ascii digits to its SDWORD representation, and store the value in a memory variable.
    WriteVal - Convert a numeric SDWORD value to ascii digits and invoke the mDisplayString macro to print the ascii.
    
  Write a test program which uses ReadVal and WriteVal procedures to get 10 valid integers from the user, store the values in an array, and display the integers, the integer sum, and integer average.


There were various conditions for the program:
  The user input validation needed to be done manually.
  Operations such as ReadInt, WriteInt, etc. that would trivialize the assignment were not allowed.
  Procedure parameters needed to be passed on the runtime stack and string needed to be passed by reference.
  Conversion routines needed to use LODSB and/or STOSB operators to deal with strings.
  Various other conditions related to good programming practice with Assembly.
  

There was an extra credit option to number each line of user input and display a running subtotal of the user's valid nubmers using the WriteVal procedure for 1 extra point.


Assignment result: 51/50
Feedback: Fantastic work, Alexander! Your program handled everything we threw at it, which isn't too common! In addition to functioning perfectly (as far as I could tell), your program was very cleanly written, well-organized, and well documented, which made it a pleasure to read. It looks like you really understood the fundamentals of MASM. I hope you found value in this course. Best of luck on the final and in your future endeavors!

# PDTEXT
PDTEXT(Programming DOS text editor)is a simple and minimal text editor for MS-DOS environments.
Designed for an Intel processor with 16-bit x86 architecture, it is also compatible with modern processors, unfortunately the operating system will not allow you to run programs in real mod, for this it is highly recommended to use an MS-DOS environment emulator.
It was developed completely in assembly, working in real mode, it relies only on the services of the BIOS that has become so universal on all compatible IBM computers.

![Schermata del 2021-06-23 19-23-23](https://user-images.githubusercontent.com/74959879/123141274-82b45900-d458-11eb-8c5d-d077d50f3ed0.png)

Nostalgia does not rise?

Why did I do it? Just for fun, I have to admit that many times there have been mistakes that I couldn't fix, and I got really nervous.

# Features
The program implements:
  
  ✅ A simple system of lateral and vertical scrolling of the screen and characters.
  
  ✅ The storage of overwritten characters in the vertical scroll of the screen.
  
  ✅ Command line parameters.
  
  ✅ Control characters.
  
  ❌ Read and write operations on files. (Dos didn't help)

# Study of the source

The source consists of 5 modules(▫️) and 2 libraries(▪️)containing the data on the exit screen and menu:

  ▫️ Main.asm = main module, makes calls to main functions.

  ▫️ Editor.asm = defines the functions for initializing the editor.
  
  ▫️ I_O.asm = defines the functions for handling I / O by the text editor.
  
  ▫️ Shifter.asm = defines the functions for managing the lateral and vertical scrolling of the screen and characters.
  
  ▫️ Animation.asm = defines the functions for managing the scrollbar.
  
  ▫️ file.asm = to do.
  
  ▪️ INIT_EDI.INC = defines the logical segment where the data to be stored in the VRAM for the menu output on the screen. 
  
  ▪️ EXIT_IM.INC =  defines the logical segment where the data to be stored in the VRAM for the exit menu output on the                           screen.
  







  






  


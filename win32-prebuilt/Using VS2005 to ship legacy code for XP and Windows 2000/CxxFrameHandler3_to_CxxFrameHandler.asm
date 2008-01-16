   .386
   .model flat
   ;
   ; vc8-to-vc6 bridge assembly code.
   ;
   ; This module patches up gaps in order to a build a bridge to connect our code
   ; compiled with the VC8 compiler and with the code in the VC6 runtime library.
   ;
   ; Trampoline from ___CxxFrameHandler3 --> ___CxxFrameHandler
   ;
   ; ___CxxFrameHandler[n] is called for try/catch blocks (C++)
   ;
   ; See "How a C++ compiler implements exception handling"
   ; http://www.codeproject.com/cpp/exceptionhandler.asp


   ;
   .code

   ; MSVCRT.DLL
   extrn __imp____CxxFrameHandler:dword  ; external memory addr


public  ___CxxFrameHandler3


___CxxFrameHandler3 proc near


   ; Jump indirect: Jumps to (*__imp__CxxFrameHandler)
   jmp  __imp____CxxFrameHandler  ; Trampoline bounce


___CxxFrameHandler3 endp

   end

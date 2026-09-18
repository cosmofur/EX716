# Test File that just exercise macros
M FUNCTION IFDEF DebugFlag \
    P Entering %1 ;

M ENDFUNCTION \
    P Exiting %1 ; \
    ENDBLOCK


M CALLFUNC @FUNCTION %1 \
  P Foo Function \
@ENDFUNCTION

P Do Functoin FOO without Debug
@FUNCTION FOO
  P Inside FOO
@ENDFUNCTION

P Do Function FOO with Debug
MF DebugFlag 1
@FUNCTION FOO
  P Inside FOO ;
@ENDFUNCTION

@FUNCTION A
   @FUNCTION B
      P Inside B ;
   @ENDFUNCTION
@ENDFUNCTION

$$1 99 42 0

# EX716 C compiler quick start

`bin/ECC` compiles C source with the sibling `lcc` compiler and emits a runnable
CPU24 assembly harness. Add the EX716 `bin` directory to `PATH` once, then use
the command from any working directory:

```sh
ECC hello.c
ECC -o hello.asm hello.c
ECC -DDEBUG -I ./include --stack-size 8192 -o build/hello.asm hello.c
ECC --no-stdio -o build/tiny.asm tiny.c
ECC -g -o build/hello-debug.asm hello.c
```

The default output is `out.asm` in the current directory. The launcher locates
the EX716 and sibling lcc repositories relative to itself, builds the lcc
preprocessor/compiler if needed, selects the EX716 headers, and compiles the
small `printf`/`snprintf` runtime with the program. `--no-stdio` omits that
runtime when formatting is not needed. Set `ECC_LCC_ROOT` if lcc is not in the
sibling directory; `ECC_CPP` and `ECC_RCC` override the built tools individually.

The generated file targets the segmented CPU24 runtime. Assemble and run it
with the EX716 library path available to the assembler:

```sh
CPUPATH=/path/to/EX716/lib python3 /path/to/EX716/cpu24.py out.asm
```

Current launcher options are `-g`, `-o FILE`, `--stack-size BYTES`,
`--no-stdio`, `-I DIR`, `-D NAME[=VALUE]`, `-U NAME`, and `-v`. `-g` adds
`# C path/to/file.c:line` comments at generated-code source locations. These
help correlate CPU24 assembly listings and runtime errors with C source, but
do not provide C-level stepping or variable inspection. Stack size defaults
to 4096 bytes and must be an even value from 512 through 57344. The target is an experimental
integer C profile (16-bit `int`, 32-bit `long`, near pointers); floating-point
and long-long operations are not implemented.

The generated harness is segmented CPU24 assembly, so a classic `cpu.py`
selector would not apply to this output format.

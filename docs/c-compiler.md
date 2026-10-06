# EX716 C compiler quick start

`bin/ECC` compiles C source with the sibling `lcc` compiler and emits a runnable
CPU24 assembly harness. Add the EX716 `bin` directory to `PATH` once, then use
the command from any working directory:

```sh
ECC hello.c
ECC -o hello.asm hello.c
ECC -DDEBUG -I ./include --stack-size 8192 -o build/hello.asm hello.c
ECC --no-stdio -o build/tiny.asm tiny.c
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

Current launcher options are `-o FILE`, `--stack-size BYTES`, `--no-stdio`,
`-I DIR`, `-D NAME[=VALUE]`, `-U NAME`, and `-v`. Stack size defaults to 4096 bytes and
must be an even value from 512 through 57344. The target is an experimental
integer C profile (16-bit `int`, 32-bit `long`, near pointers); floating-point
and long-long operations are not implemented.

Useful follow-on options would be an explicit `--run` mode, a `--cpu cpu.py|cpu24.py`
selection, and `-g`/debug-symbol control. Those affect execution/debugging, so
the current command stays focused on reliable assembly generation.

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
ECC --run --cpu-arg=--trace-tail --cpu-arg=64 hello.c
```

The default output is `out.asm` in the current directory. The launcher locates
the EX716 and sibling lcc repositories relative to itself, builds the lcc
preprocessor/compiler if needed, selects the EX716 headers, and compiles the
small `printf`/`snprintf` runtime with the program. `--no-stdio` omits that
runtime when formatting is not needed. Set `ECC_LCC_ROOT` if lcc is not in the
sibling directory; `ECC_CPP` and `ECC_RCC` override the built tools individually.

The generated file targets the segmented CPU24 runtime. It includes an explicit
`.ENTRY __ECC_INIT_MAIN`, so `cpu24.py out.asm` starts at the generated CS0
compatibility bootstrap rather than depending on a legacy `.ORG` location. The
bootstrap selects the C data segment, enables banking with `ADM`, and then
calls the relocatable C `main`. Assemble and run it
with the EX716 library path available to the assembler:

```sh
CPUPATH=/path/to/EX716/lib python3 /path/to/EX716/cpu24.py out.asm
```

`ECC --run` performs that exact final step after writing the assembly. Use a
repeatable `--cpu-arg ARG` for ordinary CPU24 options such as `-g`, `-q`, or
`--trace-tail 64`; the generated `.asm` remains on disk either way. Each lcc
translation unit is delimited in that file, with no post-processing of the
compiler's assembly, so the file is the artifact to inspect when debugging.

Current launcher options are `-g`, `-o FILE`, `--stack-size BYTES`,
`--no-stdio`, `--run`, `--cpu-arg ARG`, `-I DIR`, `-D NAME[=VALUE]`, `-U NAME`,
and `-v`. `--no-stdio`
omits the target's console stream and formatting runtime. `-g` adds
`# C path/to/file.c:line` comments at generated-code source locations. These
help correlate CPU24 assembly listings and runtime errors with C source, but
do not provide C-level stepping or variable inspection. Stack size defaults
to 4096 bytes and must be an even value from 512 through 57344. The target is an experimental
integer C profile (16-bit `int`, 32-bit `long`, near pointers); floating-point
and long-long operations are not implemented.

The generated harness is segmented CPU24 assembly, so a classic `cpu.py`
selector would not apply to this output format.

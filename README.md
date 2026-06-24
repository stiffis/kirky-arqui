# Procesador RISC-V pipelined (RV32I + extension C)

Procesador RISC-V de 5 etapas (Fetch, Decode, Execute, Memory, Writeback) con
unidad de riesgos (forwarding, stall, flush), basado en Harris & Harris.
Proyecto 2 de Arquitectura de Computadoras.

## Estructura

```
rtl/         Modulos de diseno (Verilog sintetizable)
tests/       Testbenches (.v) y programas de prueba en tests/programs/ (.mem)
toolchain/   asm2mem.sh: ensambla .s -> .mem (RV32I y RVC)
docs/        Informe LaTeX e imagenes
Makefile     Atajos de simulacion
run_tests.sh        Regresion completa (PASS/FAIL por testbench)
run_hazard_demo.sh  Demostracion de forwarding / stall / flush
```

`imem.v` carga el programa desde `riscvtest.mem` (en el directorio de
ejecucion); los runners copian ahi el programa de cada prueba. La fuente de
verdad de los programas esta en `tests/programs/*.mem`.

## Uso

```sh
make test            # regresion completa
make hazard          # demo de la unidad de riesgos
make demo-hazard     # mismo programa sin NOPs: falla sin hazard unit
make wave PROG=isa   # genera wave.vcd para gtkwave
make clean           # borra artefactos
```

## Generar programas

```sh
toolchain/asm2mem.sh programa.s          # RV32I
toolchain/asm2mem.sh programa.s rv32ic   # con instrucciones comprimidas
cp programa.mem riscvtest.mem
```

## Requisitos

`iverilog`, `gtkwave`, `python3` y `riscv64-linux-gnu-{as,ld,objcopy}`.

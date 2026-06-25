# Bitácora — Extensión C (RVC) sobre el pipeline RISC-V

Registro del desarrollo de la extensión de instrucciones comprimidas (Entrega 2).
Complementa a `IMPLEMENTACION_PIPELINE_BASE.md` (Entrega 1: pipeline + hazard unit).

## Objetivo de la Entrega 2

Implementar 11 instrucciones comprimidas de tipo ALU/registro-inmediato:

```
c.addi  c.add  c.sub  c.and  c.or  c.xor  c.slli  c.srli  c.srai  c.lui  c.andi
```

Cada comprimida (16 bits) tiene exactamente un equivalente de 32 bits. La
estrategia es **descomprimir en Fetch**: expandir los 16 bits a su forma RV32I
antes del registro IF/ID, de modo que Decode, Execute, Memory, Writeback,
`controller`, `aludec`, `extend` y `hazardunit` no se tocan.

Distinción 16/32 bits: `instr[1:0] != 2'b11` indica instrucción comprimida.

## Fases

| Fase | Contenido | Estado |
|------|-----------|--------|
| 0 — Cimientos | imem ventana deslizante + PCPlusInc (+2/+4) + decompressor passthrough | hecha |
| E2.1 | c.addi (CI) — prueba de concepto | pendiente |
| E2.2 | c.lui, c.slli (CI), c.add (CR) | pendiente |
| E2.3 | c.sub, c.and, c.or, c.xor (CA) | pendiente |
| E2.4 | c.srli, c.srai, c.andi (CB) | pendiente |
| E2.5 | programa mixto 16/32 + waveforms + informe | pendiente |

## Flujo de trabajo por fase

implementar (decompressor.v) -> programa .mem de prueba -> testbench ->
`make test` (sigue verde) -> `make wave PROG=<name>` -> crear .gtkw -> revisar.

Convención de nombres: `tests/programs/riscvtest_<name>.mem`,
`tests/testbench_<name>.v`, `waves/<name>/`.

---

## Fase 0 — Cimientos

### Idea

Instalar la infraestructura que necesita cualquier instrucción comprimida,
sin implementar todavía ninguna. El descompresor se cablea en su sitio pero
deja pasar todo sin tocar (passthrough); el fetch aprende a traer 16 bits y a
avanzar el PC de a 2 o 4.

### Qué se modifica y por qué

1. **`rtl/imem.v` — ventana deslizante.**
   Hoy `RAM[a[31:2]]` asume que toda instrucción arranca alineada a 4 bytes. Con
   RVC una instrucción puede empezar en `...0` o `...2`, y una de 32 bits puede
   quedar partida entre dos palabras. Solución:
   - `PC[1]==0`: `rd = RAM[k]` (como antes).
   - `PC[1]==1`: `rd = {RAM[k+1][15:0], RAM[k][31:16]}`.

2. **`rtl/datapath.v` — incremento +2/+4.**
   Hoy `PCPlus4F = PCF + 4` fijo. Una comprimida mide 2 bytes, así que el PC
   debe avanzar 2. `inc = compressed ? 2 : 4`. Se renombra `PCPlus4*` a
   `PCPlusInc*` por toda la tubería (ese valor es el link de jal/jalr, relevante
   en E3).

3. **`rtl/decompressor.v` (nuevo, passthrough).**
   Punto físico donde luego se expandirán los 16 bits. En Fase 0:
   - `compressed = (instrraw[1:0] != 2'b11)` (maneja el +2/+4).
   - `instr = instrraw` (aún no expande).
   El registro IF/ID guarda la salida del descompresor, no la instrucción cruda.

### Propiedad de seguridad

Para programas 100% RV32I: `PC[1]=0` siempre, `compressed=0` siempre, passthrough
entrega lo mismo -> comportamiento idéntico. La regresión debe seguir en 12 PASS.

### Validación

`make test` -> 12 PASS, 0 FAIL.
`make hazard` -> 3 PASS, 0 FAIL.

### Estado

Completada (2026-06-24).

Archivos tocados:
- `rtl/decompressor.v` (nuevo): passthrough; calcula `compressed = (instrraw[1:0] != 2'b11)`.
- `rtl/imem.v`: ventana deslizante `rd = a[1] ? {w1[15:0], w0[31:16]} : w0`.
- `rtl/datapath.v`: instancia `decompressor` sobre `InstrF`; el IF/ID guarda
  `InstrDecF`; `PCPlusIncF = PCF + (compressedF ? 2 : 4)`; rename `PCPlus4* -> PCPlusInc*`.

Para RV32I puro `PC[1]=0` y `compressed=0` siempre, asi que el comportamiento es
identico y la regresion sigue verde. El camino desalineado (`PC[1]=1`) queda listo
pero aun no se ejercita hasta E2.1, cuando haya comprimidas reales.

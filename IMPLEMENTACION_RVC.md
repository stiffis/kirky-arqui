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
| E2.1 | c.addi (CI) — prueba de concepto | hecha |
| E2.2 | c.lui, c.slli (CI), c.add (CR) | hecha |
| E2.3 | c.sub, c.and, c.or, c.xor (CA) | hecha |
| E2.4 | c.srli, c.srai, c.andi (CB) | hecha |
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

---

## E2.1 — c.addi

### Implementación

`c.addi rd, imm` (formato CI, op=01, funct3=000) expande a `addi rd, rd, imm` con
inmediato de 6 bits con signo `{c[12], c[6:2]}`. En `decompressor.v`:

```
case ({c[1:0], c[15:13]})
  5'b01000: instr = {{7{c[12]}}, c[6:2], c[11:7], 3'b000, c[11:7], 7'b0010011};
  default:  instr = instrraw;
endcase
```

Campos del addi de 32 bits: imm[11:0] = sign-extend de 6 bits, rs1 = rd = `c[11:7]`,
funct3 = 000, rd = `c[11:7]`, opcode = 0010011.

### Programa de prueba

`tests/programs/riscvtest_caddi.s` (mixto 16/32, control con `.option rvc/norvc`):

```
addi x8, x0, 5     ; 32 bits  -> x8 = 5
c.addi x8, 3       ; 16 bits  -> x8 = 8
sw   x8, 0(x0)     ; 32 bits  -> Mem[0] = 8
```

`.mem` generado:
```
00500413   ; addi x8,x0,5
2023040d   ; c.addi x8,3 (low16) + sw (low16)
00000080   ; sw (high16)
```

La `sw` empieza en el byte 6 (`PC[1]=1`): queda partida entre `RAM[1]` y `RAM[2]`,
y la ventana deslizante la reensambla (`0x00802023`). Es decir, este test ademas
estrena el camino desalineado de la `imem`.

### Validación

`make test` -> 13 PASS (12 RV32I + caddi: `Mem[0] = 8`).
`make wave PROG=caddi` -> `waves/caddi/caddi.vcd`.

### Estado

Completada (2026-06-24).

---

## E2.2 — c.lui, c.slli, c.add

### Meta de la fase

Agregar las tres comprimidas que usan **registros completos** (de 5 bits,
cualquiera de x0--x31): dos del formato CI (`c.lui`, `c.slli`) y una del CR
(`c.add`). Es el escalon natural tras `c.addi` porque comparten el manejo de
registros de 5 bits y todavia NO introducen los registros restringidos x8--x15
(eso llega en E2.3). Asi se sube la dificultad de a poco.

### Como se implemento y por que

Se agregaron variables nombradas en `decompressor.v` para que cada expansion se
lea como pseudocodigo: `rs2 = c[6:2]`, `shamt = c[6:2]`, `immlui = {{15{c[12]}}, c[6:2]}`.
Se definen aparte aunque algunas comparten bits, porque cumplen roles distintos
segun la instruccion (la legibilidad pesa mas que evitar el alias).

Las tres entradas del `case ({op, funct3})`:

```
5'b01_011: instr = {immlui, rd, 7'b0110111};                         // c.lui
5'b10_000: instr = {7'b0000000, shamt, rd, 3'b001, rd, 7'b0010011};  // c.slli
5'b10_100: instr = (c[12] && rs2 != 0)                               // c.add
                 ? {7'b0000000, rs2, rd, 3'b000, rd, 7'b0110011}
                 : instrraw;
```

- **`c.lui`** (CI, op=01 funct3=011) -> `lui rd, imm`. Por que `immlui =
  {{15{c[12]}}, c[6:2]}`: el nzimm de 6 bits ocupa imm[17:12] y se extiende en
  signo hasta el bit 31; como el campo U del `lui` es imm[31:12] (20 bits), eso es
  15 copias del signo (`c[12]`) seguidas de los 5 bits bajos. El `extend.v`
  existente ya construye `{instr[31:12], 12'b0}` para `lui`, asi que no se toca
  nada aguas abajo. Restriccion del ISA: el destino no puede ser x0 ni x2.

- **`c.slli`** (CI, op=10 funct3=000) -> `slli rd, rd, shamt`. El shamt son los 5
  bits `c[6:2]`; el `slli` de RV32I es I-type con funct7=0000000 y funct3=001. En
  RV32 el bit `c[12]` (shamt[5]) es 0, por eso solo se usan 5 bits.

- **`c.add`** (CR, op=10 funct3=100) -> `add rd, rd, rs2`. Aqui hay una sutileza:
  `{op, funct3}=10100` lo comparten varias instrucciones del cuadrante 2
  (`c.mv`, `c.jr`, `c.jalr`, `c.add`), que se distinguen por `c[12]` y por si
  `rs2` es cero. Por eso la condicion `c[12] && rs2 != 0` selecciona
  exactamente `c.add`; lo demas cae a passthrough hasta que toque (c.jr/c.jalr
  son de E3). Es la primera vez que una entrada del case necesita desambiguar.

### Programa de prueba y por que esos valores

`tests/programs/riscvtest_cir.s` encadena las tres para que cada resultado dependa
del anterior (asi un solo valor final valida toda la cadena):

```
addi x8, x0, 3   ; x8 = 3      (32 bits)
c.slli x8, 2     ; x8 = 12     (3 << 2)
addi x9, x0, 5   ; x9 = 5      (32 bits)
c.add x8, x9     ; x8 = 17     (12 + 5)
c.lui x10, 1     ; x10 = 0x1000 = 4096
sw x8, 0(x0)     ; Mem[0] = 17
sw x10, 4(x0)    ; Mem[4] = 4096
```

Se uso `.option rvc/norvc` para forzar que solo `slli`, `add` y `lui` se
compriman (los `addi` quedan en 32 bits para mantener la mezcla 16/32). Se
verifico con `objdump` que el ensamblador emitiera `c.slli`/`c.add`/`c.lui` y no
otras comprimidas aun no soportadas.

### Validación

`make test` -> 14 PASS (caddi + cir: `Mem[0]=17`, `Mem[4]=4096`).
`make wave PROG=cir` -> `waves/cir/cir.vcd`.

### Estado

Completada (2026-06-24).

---

## E2.3 — c.sub, c.and, c.or, c.xor

### Meta de la fase

Implementar la familia CA (registro-registro). Lo nuevo respecto a E2.2 son dos
cosas: (1) los **registros restringidos** x8--x15 (3 bits en vez de 5), y (2) la
primera **desambiguacion anidada** del descompresor.

### Como se implemento y por que

Registros restringidos: se agregaron `rdp = {2'b01, c[9:7]}` y `rs2p = {2'b01,
c[4:2]}`. Anteponer `01` a los 3 bits da el numero real (campo 000->x8 ...
111->x15), que es justo el mapeo del ISA.

Desambiguacion anidada: la familia CA comparte `{op,funct3} = {01,100}` con la
familia CB de E2.4 (`c.srli/srai/andi`). Ambas caen en la misma entrada del case.
Se distinguen por `c[11:10]`:
- `c[11:10] == 11` -> registro-registro (CA), y dentro, `c[6:5]` elige la operacion.
- otro valor -> CB (queda passthrough hasta E2.4).

```
5'b01_100:
  if (c[11:10] == 2'b11)
    case (c[6:5])
      2'b00: sub  -> {7'b0100000, rs2p, rdp, 3'b000, rdp, 7'b0110011}
      2'b01: xor  -> {7'b0000000, rs2p, rdp, 3'b100, rdp, 7'b0110011}
      2'b10: or   -> {7'b0000000, rs2p, rdp, 3'b110, rdp, 7'b0110011}
      2'b11: and  -> {7'b0000000, rs2p, rdp, 3'b111, rdp, 7'b0110011}
    endcase
  else instr = instrraw;
```

Cada una expande al R-type correspondiente: `sub` usa funct7=0100000; el resto
funct7=0000000; el funct3 distingue (000 sub, 100 xor, 110 or, 111 and).

### Programa de prueba y por que esos valores

`tests/programs/riscvtest_ca.s`. Se cargan operandos `x8..x12` (todos en x8--x15
para que las comprimidas sean validas) con valor 12, y `x9=10`, y se aplican las
cuatro operaciones contra `x9`:

```
c.sub x8, x9   ; 12 - 10 = 2    -> Mem[0]=2
c.xor x10, x9  ; 12 ^ 10 = 6    -> Mem[4]=6
c.or  x11, x9  ; 12 | 10 = 14   -> Mem[8]=14
c.and x12, x9  ; 12 & 10 = 8    -> Mem[12]=8
```

Los valores 12 (1100) y 10 (1010) se eligieron para que cada operacion logica de
un resultado distinto y reconocible. Se verifico con `objdump` que el ensamblador
emitiera `c.sub/c.xor/c.or/c.and` con registros restringidos (s0,s1,a0,a1,a2).

### Validación

`make test` -> 15 PASS (Mem[0]=2, Mem[4]=6, Mem[8]=14, Mem[12]=8).
`make wave PROG=ca` -> `waves/ca/ca.vcd`.

### Estado

Completada (2026-06-24).

---

## E2.4 — c.srli, c.srai, c.andi

### Meta de la fase

Cerrar la familia CB y, con ella, las 11 instrucciones de E2. Estas tres comparten
la entrada `{op,funct3}={01,100}` con la CA de E2.3 (eran las ramas que en E2.3
quedaron en passthrough). Se distinguen por `c[11:10]`.

### Como se implemento y por que

Se reescribio la entrada `5'b01_100` como un unico `case (c[11:10])`, mas claro
que el if/else previo:

```
case (c[11:10])
  2'b00: srli -> {7'b0000000, shamt, rdp, 3'b101, rdp, 7'b0010011}
  2'b01: srai -> {7'b0100000, shamt, rdp, 3'b101, rdp, 7'b0010011}
  2'b10: andi -> {immci, rdp, 3'b111, rdp, 7'b0010011}
  2'b11: <CA: c.sub/xor/or/and segun c[6:5]>
endcase
```

- `c.srli`/`c.srai` (CB): shamt = `c[6:2]`, funct3=101; la diferencia es funct7
  (0000000 logico vs 0100000 aritmetico), igual que en RV32I.
- `c.andi` (CB): reusa `immci` (el mismo inmediato de 6 bits con signo que `c.addi`)
  y funct3=111. Registro restringido `rdp`.

Reuso de variables: `shamt` (= c[6:2]) e `immci` ya existian de fases anteriores;
no hizo falta nada nuevo, solo cablear las tres expansiones.

### Programa de prueba y por que esos valores

`tests/programs/riscvtest_cb.s`:

```
addi x8, x0, 40   ; srli: 40 >> 2 = 10     -> Mem[0]=10
addi x9, x0, -8   ; srai: -8 >> 1 = -4     -> Mem[4]=0xFFFFFFFC
addi x10, x0, 13  ; andi: 13 & 6 = 4       -> Mem[8]=4
```

Se uso `x9 = -8` a proposito para que `c.srai` demuestre el **corrimiento
aritmetico** (mantiene el signo): -8 >> 1 = -4 = 0xFFFFFFFC, distinto de un
corrimiento logico. Todos los registros en x8--x15 para que las comprimidas sean
validas. Verificado con `objdump`.

### Validación

`make test` -> 16 PASS (Mem[0]=10, Mem[4]=-4, Mem[8]=4).
`make wave PROG=cb` -> `waves/cb/cb.vcd`.

Con E2.4 quedan implementadas las **11 instrucciones** de la Parte 1 de RVC:
c.addi, c.lui, c.slli, c.add, c.sub, c.xor, c.or, c.and, c.srli, c.srai, c.andi.

### Estado

Completada (2026-06-24).

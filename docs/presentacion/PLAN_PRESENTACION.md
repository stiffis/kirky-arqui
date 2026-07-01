# Plan de capítulos — Presentación Final (15 min, 8 pts)

Basado en la rúbrica del profesor. Puntaje de contenido: 5 pts (0.5 + 2 + 2 + 0.5);
el resto (3 pts) es la ronda de preguntas grupal/individual, que no es un frame
sino preparación oral.

Tiempo objetivo: **15 min ≈ 16-18 frames**. El tiempo por capítulo abajo es
proporcional a su puntaje, con la excepción de los capítulos 2 y 3 (ver nota
de validación incremental).

**Patrón de validación incremental (aplica en cap. 2 y 3):** por cada
mecanismo/familia se muestra, muy rápido: *"el programa quiere hacer X, pero
sin [mecanismo/instrucción] no puede porque Y — y eso se ve en el waveform
así"*. Un frame por caso, sin over-explicar: snippet corto del programa +
waveform con la parte relevante señalada. Esto es lo que evidencia que se fue
probando en fases, no solo al final.

---

## 0. Portada (no puntúa, ~20 s)

- Título del proyecto, integrantes, curso, fecha.
- 1 frame.

## 1. Proceso de construcción (no puntúa directo, ~1 min, 1 frame)

**Por qué se agrega:** no está en la rúbrica, pero da contexto de cómo se
trabajó y demuestra rigor metodológico — vale la pena 1 frame, no más.

- Frame 1 — Metodología incremental por entregas:
  - E1 (5 pts): pipeline base + Hazard Unit + ISA RV32I (24 instr.)
  - E2 (4 pts): RVC parte 1 — 11 instrucciones comprimidas de ALU/reg-inmediato
  - E3 (3 pts): RVC parte 2 — 10 instrucciones de memoria y control de flujo
  - Ciclo por fase: implementar → programa de prueba → testbench → waveform →
    siguiente fase. Este patrón es el que se ve en detalle en los próximos
    dos capítulos (hazard unit y extensión C).

## 2. Pipeline funcionando con Hazard Unit — 0.5 pts (~2 min, 4-5 frames)

**Qué debe quedar claro:** el pipeline base de 5 etapas funciona, y sin
detección/resolución de riesgos falla de 3 formas distintas (dependencias de
datos consecutivas, dependencias con carga, saltos); la Hazard Unit resuelve
cada una.

- Frame 2 — Pipeline de 5 etapas: diagrama (Fetch/Decode/Execute/Memory/WB).
  - Figura: `pipeline_diagram.png`
- Frame 3 — **Forward**: el programa quiere usar un resultado apenas
  calculado en la instrucción siguiente; sin forwarding lee el valor viejo del
  regfile. Mostrar snippet del programa + waveform del fallo.
  - Figuras: `hazard_forward_nohu.png` (fallo) → `hazard_forward_waveform.png`
    (resuelto, mismo dato correcto ya en el ciclo que corresponde)
- Frame 4 — **Stall**: el programa quiere usar un valor que recién se está
  leyendo de memoria (load-use); no se puede resolver solo con forwarding, hay
  que detener el pipeline un ciclo.
  - Figuras: `hazard_stall_nohu.png` → `hazard_stall_waveform.png`
- Frame 5 — **Flush**: el programa tiene un salto/branch; las instrucciones ya
  cargadas en el pipeline detrás del salto son incorrectas y hay que
  descartarlas.
  - Figuras: `hazard_flush_nohu.png` → `hazard_flush_waveform.png`
- (Frame 2-5 pueden fusionarse en menos diapositivas si el espacio de cada
  waveform lo permite — decidir al maquetar en Beamer)

## 3. Implementación de instrucciones C — 2 pts (~7 min, 8-9 frames)

**Qué debe quedar claro:** cómo se extendió el pipeline para soportar RVC sin
tocar su lógica interna, qué módulos cambiaron, cómo se fue validando
familia por familia, cómo se codifican las instrucciones, y qué no se
soporta.

- Frame 6 — ¿Qué es la extensión C? Motivación (reducir tamaño de código),
  idea clave: descomprimir en Fetch antes del registro IF/ID → pipeline,
  control y hazard unit no se modifican.
- Frame 7 — Validación incremental por familia (E2): recorrido rápido de las
  familias de instrucciones ALU/reg-inmediato (CI: `c.addi`/`c.lui`/`c.slli`;
  CR: `c.add`; CA: `c.sub`/`c.xor`/`c.or`/`c.and`; CB: `c.srli`/`c.srai`/`c.andi`),
  cada una con su programa de prueba y su waveform confirmando el resultado
  esperado — mostrar en formato compacto (grid de 2-3 miniaturas o tabla con
  1-2 capturas representativas, no las 4 familias a tamaño completo).
- Frame 8 — Validación incremental por familia (E3): mismo patrón para
  memoria/control de flujo (CL/CS: `c.lw`/`c.sw`; CSS: `c.lwsp`/`c.swsp`; CB:
  `c.beqz`/`c.bnez`; CJ: `c.j`/`c.jal`; CR: `c.jr`/`c.jalr`) — igual de
  compacto que el frame anterior.
- Frame 9 — Instrucciones importantes en detalle (las 2 más representativas,
  con su programa y su waveform a tamaño completo):
  - `c.lw`/`c.sw` (formato CL/CS, registros restringidos, bug real de
    `c[4:2]` vs `c[9:7]` si se quiere contar como anécdota)
  - `c.jr`/`c.jalr`/`c.add` (desambiguación por cuadrante/campos)
- Frame 10 — Módulos agregados y cambios en el datapath:
  - `decompressor.v` (núcleo, combinacional 16→32)
  - `imem.v` con ventana deslizante (PC desalineado a palabra)
  - incremento variable del PC (+2/+4)
  - Figura: `datapath_final.pdf` (resaltar en rojo lo agregado)
- Frame 11 — ALU modificada.
  - Figura: `alu_modificada.pdf`
- Frame 12 — Encoding: tabla resumida de formatos usados (CI, CR, CA, CB, CL,
  CS, CSS, CJ) con 1 ejemplo de bits por formato.
- Frame 13 — Limitaciones (contenido concreto, verificado contra
  `rtl/decompressor.v`):
  - **Subset de RVC no cubierto:** `c.nop`, `c.li`, `c.addi16sp`,
    `c.addi4spn`, `c.ebreak` no se implementaron — el foco fueron las 21
    instrucciones pedidas en E2+E3. Tampoco hay punto flotante comprimido
    (`c.flw`/`c.fsw`) ni instrucciones RV64C (`c.ld`/`c.sd`), por ser fuera de
    alcance de una base RV32I.
  - **Registros restringidos (limitación del estándar RVC, no del diseño
    propio):** los formatos CA, CB, CL y CS solo direccionan `x8`–`x15`
    (campo de 3 bits `rd'`/`rs2'` + prefijo `01`) — vale la pena explicarlo
    porque implica que un compilador real tendría que priorizar esos
    registros para aprovechar la compresión al máximo.
  - **Sin detección de encoding ilegal:** el decompresor no valida patrones
    de 16 bits que no correspondan a ninguna instrucción comprimida
    soportada — no se genera trap de instrucción ilegal, el comportamiento
    queda indefinido.
  - **Nota aparte (no es limitación, es un extra):** `c.mv` sí está
    implementado como subproducto de la desambiguación del cuadrante 2
    (`c[12]=0 && rs2!=0`, junto a `c.add`/`c.jr`/`c.jalr`), aunque no se
    presenta como instrucción propia porque no fue pedida explícitamente.

## 4. Test programa ISA / algoritmo de prueba — 2 pts (~4 min, 4 frames)

**Qué debe quedar claro:** el programa de prueba final (más allá de las
familias individuales) corre correctamente, los resultados coinciden con lo
esperado, y hay una comparativa cuantitativa tamaño/performance entre RV32I y
RVC.

- Frame 14 — Programa de prueba: qué hace el algoritmo (ej. `sumloop`, bucle
  de suma) y por qué se eligió (ejercita memoria + control de flujo + ALU +
  RVC juntos, a diferencia de las pruebas por familia que fueron aisladas).
- Frame 15 — Explicación de resultados: waveform con anotación de qué se debe
  leer (valor final esperado vs. obtenido).
  - Figura: `sumloop_waveform.png`
- Frame 16 — (opcional si alcanza el tiempo) segundo programa de prueba
  (ej. `mul10`) como refuerzo de robustez.
  - Figura: `mul10_waveform.png`
- Frame 17 — Comparativa de tamaño y performance: tabla RV32I vs RVC (bytes de
  código, número de ciclos/instrucciones ejecutadas).

## 5. Conclusiones, desafíos y mejoras — 0.5 pts (~1.5 min, 1-2 frames)

- Frame 18 — Conclusiones: qué se logró (pipeline + hazard unit + RVC
  completo y validado).
- Frame 19 — Desafíos encontrados (elegir 1-2 reales, no una lista genérica)
  y mejoras futuras (ej. subset RVC más amplio, testbenches por etapa).

## 6. Cierre (~10 s)

- Frame 20 — "Gracias / Preguntas".

---

## Notas de proceso

- El conteo de frames subió (0→20) por agregar la validación incremental;
  para respetar los 15 min, los frames 7 y 8 (grid de familias) DEBEN ser
  compactos — miniaturas o checkmarks, no waveforms grandes uno por uno. Si
  al maquetar en Beamer no entra, fusionar 7+8 en un solo frame con una tabla
  única (familia | instrucciones | resultado).
- Las figuras y tablas ya existen en `docs/` (`hazard_*_nohu.png`,
  `hazard_*_waveform.png`, etc.). Para los frames 7 y 8 (validación por
  familia RVC), ya hay `.vcd`/`.gtkw` en `waves/` por familia: `caddi`, `cir`,
  `ca`, `cb` (E2); `clsw`, `clspsp`, `cbz`, `cj`, `cjr` (E3) — falta solo
  exportar capturas `.png` chicas desde GTKWave para el grid compacto (no
  volver a simular nada, ya están validados).
- Después de tener el esqueleto de frames (títulos + bullets), pasar a:
  1. Elegir figuras definitivas por frame (revisar qué hay en `waves/<test>/`
     para cada familia).
  2. Redactar notas del orador (quién dice qué).
  3. Ensayar y cronometrar; recortar (empezando por frames opcionales/16) si
     excede 15 min.

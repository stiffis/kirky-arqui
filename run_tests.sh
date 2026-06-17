#!/usr/bin/env bash
#
# Runner de regresion del pipeline RISC-V (week13).
# Compila y corre los 7 testbenches con iverilog y reporta PASS/FAIL por cada uno.
# Uso:  ./run_tests.sh
# Exit: 0 si todos pasan, 1 si alguno falla.

set -u
cd "$(dirname "$0")"

BUILD=build
mkdir -p "$BUILD"

# Modulos del nucleo de diseno (en la raiz; todo menos los testbenches).
CORE=(adder.v alu.v aludec.v controller.v datapath.v dmem.v extend.v \
      flopr.v imem.v maindec.v mux2.v mux3.v regfile.v riscvpipe.v top.v)

# Pruebas (programas en tests/programs/, testbenches en tests/).
#   nombre | programa (.txt) | testbench (.v)
PROGDIR=tests/programs
TBDIR=tests
TESTS=(
  "base   | riscvtest_base.txt    | testbench_base.v"
  "ctrl   | riscvtest_ctrl.txt    | testbench_ctrl.v"
  "xor    | riscvtest_xor.txt     | testbench_xor.v"
  "lui    | riscvtest_lui.txt     | testbench_lui.v"
  "shift  | riscvtest_shift.txt   | testbench_shift.v"
  "branch | riscvtest_branch3.txt | testbench_branch3.v"
  "jalr   | riscvtest_jalr.txt    | testbench_jalr.v"
  "deps   | riscvtest_deps.txt    | testbench_deps.v"
)

# imem.v lee "riscvtest.txt" del directorio actual: lo respaldamos y restauramos.
BACKUP=""
if [ -f riscvtest.txt ]; then
  BACKUP="$BUILD/riscvtest.txt.bak"
  cp riscvtest.txt "$BACKUP"
fi
restore() { [ -n "$BACKUP" ] && cp "$BACKUP" riscvtest.txt; }
trap restore EXIT

pass=0; fail=0
GREEN=$'\e[32m'; RED=$'\e[31m'; DIM=$'\e[2m'; RST=$'\e[0m'

printf '%s\n' "── Regresion pipeline RISC-V ─────────────────────────"

for row in "${TESTS[@]}"; do
  IFS='|' read -r name prog tb <<< "$row"
  name="${name// /}"; prog="${prog// /}"; tb="${tb// /}"

  cp "$PROGDIR/$prog" riscvtest.txt
  sim="$BUILD/sim_$name"
  if ! iverilog -g2012 -o "$sim" "${CORE[@]}" "$TBDIR/$tb" 2> "$BUILD/$name.compile.log"; then
    printf '  %-7s %sFAIL%s  %s(error de compilacion, ver %s)%s\n' \
      "$name" "$RED" "$RST" "$DIM" "$BUILD/$name.compile.log" "$RST"
    fail=$((fail+1)); continue
  fi

  out="$(vvp "$sim" 2>/dev/null | grep -v -i 'warning\|vcd')"

  if echo "$out" | grep -q -i -E 'unexpected|timed out|mismatch' \
     || ! echo "$out" | grep -q -i 'ok'; then
    printf '  %-7s %sFAIL%s\n' "$name" "$RED" "$RST"
    echo "$out" | sed 's/^/             /'
    fail=$((fail+1))
  else
    last="$(echo "$out" | grep -i 'succe\|ok' | tail -1)"
    printf '  %-7s %sPASS%s  %s%s%s\n' "$name" "$GREEN" "$RST" "$DIM" "$last" "$RST"
    pass=$((pass+1))
  fi
done

printf '%s\n' "──────────────────────────────────────────────────────"
printf 'Total: %d PASS, %d FAIL\n' "$pass" "$fail"
[ "$fail" -eq 0 ]

# Atajos para el pipeline RISC-V (week13).
#   make test          -> corre la regresion (PASS/FAIL de todos los testbenches)
#   make demo-hazard   -> corre el mismo programa SIN NOPs y muestra los
#                         resultados incorrectos por hazards (sin hazard unit)
#   make clean         -> borra artefactos de compilacion

RTL = adder.v alu.v aludec.v controller.v datapath.v dmem.v extend.v \
      flopr.v imem.v maindec.v mux2.v mux3.v regfile.v riscvpipe.v top.v

.PHONY: test demo-hazard clean

test:
	@./run_tests.sh

demo-hazard:
	@mkdir -p build
	@echo "Mismo programa SIN NOPs y mismo testbench: el primer resultado dependiente ya sale mal."
	@bash -c 'cp -f riscvtest.txt build/riscvtest.txt.bak 2>/dev/null; \
	  trap "cp -f build/riscvtest.txt.bak riscvtest.txt 2>/dev/null" EXIT; \
	  cp tests/programs/riscvtest_deps_nonop.txt riscvtest.txt; \
	  iverilog -g2012 -o build/sim_nonop $(RTL) tests/testbench_deps.v && \
	  vvp build/sim_nonop 2>/dev/null | grep -v -i warning'

clean:
	rm -rf build

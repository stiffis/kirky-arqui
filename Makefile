# Atajos para el pipeline RISC-V (week13).
#   make test    -> corre la regresion de los 7 testbenches (PASS/FAIL)
#   make clean   -> borra artefactos de compilacion

.PHONY: test clean

test:
	@./run_tests.sh

clean:
	rm -rf build

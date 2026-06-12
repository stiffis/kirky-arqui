module controller(input  clk, reset,
                  input  [6:0] opD,
                  input  [2:0] funct3D,
                  input  funct7b5D,
                  input  ZeroE,
                  output [1:0] ResultSrcW,
                  output MemWriteM,
                  output PCSrcE, ALUSrcE,
                  output RegWriteW,
                  output [1:0] ImmSrcD,
                  output [2:0] ALUControlE);
  
  wire [1:0] ResultSrcD, ResultSrcE, ResultSrcM;
  wire [1:0] ALUOpD;
  wire       BranchD, BranchE;
  wire       ALUSrcD;
  wire       RegWriteD, RegWriteE, RegWriteM;
  wire       JumpD, JumpE;
  wire       MemWriteD, MemWriteE;
  wire [2:0] ALUControlD;
  wire [9:0] controlsE_in, controlsE;
  wire [3:0] controlsM_in, controlsM;
  wire [2:0] controlsW_in, controlsW;

  maindec md(
    .op(opD),
    .ResultSrc(ResultSrcD),
    .MemWrite(MemWriteD),
    .Branch(BranchD),
    .ALUSrc(ALUSrcD),
    .RegWrite(RegWriteD),
    .Jump(JumpD),
    .ImmSrc(ImmSrcD),
    .ALUOp(ALUOpD)
  );

  aludec ad(
    .opb5(opD[5]),
    .funct3(funct3D),
    .funct7b5(funct7b5D),
    .ALUOp(ALUOpD),
    .ALUControl(ALUControlD)
  );

  assign controlsE_in = {RegWriteD, ResultSrcD, MemWriteD, JumpD,
                         BranchD, ALUControlD, ALUSrcD};

  flopr #(10) regE(
    .clk(clk),
    .reset(reset),
    .d(controlsE_in),
    .q(controlsE)
  );

  assign {RegWriteE, ResultSrcE, MemWriteE, JumpE,
          BranchE, ALUControlE, ALUSrcE} = controlsE;

  assign PCSrcE = (BranchE & ZeroE) | JumpE;

  assign controlsM_in = {RegWriteE, ResultSrcE, MemWriteE};

  flopr #(4) regM(
    .clk(clk),
    .reset(reset),
    .d(controlsM_in),
    .q(controlsM)
  );

  assign {RegWriteM, ResultSrcM, MemWriteM} = controlsM;

  assign controlsW_in = {RegWriteM, ResultSrcM};

  flopr #(3) regW(
    .clk(clk),
    .reset(reset),
    .d(controlsW_in),
    .q(controlsW)
  );

  assign {RegWriteW, ResultSrcW} = controlsW;
endmodule

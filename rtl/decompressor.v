module decompressor(input  [31:0] instrraw,
                    output [31:0] instr,
                    output        compressed);

  assign compressed = (instrraw[1:0] != 2'b11);
  assign instr = instrraw;
endmodule

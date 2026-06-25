module decompressor(input  [31:0] instrraw,
                    output reg [31:0] instr,
                    output        compressed);

  wire [15:0] c      = instrraw[15:0];
  wire [1:0]  op     = c[1:0];
  wire [2:0]  funct3 = c[15:13];
  wire [4:0]  rd     = c[11:7];
  wire [11:0] immci  = {{7{c[12]}}, c[6:2]};

  assign compressed = (op != 2'b11);

  always @* begin
    instr = instrraw;
    if (compressed) begin
      case ({op, funct3})
        5'b01_000: instr = {immci, rd, 3'b000, rd, 7'b0010011};
        default:   instr = instrraw;
      endcase
    end
  end
endmodule

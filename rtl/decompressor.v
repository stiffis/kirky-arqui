module decompressor(input  [31:0] instrraw,
                    output reg [31:0] instr,
                    output        compressed);

  wire [15:0] c = instrraw[15:0];

  assign compressed = (instrraw[1:0] != 2'b11);

  always @* begin
    instr = instrraw;
    if (compressed) begin
      case ({c[1:0], c[15:13]})
        5'b01000: instr = {{7{c[12]}}, c[6:2], c[11:7], 3'b000, c[11:7], 7'b0010011};
        default:  instr = instrraw;
      endcase
    end
  end
endmodule

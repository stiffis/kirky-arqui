module decompressor(input  [31:0] instrraw,
                    output reg [31:0] instr,
                    output        compressed);

  wire [15:0] c      = instrraw[15:0];
  wire [1:0]  op     = c[1:0];
  wire [2:0]  funct3 = c[15:13];
  wire [4:0]  rd     = c[11:7];
  wire [4:0]  rs2    = c[6:2];
  wire [4:0]  shamt  = c[6:2];
  wire [4:0]  rdp    = {2'b01, c[9:7]};
  wire [4:0]  rs2p   = {2'b01, c[4:2]};
  wire [11:0] immci  = {{7{c[12]}}, c[6:2]};
  wire [19:0] immlui = {{15{c[12]}}, c[6:2]};

  assign compressed = (op != 2'b11);

  always @* begin
    instr = instrraw;
    if (compressed) begin
      case ({op, funct3})
        5'b01_000: instr = {immci, rd, 3'b000, rd, 7'b0010011};
        5'b01_011: instr = {immlui, rd, 7'b0110111};
        5'b01_100:
          if (c[11:10] == 2'b11) begin
            case (c[6:5])
              2'b00: instr = {7'b0100000, rs2p, rdp, 3'b000, rdp, 7'b0110011};
              2'b01: instr = {7'b0000000, rs2p, rdp, 3'b100, rdp, 7'b0110011};
              2'b10: instr = {7'b0000000, rs2p, rdp, 3'b110, rdp, 7'b0110011};
              2'b11: instr = {7'b0000000, rs2p, rdp, 3'b111, rdp, 7'b0110011};
            endcase
          end else begin
            instr = instrraw;
          end
        5'b10_000: instr = {7'b0000000, shamt, rd, 3'b001, rd, 7'b0010011};
        5'b10_100: instr = (c[12] && rs2 != 0)
                         ? {7'b0000000, rs2, rd, 3'b000, rd, 7'b0110011}
                         : instrraw;
        default:   instr = instrraw;
      endcase
    end
  end
endmodule

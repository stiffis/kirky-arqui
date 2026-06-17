module testbench;
  reg         clk;
  reg         reset;
  wire [31:0] WriteData;
  wire [31:0] DataAdr;
  wire        MemWrite;

  top dut(
    .clk(clk),
    .reset(reset),
    .WriteData(WriteData),
    .DataAdr(DataAdr),
    .MemWrite(MemWrite)
  );

  initial begin
    reset = 1;
    #22;
    reset = 0;
  end

  always begin
    clk = 1;
    #5;
    clk = 0;
    #5;
  end

  initial begin
    #1500;
    $display("Simulation timed out");
    $finish;
  end

  always @(negedge clk) begin
    if (MemWrite) begin
      if (DataAdr === 32'd0 && WriteData === 32'd16)
        $display("dep store/load ok: Mem[0] = 16");
      else if (DataAdr === 32'd100 && WriteData === 32'd6)
        $display("addi RAW ok: Mem[100] = 6");
      else if (DataAdr === 32'd104 && WriteData === 32'd10)
        $display("addi RAW ok: Mem[104] = 10");
      else if (DataAdr === 32'd108 && WriteData === 32'd16)
        $display("add RAW ok: Mem[108] = 16");
      else if (DataAdr === 32'd112 && WriteData === 32'd6)
        $display("sub RAW ok: Mem[112] = 6");
      else if (DataAdr === 32'd116 && WriteData === 32'd64)
        $display("slli RAW ok: Mem[116] = 64");
      else if (DataAdr === 32'd120 && WriteData === 32'd70)
        $display("or RAW ok: Mem[120] = 70");
      else if (DataAdr === 32'd124 && WriteData === 32'd17) begin
        $display("load-use ok: Mem[124] = 17");
        $display("Dependency program succeeded");
        $finish;
      end else begin
        $display("Unexpected store: Adr=%0d Data=%0d", DataAdr, WriteData);
        $finish;
      end
    end
  end
endmodule

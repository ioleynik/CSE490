`timescale 1ns / 1ps
module cpu_tb;
    reg clk = 0;
    reg reset = 1;
    wire [15:0] pc, instr, alu_result;
    integer i;

    cpu16 dut (
        .clk(clk), .reset(reset),
        .io_pc(pc), .io_curr_inst(instr), .io_alu_result(alu_result)
    );
    always #5 clk = ~clk;

    // run 1 instruction then wait for res
    task tick;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    initial begin
        //reset cpu
        repeat (2) tick;
        if (pc !== 0) $fatal(1, "FAIL: reset");
        for (i = 0; i < 16; i = i + 1)
            if (dut.REGF.regs[i] !== 0) $fatal(1, "FAIL: register reset");
        @(negedge clk); reset = 0;
        $display("PASS: reset");

        //load nums, add and sub
        tick; if (dut.REGF.regs[1] !== 7)  $fatal(1, "FAIL: ADDI");
        tick; if (dut.REGF.regs[2] !== 3)  $fatal(1, "FAIL: ADDI");
        tick; if (dut.REGF.regs[1] !== 10) $fatal(1, "FAIL: ADD");
        tick; if (dut.REGF.regs[2] !== 7)  $fatal(1, "FAIL: SUB");
        $display("PASS: ADDI, ADD, SUB");

        //shift and bitwise add
        tick; // s3 = 1.
        tick; if (dut.REGF.regs[3] !== 128) $fatal(1, "FAIL: SLL");
        tick; if (dut.REGF.regs[1] !== 2)   $fatal(1, "FAIL: AND");
        $display("PASS: SLL, AND");

        //store word check bytes and load back
        tick;
        if (dut.DMEMU.mem[2] !== 8'h00 || dut.DMEMU.mem[3] !== 8'h02)
            $fatal(1, "FAIL: SW");
        tick; if (dut.REGF.regs[4] !== 2) $fatal(1, "FAIL: LW");
        $display("PASS: SW, LW");

        //check branch skips
        tick; if (pc !== 16'h0016) $fatal(1, "FAIL: BEQ");
        tick; if (pc !== 16'h001A) $fatal(1, "FAIL: BNE");
        if (dut.REGF.regs[5] !== 0 || dut.REGF.regs[6] !== 0)
            $fatal(1, "FAIL: branch skip");
        $display("PASS: BEQ, BNE");

        //neg imm check and jmp loop check
        tick;
        if (dut.REGF.regs[7] !== 16'hFFFF) $fatal(1, "FAIL: negative ADDI");
        repeat (3) begin
            tick;
            if (pc !== 16'h001C) $fatal(1, "FAIL: JMP");
        end
        $display("PASS: negative ADDI, JMP");

        $display("tests passed :D niceeee");
        $finish;
    end

    initial begin
        #1000;
        $fatal(1, "FAIL: timeout");
    end
endmodule

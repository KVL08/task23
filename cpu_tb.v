module CPU_tb;
    reg clk;
    reg reset;
    reg [18:0] instruction;
    reg [15:0] data_in;
    wire [15:0] data_out;
    wire [15:0] address;
    wire mem_read;
    wire mem_write;

    CPU uut (
        .clk(clk),
        .reset(reset),
        .instruction(instruction),
        .data_in(data_in),
        .data_out(data_out),
        .address(address),
        .mem_read(mem_read),
        .mem_write(mem_write)
    );

    initial begin
        // Initialize clock
        clk = 0;
        forever #5 clk = ~clk; // 10ns period clock
    end

    initial begin
        // Initialize inputs
        reset = 1;
        instruction = 19'b0;
        data_in = 16'b0;

        // Wait for global reset
        #10;
        reset = 0;

        // Test ADD r1, r2, r3 (r1 = r2 + r3)
        instruction = 19'b0000_0001_0010_0011_000; // opcode=0000, rs=r2, rt=r3, rd=r1, func=000
        uut.registers[2] = 16'd10;
        uut.registers[3] = 16'd15;
        #10;
        if (uut.registers[1] !== 16'd25) $display("ADD test failed");

        // Test SUB r1, r2, r3 (r1 = r2 - r3)
        instruction = 19'b0001_0001_0010_0011_000; // opcode=0001, rs=r2, rt=r3, rd=r1, func=000
        uut.registers[2] = 16'd20;
        uut.registers[3] = 16'd5;
        #10;
        if (uut.registers[1] !== 16'd15) $display("SUB test failed");

        // Test MUL r1, r2, r3 (r1 = r2 * r3)
        instruction = 19'b0010_0001_0010_0011_000; // opcode=0010, rs=r2, rt=r3, rd=r1, func=000
        uut.registers[2] = 16'd3;
        uut.registers[3] = 16'd4;
        #10;
        if (uut.registers[1] !== 16'd12) $display("MUL test failed");

        // Test DIV r1, r2, r3 (r1 = r2 / r3)
        instruction = 19'b0011_0001_0010_0011_000; // opcode=0011, rs=r2, rt=r3, rd=r1, func=000
        uut.registers[2] = 16'd20;
        uut.registers[3] = 16'd4;
        #10;
        if (uut.registers[1] !== 16'd5) $display("DIV test failed");

        // Test INC r1 (r1 = r1 + 1)
        instruction = 19'b0100_0001_0000_0000_000; // opcode=0100, rs=r1, func=000
        uut.registers[1] = 16'd10;
        #10;
        if (uut.registers[1] !== 16'd11) $display("INC test failed");

        // Test DEC r1 (r1 = r1 - 1)
        instruction = 19'b0101_0001_0000_0000_000; // opcode=0101, rs=r1, func=000
        uut.registers[1] = 16'd10;
        #10;
        if (uut.registers[1] !== 16'd9) $display("DEC test failed");

        // Test AND r1, r2, r3 (r1 = r2 & r3)
        instruction = 19'b0110_0001_0010_0011_000; // opcode=0110, rs=r2, rt=r3, rd=r1, func=000
        uut.registers[2] = 16'b1100;
        uut.registers[3] = 16'b1010;
        #10;
        if (uut.registers[1] !== 16'b1000) $display("AND test failed");

        // Test OR r1, r2, r3 (r1 = r2 | r3)
        instruction = 19'b0111_0001_0010_0011_000; // opcode=0111, rs=r2, rt=r3, rd=r1, func=000
        uut.registers[2] = 16'b1100;
        uut.registers[3] = 16'b1010;
        #10;
        if (uut.registers[1] !== 16'b1110) $display("OR test failed");

        // Test XOR r1, r2, r3 (r1 = r2 ^ r3)
        instruction = 19'b1000_0001_0010_0011_000; // opcode=1000, rs=r2, rt=r3, rd=r1, func=000
        uut.registers[2] = 16'b1100;
        uut.registers[3] = 16'b1010;
        #10;
        if (uut.registers[1] !== 16'b0110) $display("XOR test failed");

        // Test NOT r1, r2 (r1 = ~r2)
        instruction = 19'b1001_0001_0010_0000_000; // opcode=1009, rs=r2, rd=r1, func=000
        uut.registers[2] = 16'b1100;
        #10;
        if (uut.registers[1] !== ~16'b1100) $display("NOT test failed");

        // Test JMP addr (PC = addr)
        instruction = 19'b1100_0000_0000_0000_001; // opcode=1100, addr=1 (PC = 1)
        #10;
        if (uut.PC !== 16'b1) $display("JMP test failed");

        // Test BEQ r1, r2, addr (if (r1 == r2) PC = addr)
        instruction = 19'b1101_0001_0001_0000_001; // opcode=1101, rs=r1, rt=r1, addr=1 (PC = 1 if r1 == r1)
        uut.registers[1] = 16'b1010;
        #10;
        if (uut.PC !== 16'b1) $display("BEQ test failed");

        // Test BNE r1, r2, addr (if (r1 != r2) PC = addr)
        instruction = 19'b1110_0001_0010_0000_010; // opcode=1110, rs=r1, rt=r2, addr=2 (PC = 2 if r1 != r2)
        uut.registers[1] = 16'b1010;
        uut.registers[2] = 16'b1100;
        #10;
        if (uut.PC !== 16'b10) $display("BNE test failed");

        // Test CALL addr (store PC+1 in r15, PC = addr)
        instruction = 19'b1111_0000_0000_0000_011; // opcode=1111, addr=3 (PC = 3, r15 = PC+1)
        uut.PC = 16'b2;
        #10;
        if (uut.PC !== 16'b3 || uut.registers[15] !== 16'b3) $display("CALL test failed");

        $stop;
    end
endmodule

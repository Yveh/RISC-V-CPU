module instcache(
    input wire clk,
    input wire rst,
    input wire rdy,
    //IF
    input wire en_i,
    input wire[31:0] addr_i,
    output reg rdy_o,
    output reg[31:0] inst_o,
    //RC
    input wire rdy_i,
    input wire[31:0] inst_i,
    output reg en_o,
    output reg[31:0] addr_o
);

reg[31:0] cache[1023:0];
reg[21:0] tag[1023:0];
reg valid[1023:0];

always @ (posedge clk) begin
    if (rst) begin
        for (integer i = 0; i < 1024; i = i + 1)
            valid[i] <= 1'b0;
    end
    else if (rdy && rdy_i) begin
        tag[addr_i[9:0]] <= addr_i[31:10];
        cache[addr_i[9:0]] <= inst_i;
        valid[addr_i[9:0]] <= 1'b1;
    end
end

always @ (*) begin
    if (rst || !en_i) begin
        rdy_o = 1'b0;
        inst_o = 32'b0;
        en_o = 1'b0;
        addr_o = 32'b0;
    end
    else if (rdy_i) begin
        rdy_o = 1'b1;
        inst_o = inst_i;
        en_o = 1'b0;
        addr_o = 32'b0;
    end
    else if (valid[addr_i[9:0]] && tag[addr_i[9:0]] == addr_i[31:10]) begin
        rdy_o = 1'b1;
        inst_o = cache[addr_i[9:0]];
        en_o = 1'b0;
        addr_o = 32'b0;
    end
    else begin
        rdy_o = 1'b0;
        inst_o = 32'b0;
        en_o = 1'b1;
        addr_o = addr_i;
    end
end

endmodule // instcache
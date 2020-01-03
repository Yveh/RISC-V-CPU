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

reg[31:0] cache[511:0];
reg[20:0] tag[511:0];
reg[511:0] valid;

always @ (posedge clk) begin
    if (rst) begin
        valid = 1'b0;
    end
    else if (rdy) begin
        if (rdy_i) begin
            tag[addr_i[10:2]] <= addr_i[31:11];
            cache[addr_i[10:2]] <= inst_i;
            valid[addr_i[10:2]] <= 1'b1;
        end
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
    else if (valid[addr_i[10:2]] && tag[addr_i[10:2]] == addr_i[31:11]) begin
        rdy_o = 1'b1;
        inst_o = cache[addr_i[10:2]];
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
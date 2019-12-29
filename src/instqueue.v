module instqueue(
    input wire clk,
    input wire rst,
    input wire rst_c,
    input wire rdy,

    input wire we_i,
    input wire[31:0] inst_i,
    input wire[31:0] pc_i,
    input wire re_i,
    output reg[31:0] inst_o,
    output reg[31:0] pc_o,
    output reg full_o,
    output reg empty_o,
    output reg[31:0] debug
);

parameter cap = 5'h1f;

reg[31:0] pc[31:0];
reg[31:0] inst[31:0];
reg[4:0] head, tail;

always @ (posedge clk) begin
    if (rst || rst_c) begin
        head <= 1'b0;
        tail <= 1'b0;
        full_o <= 1'b0;
        empty_o <= 1'b1;
    end
    else if (rdy) begin
        if (we_i) begin
            inst[tail] <= inst_i;
            pc[tail] <= pc_i;
        end
        head <= head + re_i;
        tail <= tail + we_i;
        full_o <= (tail - head - re_i + we_i == cap) ? 1'b1 : 1'b0;
        empty_o <= (tail - head - re_i + we_i == 1'b0) ? 1'b1 : 1'b0;
        if (tail - head - re_i == 1'b0 && we_i) begin
            inst_o <= inst_i;
            pc_o <= pc_i;
        end
        else begin
            inst_o <= inst[head + re_i];
            pc_o <= pc[head + re_i];
        end
    end
end

endmodule // instqueue
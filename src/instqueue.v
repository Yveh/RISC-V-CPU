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
    output reg empty_o
);

parameter cap = 5'h1e;

reg[31:0] pc[31:0];
reg[31:0] inst[31:0];
reg[4:0] head, tail;

wire full, empty;
wire[4:0] head_p;

assign full = (tail + we_i - head - re_i >= cap) ? 1'b1 : 1'b0;
assign empty = (tail + we_i - head - re_i == 1'b0) ? 1'b1 : 1'b0;
assign head_p = head + re_i;

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
        full_o <= full;
        empty_o <= empty;
        if (tail == head_p && we_i) begin
            inst_o <= inst_i;
            pc_o <= pc_i;
        end
        else begin
            inst_o <= inst[head_p];
            pc_o <= pc[head_p];
        end
    end
end

endmodule // instqueue
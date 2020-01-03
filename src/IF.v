module IF(
    input wire clk,
    input wire rst,
    input wire rdy,
    //to cache
    input wire rdy_cache_i,
    input wire[31:0] inst_cache_i,
    output reg en_cache_o,
    output reg[31:0] addr_cache_o,
    //to commit
    input wire en_i,
    input wire[31:0] pc_i,
    //to queue
    input wire full_queue_i,
    output reg we_queue_o,
    output reg[31:0] inst_queue_o,
    output reg[31:0] pc_queue_o
);

reg[31:0] pc;
reg[31:0] npc;

always @ (posedge clk) begin
    if (rst) begin
        pc <= 32'b0;
        npc <= 32'h4;
        en_cache_o <= 1'b0;
        we_queue_o <= 1'b0;
    end
    else if (rdy) begin
        if (en_i) begin
            pc <= pc_i;
            npc <= pc_i + 32'h4;
            en_cache_o <= 1'b1;
            addr_cache_o <= pc_i;
            we_queue_o <= 1'b0;
        end
        else if (rdy_cache_i && !full_queue_i) begin
            pc <= npc;
            npc <= npc + 32'h4;
            en_cache_o <= 1'b1;
            addr_cache_o <= npc;
            we_queue_o <= 1'b1;
            inst_queue_o <= inst_cache_i;
            pc_queue_o <= pc;
        end else begin
            en_cache_o <= 1'b1;
            addr_cache_o <= pc;
            we_queue_o <= 1'b0;
        end
    end
end

endmodule // IF
module commit(
    input wire rst,
    input wire clk,

    input wire en_i,
    input wire[4:0] regaddr_i,
    input wire[4:0] id_i,
    input wire[31:0] data_i,
    input wire[31:0] pc_i,
    input wire[1:0] branch_tag_i,
    input wire cond_i,

    output reg we_regfile_o,
    output reg[4:0] waddr_regfile_o,
    output reg[4:0] wid_regfile_o,
    output reg[31:0] wdata_regfile_o,
    output reg rdy_o,
    
    output reg rst_c,
    output reg en_if_o,
    output reg[31:0] pc_if_o
);

always @ (*) begin
    if (rst) begin
        we_regfile_o = 1'b0;
        waddr_regfile_o = 5'b0;
        wid_regfile_o = 5'b0;
        wdata_regfile_o = 32'b0;
        rdy_o = 1'b0;
        rst_c = 1'b0;
        en_if_o = 1'b0;
        pc_if_o = 32'b0;
    end
    else if (!en_i) begin
        we_regfile_o = 1'b0;
        waddr_regfile_o = 5'b0;
        wid_regfile_o = 5'b0;
        wdata_regfile_o = 32'b0;
        rdy_o = 1'b0;
        rst_c = 1'b0;
        en_if_o = 1'b0;
        pc_if_o = 32'b0;
    end
    else begin
        we_regfile_o = 1'b1;
        waddr_regfile_o = regaddr_i;
        wid_regfile_o = id_i;
        wdata_regfile_o = data_i;
        if (branch_tag_i == 2'b01 && cond_i != 1'b1 || branch_tag_i == 2'b10 && cond_i != 1'b0) begin
            rst_c = 1'b1;
            en_if_o = 1'b1;
            pc_if_o = pc_i;
        end
        else begin
            rst_c = 1'b0;
            en_if_o = 1'b0;
            pc_if_o = 32'b0;
        end
        rdy_o = 1'b1;
    end
end


endmodule // commit
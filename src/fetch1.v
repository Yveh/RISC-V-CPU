module fetch1(
    input wire clk,
    input wire rst,

    input wire[2:0] RS_id_i,
    input wire[31:0] Imm_i,
    input wire[6:0] OP_i,
    input wire[6:0] Funct7_i,
    input wire[2:0] Funct3_i,
    input wire[4:0] ROB_id_i,
    input wire[31:0] pc_i,
    input wire[4:0] A_addr_i,
    input wire[4:0] B_addr_i,
    
    input wire data1_rdy_regfile_i,
    input wire data2_rdy_regfile_i,
    input wire[31:0] data1_regfile_i,
    input wire[31:0] data2_regfile_i,
    input wire[4:0] data1_rid_regfile_i,
    input wire[4:0] data2_rid_regfile_i,
    output reg re1_regfile_o,
    output reg re2_regfile_o,
    output reg[4:0] addr1_regfile_o,
    output reg[4:0] addr2_regfile_o
);


always @ (*) begin
    if (rst) begin
        re1_regfile_o = 1'b0;
        addr1_regfile_o = 5'b0;
    end
    else begin
        re1_regfile_o = 1'b1;
        addr1_regfile_o = A_addr_i;
    end
end

always @ (*) begin
    if (rst) begin
        re2_regfile_o = 1'b0;
        addr2_regfile_o = 5'b0;
    end
    else begin
        re2_regfile_o = 1'b1;
        addr2_regfile_o = B_addr_i;
    end
end

endmodule //fetch1
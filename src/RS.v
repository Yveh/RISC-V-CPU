module RS(
    input wire clk,
    input wire rst,
    input wire rst_c,
    input wire rdy,
    
    input wire en_i,
    input wire[31:0] A_i,
    input wire[31:0] B_i,
    input wire A_rdy_i,
    input wire B_rdy_i,
    input wire[4:0] A_id_i,
    input wire[4:0] B_id_i,
    input wire[31:0] pc_i,
    input wire[31:0] Imm_i,
    input wire[6:0] OP_i,
    input wire[6:0] Funct7_i,
    input wire[2:0] Funct3_i,
    input wire[4:0] ROB_id_i,
    output reg busy,
    
    //to cdb
    input wire cdb1_en_i,
    input wire[4:0] cdb1_id_ROB_i,
    input wire[31:0] cdb1_data_i,

    input wire cdb2_en_i,
    input wire[4:0] cdb2_id_ROB_i,
    input wire[31:0] cdb2_data_i,

    input wire cdb3_en_i,
    input wire[4:0] cdb3_id_ROB_i,
    input wire[31:0] cdb3_data_i,

    output reg[31:0] A_o,
    output reg[31:0] B_o,
    output reg[31:0] Imm_o,
    output reg[31:0] pc_o,
    output reg[6:0] OP_o,
    output reg[6:0] Funct7_o,
    output reg[2:0] Funct3_o,
    output reg[4:0] ROB_id_o,
    output reg en_EX_o
);

reg A_rdy, B_rdy;
reg[4:0] A_id, B_id;
reg empty;

always @ (posedge clk) begin
    if (rst || rst_c) begin
        empty <= 1'b1;
        en_EX_o <= 1'b0;
        busy <= 1'b1;
    end
    else if (rdy) begin
        if (en_i) begin
            A_id <= A_id_i;
            B_id <= B_id_i;
            if (A_rdy_i) begin
                A_o <= A_i;
                A_rdy <= 1'b1;
            end
            else if (cdb1_en_i && A_id_i == cdb1_id_ROB_i) begin
                A_o <= cdb1_data_i;
                A_rdy <= 1'b1;
            end
            else if (cdb2_en_i && A_id_i == cdb2_id_ROB_i) begin
                A_o <= cdb2_data_i;
                A_rdy <= 1'b1;
            end
            else if (cdb3_en_i && A_id_i == cdb3_id_ROB_i) begin
                A_o <= cdb3_data_i;
                A_rdy <= 1'b1;
            end
            else begin
                A_rdy <= 1'b0;
            end
            if (B_rdy_i) begin
                B_o <= B_i;
                B_rdy <= 1'b1;
            end
            else if (cdb1_en_i && B_id_i == cdb1_id_ROB_i) begin
                B_o <= cdb1_data_i;
                B_rdy <= 1'b1;
            end
            else if (cdb2_en_i && B_id_i == cdb2_id_ROB_i) begin
                B_o <= cdb2_data_i;
                B_rdy <= 1'b1;
            end
            else if (cdb3_en_i && B_id_i == cdb3_id_ROB_i) begin
                B_o <= cdb3_data_i;
                B_rdy <= 1'b1;
            end
            else begin
                B_rdy <= 1'b0;
            end
            if ((A_rdy_i || 
                cdb1_en_i && A_id_i == cdb1_id_ROB_i || 
                cdb1_en_i && A_id_i == cdb1_id_ROB_i || 
                cdb1_en_i && A_id_i == cdb1_id_ROB_i) && 
                (B_rdy_i ||
                cdb1_en_i && B_id_i == cdb1_id_ROB_i ||
                cdb2_en_i && B_id_i == cdb2_id_ROB_i ||
                cdb3_en_i && B_id_i == cdb3_id_ROB_i)) begin
                empty <= 1'b1;
                busy <= 1'b0;
                en_EX_o <= 1'b1;
            end
            else begin
                empty <= 1'b0;
                busy <= 1'b1;
                en_EX_o <= 1'b0;
            end
            Imm_o <= Imm_i;
            pc_o <= pc_i;
            OP_o <= OP_i;
            Funct7_o <= Funct7_i;
            Funct3_o <= Funct3_i;
            ROB_id_o <= ROB_id_i;
        end
        else begin
            if (empty) begin
                empty <= 1'b1;
                busy <= 1'b0;
                en_EX_o <= 1'b0;
            end
            else begin
                if (A_rdy) begin
                    A_rdy <= 1'b1;
                end
                else if (cdb1_en_i && A_id == cdb1_id_ROB_i) begin
                    A_o <= cdb1_data_i;
                    A_rdy <= 1'b1;
                end
                else if (cdb2_en_i && A_id == cdb2_id_ROB_i) begin
                    A_o <= cdb2_data_i;
                    A_rdy <= 1'b1;
                end
                else if (cdb3_en_i && A_id == cdb3_id_ROB_i) begin
                    A_o <= cdb3_data_i;
                    A_rdy <= 1'b1;
                end

                if (B_rdy) begin
                    B_rdy <= 1'b1;
                end
                else if (cdb1_en_i && B_id == cdb1_id_ROB_i) begin
                    B_o <= cdb1_data_i;
                    B_rdy <= 1'b1;
                end
                else if (cdb2_en_i && B_id == cdb2_id_ROB_i) begin
                    B_o <= cdb2_data_i;
                    B_rdy <= 1'b1;
                end
                else if (cdb3_en_i && B_id == cdb3_id_ROB_i) begin
                    B_o <= cdb3_data_i;
                    B_rdy <= 1'b1;
                end

                if ((A_rdy || 
                    cdb1_en_i && A_id == cdb1_id_ROB_i || 
                    cdb1_en_i && A_id == cdb1_id_ROB_i || 
                    cdb1_en_i && A_id == cdb1_id_ROB_i) && 
                    (B_rdy ||
                    cdb1_en_i && B_id == cdb1_id_ROB_i ||
                    cdb2_en_i && B_id == cdb2_id_ROB_i ||
                    cdb3_en_i && B_id == cdb3_id_ROB_i)) begin
                    empty <= 1'b1;
                    busy <= 1'b0;
                    en_EX_o <= 1'b1;
                end
                else begin
                    empty <= 1'b0;
                    busy <= 1'b1;
                    en_EX_o <= 1'b0;
                end
            end
        end
    end
end

endmodule // RS
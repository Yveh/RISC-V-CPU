module fetch(
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
    output reg[4:0] addr2_regfile_o,

    input wire data1_rdy_ROB_i,
    input wire data2_rdy_ROB_i,
    input wire[31:0] data1_ROB_i,
    input wire[31:0] data2_ROB_i,
    output reg re1_ROB_o,
    output reg re2_ROB_o,
    output reg[4:0] rid1_ROB_o,
    output reg[4:0] rid2_ROB_o,
    
    output reg RS1_en_o,
    output reg[31:0] A_RS1_o,
    output reg[31:0] B_RS1_o,
    output reg A_rdy_RS1_o,
    output reg B_rdy_RS1_o,
    output reg[4:0] A_id_RS1_o,
    output reg[4:0] B_id_RS1_o,
    output reg[31:0] Imm_RS1_o,
    output reg[6:0] OP_RS1_o,
    output reg[6:0] Funct7_RS1_o,
    output reg[2:0] Funct3_RS1_o,
    output reg[31:0] pc_RS1_o,
    output reg[4:0] ROB_id_RS1_o,

    output reg RS2_en_o,
    output reg[31:0] A_RS2_o,
    output reg[31:0] B_RS2_o,
    output reg A_rdy_RS2_o,
    output reg B_rdy_RS2_o,
    output reg[4:0] A_id_RS2_o,
    output reg[4:0] B_id_RS2_o,
    output reg[31:0] Imm_RS2_o,
    output reg[6:0] OP_RS2_o,
    output reg[6:0] Funct7_RS2_o,
    output reg[2:0] Funct3_RS2_o,
    output reg[31:0] pc_RS2_o,
    output reg[4:0] ROB_id_RS2_o,

    output reg RS3_en_o,
    output reg[31:0] A_RS3_o,
    output reg[31:0] B_RS3_o,
    output reg A_rdy_RS3_o,
    output reg B_rdy_RS3_o,
    output reg[4:0] A_id_RS3_o,
    output reg[4:0] B_id_RS3_o,
    output reg[31:0] Imm_RS3_o,
    output reg[6:0] OP_RS3_o,
    output reg[2:0] Funct3_RS3_o,
    output reg[4:0] ROB_id_RS3_o
);

reg[31:0] A_o, B_o;
reg A_rdy_o, B_rdy_o;
reg[4:0] A_id_o, B_id_o;

always @ (*) begin
    if (rst) begin
        re1_regfile_o = 1'b0;
        addr1_regfile_o = 5'b0;
        re1_ROB_o = 1'b0;
        rid1_ROB_o = 5'b0;
        A_o = 32'b0;
        A_rdy_o = 1'b0;
        A_id_o = 5'b0;
    end
    else begin
        re1_regfile_o = 1'b1;
        addr1_regfile_o = A_addr_i;
        if (data1_rdy_regfile_i) begin
            re1_ROB_o = 1'b0;
            rid1_ROB_o = 5'b0;
            A_o = data1_regfile_i;
            A_rdy_o = 1'b1;
            A_id_o = 5'b0;
        end
        else begin
            re1_ROB_o = 1'b1;
            rid1_ROB_o = data1_rid_regfile_i;
            if (data1_rdy_ROB_i) begin
                A_o = data1_ROB_i;
                A_rdy_o = 1'b1;
                A_id_o = 5'b0;
            end
            else begin
                A_o = 32'b0;
                A_rdy_o = 1'b0;
                A_id_o = data1_rid_regfile_i;
            end
        end        
    end
end

always @ (*) begin
    if (rst) begin
        re2_regfile_o = 1'b0;
        addr2_regfile_o = 5'b0;
        re2_ROB_o = 1'b0;
        rid2_ROB_o = 5'b0;
        B_o = 32'b0;
        B_rdy_o = 1'b0;
        B_id_o = 5'b0;
    end
    else begin
        re2_regfile_o = 1'b1;
        addr2_regfile_o = B_addr_i;
        if (data2_rdy_regfile_i) begin
            re2_ROB_o = 1'b0;
            rid2_ROB_o = 5'b0;
            B_o = data2_regfile_i;
            B_rdy_o = 1'b1;
            B_id_o = 5'b0;
        end
        else begin
            re2_ROB_o = 1'b1;
            rid2_ROB_o = data2_rid_regfile_i;
            if (data2_rdy_ROB_i) begin
                B_o = data2_ROB_i;
                B_rdy_o = 1'b1;
                B_id_o = 5'b0;
            end
            else begin
                B_o = 32'b0;
                B_rdy_o = 1'b0;
                B_id_o = data2_rid_regfile_i;
            end
        end        
    end
end

always @ (*) begin
    if (rst) begin
        RS1_en_o = 1'b0;
        A_RS1_o = 32'b0;
        B_RS1_o = 32'b0;
        A_rdy_RS1_o = 1'b0;
        B_rdy_RS1_o = 1'b0;
        A_id_RS1_o = 5'b0;
        B_id_RS1_o = 5'b0;
        Imm_RS1_o = 32'b0;
        OP_RS1_o = 7'b0;
        Funct7_RS1_o = 7'b0;
        Funct3_RS1_o = 3'b0;
        pc_RS1_o = 32'b0;
        ROB_id_RS1_o = 5'b0;

        RS2_en_o = 1'b0;
        A_RS2_o = 32'b0;
        B_RS2_o = 32'b0;
        A_rdy_RS2_o = 1'b0;
        B_rdy_RS2_o = 1'b0;
        A_id_RS2_o = 5'b0;
        B_id_RS2_o = 5'b0;
        Imm_RS2_o = 32'b0;
        OP_RS2_o = 7'b0;
        Funct7_RS2_o = 7'b0;
        Funct3_RS2_o = 3'b0;
        pc_RS2_o = 32'b0;
        ROB_id_RS2_o = 5'b0;

        RS3_en_o = 1'b0;
        A_RS3_o = 32'b0;
        B_RS3_o = 32'b0;
        A_rdy_RS3_o = 1'b0;
        B_rdy_RS3_o = 1'b0;
        A_id_RS3_o = 5'b0;
        B_id_RS3_o = 5'b0;
        Imm_RS3_o = 32'b0;
        OP_RS3_o = 7'b0;
        Funct3_RS3_o = 3'b0;
        ROB_id_RS3_o = 5'b0;
    end
    else begin
        RS1_en_o = 1'b0;
        A_RS1_o = 32'b0;
        B_RS1_o = 32'b0;
        A_rdy_RS1_o = 1'b0;
        B_rdy_RS1_o = 1'b0;
        A_id_RS1_o = 5'b0;
        B_id_RS1_o = 5'b0;
        Imm_RS1_o = 32'b0;
        OP_RS1_o = 7'b0;
        Funct7_RS1_o = 7'b0;
        Funct3_RS1_o = 3'b0;
        pc_RS1_o = 32'b0;
        ROB_id_RS1_o = 5'b0;
        
        RS2_en_o = 1'b0;
        A_RS2_o = 32'b0;
        B_RS2_o = 32'b0;
        A_rdy_RS2_o = 1'b0;
        B_rdy_RS2_o = 1'b0;
        A_id_RS2_o = 5'b0;
        B_id_RS2_o = 5'b0;
        Imm_RS2_o = 32'b0;
        OP_RS2_o = 7'b0;
        Funct7_RS2_o = 7'b0;
        Funct3_RS2_o = 3'b0;
        pc_RS2_o = 32'b0;
        ROB_id_RS2_o = 5'b0;

        RS3_en_o = 1'b0;
        A_RS3_o = 32'b0;
        B_RS3_o = 32'b0;
        A_rdy_RS3_o = 1'b0;
        B_rdy_RS3_o = 1'b0;
        A_id_RS3_o = 5'b0;
        B_id_RS3_o = 5'b0;
        Imm_RS3_o = 32'b0;
        OP_RS3_o = 7'b0;
        Funct3_RS3_o = 3'b0;
        ROB_id_RS3_o = 5'b0;

        if (RS_id_i[0]) begin
            RS1_en_o = 1'b1;
            A_RS1_o = A_o;
            B_RS1_o = B_o;
            A_rdy_RS1_o = A_rdy_o;
            B_rdy_RS1_o = B_rdy_o;
            A_id_RS1_o = A_id_o;
            B_id_RS1_o = B_id_o; 
            Imm_RS1_o = Imm_i;
            OP_RS1_o = OP_i;
            Funct7_RS1_o = Funct7_i;
            Funct3_RS1_o = Funct3_i;
            pc_RS1_o = pc_i;
            ROB_id_RS1_o = ROB_id_i;
        end
        if (RS_id_i[1]) begin
            RS2_en_o = 1'b1;
            A_RS2_o = A_o;
            B_RS2_o = B_o;
            A_rdy_RS2_o = A_rdy_o;
            B_rdy_RS2_o = B_rdy_o;
            A_id_RS2_o = A_id_o;
            B_id_RS2_o = B_id_o; 
            Imm_RS2_o = Imm_i;
            OP_RS2_o = OP_i;
            Funct7_RS2_o = Funct7_i;
            Funct3_RS2_o = Funct3_i;
            pc_RS2_o = pc_i;
            ROB_id_RS2_o = ROB_id_i;
        end
        if (RS_id_i[2]) begin
            RS3_en_o = 1'b1;
            A_RS3_o = A_o;
            B_RS3_o = B_o;
            A_rdy_RS3_o = A_rdy_o;
            B_rdy_RS3_o = B_rdy_o;
            A_id_RS3_o = A_id_o;
            B_id_RS3_o = B_id_o;
            Imm_RS3_o = Imm_i;
            OP_RS3_o = OP_i;
            Funct3_RS3_o = Funct3_i;
            ROB_id_RS3_o = ROB_id_i;
        end
    end
end
endmodule // fetch
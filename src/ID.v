module ID(
    input wire clk,
    input wire rst, 
    //to instqueue
    input wire[31:0] inst_queue_i,
    input wire[31:0] pc_queue_i,
    input wire inst_empty_queue_i,
    output reg re_queue_o,
    //to ROB
    input wire add_full_ROB_i,
    input wire[4:0] add_id_ROB_i,
    output reg add_en_ROB_o,
    output reg add_rdytag_o,
    output reg[4:0] add_regaddr_ROB_o,
    output reg[1:0] add_branch_tag_ROB_o,
    //to regfile
    output reg wait_en_regfile_o,
    output reg[4:0] wait_regaddr_regfile_o,
    output reg[4:0] wait_id_regfile_o,
    //to EX
    input wire busySL_i,
    input wire busy1_i,
    input wire busy2_i,
    output reg[2:0] RS_id_o,
    output reg[31:0] Imm_o,
    output reg[6:0] OP_o,
    output reg[6:0] Funct7_o,
    output reg[2:0] Funct3_o,
    output reg[4:0] ROB_id_o,
    output reg[31:0] pc_o,
    output reg[4:0] A_addr_o,
    output reg[4:0] B_addr_o
);

always @ (*) begin
    if (rst) begin
        re_queue_o = 1'b0;
        add_en_ROB_o = 1'b0;
        wait_en_regfile_o = 1'b0;
        RS_id_o = 3'b0;

        wait_regaddr_regfile_o = 5'b0;
        wait_id_regfile_o = 5'b0;
        add_rdytag_o = 1'b0;
        add_regaddr_ROB_o = 5'b0;
        add_branch_tag_ROB_o = 2'b0;
        Imm_o = 32'b0;
        OP_o = 7'b0;
        Funct7_o = 7'b0;
        Funct3_o = 3'b0;
        ROB_id_o = 5'b0;
        pc_o = 32'b0;
        A_addr_o = 5'b0;
        B_addr_o = 5'b0;
    end
    else begin
        re_queue_o = 1'b0;
        add_en_ROB_o = 1'b0;
        wait_en_regfile_o = 1'b0;
        RS_id_o = 3'b0;

        wait_regaddr_regfile_o = inst_queue_i[11:7];
        wait_id_regfile_o = add_id_ROB_i;
        add_rdytag_o = 1'b0;
        add_regaddr_ROB_o = inst_queue_i[11:7];
        add_branch_tag_ROB_o = 2'b0;
        OP_o = inst_queue_i[6:0];
        Funct7_o = inst_queue_i[31:25];
        Funct3_o = inst_queue_i[14:12];
        pc_o = pc_queue_i;
        ROB_id_o = add_id_ROB_i;
        Imm_o = 32'b0;
        A_addr_o = 5'b0;
        B_addr_o = 5'b0;
        if (!inst_empty_queue_i) begin
            case (inst_queue_i[6:0])
                7'b0110111, 7'b0010111: begin
                    if (!add_full_ROB_i && (!busy1_i || !busy2_i)) begin
                        re_queue_o = 1'b1;
                        add_en_ROB_o = 1'b1;
                        RS_id_o = !busy1_i ? 3'b001 : 3'b010;
                        wait_en_regfile_o = 1'b1;
                    end
                    Imm_o = {inst_queue_i[31:12], 12'b0};
                    A_addr_o = 5'b0;
                    B_addr_o = 5'b0;
                end
                7'b1101111: begin
                    if (!add_full_ROB_i && (!busy1_i || !busy2_i)) begin
                        re_queue_o = 1'b1;
                        add_en_ROB_o = 1'b1;
                        add_branch_tag_ROB_o = 2'b10;
                        RS_id_o = !busy1_i ? 3'b001 : 3'b010;
                        wait_en_regfile_o = 1'b1;
                    end
                    Imm_o = {{12{inst_queue_i[31]}}, inst_queue_i[19:12], inst_queue_i[20], inst_queue_i[30:21], 1'b0};
                    A_addr_o = 5'b0;
                    B_addr_o = 5'b0;
                end
                7'b0000011: begin
                    if (!add_full_ROB_i && !busySL_i) begin
                        re_queue_o = 1'b1;
                        add_en_ROB_o = 1'b1;
                        add_branch_tag_ROB_o = 2'b11;
                        RS_id_o = 3'b100;
                        wait_en_regfile_o = 1'b1;
                    end
                    Imm_o = {{20{inst_queue_i[31]}}, inst_queue_i[31:20]};
                    A_addr_o = inst_queue_i[19:15];
                    B_addr_o = 5'b0;
                end
                7'b1100111: begin
                    if (!add_full_ROB_i && (!busy1_i || !busy2_i)) begin
                        re_queue_o = 1'b1;
                        add_en_ROB_o = 1'b1;
                        add_branch_tag_ROB_o = 2'b10;
                        RS_id_o = !busy1_i ? 3'b001 : 3'b010;
                        wait_en_regfile_o = 1'b1;
                    end
                    Imm_o = {{20{inst_queue_i[31]}}, inst_queue_i[31:20]};
                    A_addr_o = inst_queue_i[19:15];
                    B_addr_o = 5'b0;
                end
                7'b0010011: begin
                    if (!add_full_ROB_i && (!busy1_i || !busy2_i)) begin
                        re_queue_o = 1'b1;
                        add_en_ROB_o = 1'b1;
                        RS_id_o = !busy1_i ? 3'b001 : 3'b010;
                        wait_en_regfile_o = 1'b1;
                    end
                    Imm_o = {{20{inst_queue_i[31]}}, inst_queue_i[31:20]};
                    A_addr_o = inst_queue_i[19:15];
                    B_addr_o = inst_queue_i[24:20];
                end
                7'b1100011: begin
                    if (!add_full_ROB_i && (!busy1_i || !busy2_i)) begin
                        re_queue_o = 1'b1;
                        add_en_ROB_o = 1'b1;
                        add_regaddr_ROB_o = 5'b0;
                        add_branch_tag_ROB_o = 2'b10;
                        RS_id_o = !busy1_i ? 3'b001 : 3'b010;
                    end
                    Imm_o = {{20{inst_queue_i[31]}}, inst_queue_i[7], inst_queue_i[30:25], inst_queue_i[11:8], 1'b0};
                    A_addr_o = inst_queue_i[19:15];
                    B_addr_o = inst_queue_i[24:20];
                end
                7'b0100011: begin
                    if (!busySL_i) begin
                        re_queue_o = 1'b1;
                        add_en_ROB_o = 1'b1;
                        add_rdytag_o = 1'b1;
                        add_regaddr_ROB_o = 5'b0;
                        add_branch_tag_ROB_o = 2'b11;
                        RS_id_o = 3'b100;
                    end
                    Imm_o = {{20{inst_queue_i[31]}}, inst_queue_i[31:25], inst_queue_i[11:7]};
                    A_addr_o = inst_queue_i[19:15];
                    B_addr_o = inst_queue_i[24:20];
                end
                7'b0110011: begin
                    if (!add_full_ROB_i && (!busy1_i || !busy2_i)) begin
                        re_queue_o = 1'b1;
                        add_en_ROB_o = 1'b1;
                        RS_id_o = !busy1_i ? 3'b001 : 3'b010;
                        wait_en_regfile_o = 1'b1;
                    end
                    Imm_o = 32'b0;
                    A_addr_o = inst_queue_i[19:15];
                    B_addr_o = inst_queue_i[24:20];
                end
                default: begin
                    Imm_o = 32'b0;
                    A_addr_o = 5'b0;
                    B_addr_o = 5'b0;
                end
            endcase
        end
    end
end

endmodule // ID
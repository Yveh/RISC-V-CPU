module EX(
    input wire clk,
    input wire rst,
    input wire en_i,
    input wire[31:0] A_i,
    input wire[31:0] B_i,
    input wire[31:0] Imm_i,
    input wire[31:0] pc_i,
    input wire[6:0] OP_i,
    input wire[6:0] Funct7_i,
    input wire[2:0] Funct3_i,
    input wire[4:0] ROB_id_i,

    output reg cdb_en_o,
    output reg[4:0] cdb_id_ROB_o,
    output reg[31:0] cdb_data_o,
    output reg[31:0] cdb_pc_o,
    output reg cdb_cond_o
);

always @ (*) begin
    if (rst || !en_i) begin
        cdb_en_o = 1'b0;
        cdb_id_ROB_o = 5'b0;
        cdb_data_o = 32'b0;
        cdb_pc_o = 32'b0;
        cdb_cond_o = 1'b0;
    end    
    else begin
        cdb_en_o = 1'b1;
        cdb_id_ROB_o = ROB_id_i;
        cdb_data_o = 32'b0;
        cdb_pc_o = 32'b0;
        cdb_cond_o = 1'b0;
        case (OP_i)
            7'b0110111:
                cdb_data_o = Imm_i;
            7'b0010111: 
                cdb_data_o = Imm_i + pc_i;
            7'b0010011: begin
                case (Funct3_i)
                    3'b000:
                        cdb_data_o = A_i + Imm_i;
                    3'b001:
                        cdb_data_o = A_i << Imm_i[5:0];
                    3'b010:
                        cdb_data_o = A_i < $unsigned(Imm_i);
                    3'b011:
                        cdb_data_o = $signed(A_i) < Imm_i;
                    3'b100:
                        cdb_data_o = A_i ^ Imm_i;
                    3'b101: begin
                        case (Funct7_i)
                            7'b0000000: 
                                cdb_data_o = A_i >> Imm_i[5:0];
                            7'b0100000:
                                cdb_data_o = $signed(A_i) >> Imm_i[5:0];
                            default: ;
                        endcase
                    end
                    3'b110:
                        cdb_data_o = A_i | Imm_i;
                    3'b111:
                        cdb_data_o = A_i & Imm_i;
                    default: ;
                endcase
            end
            7'b0110011: begin
                case (Funct3_i)
                    3'b000: begin
                        case (Funct7_i)
                            7'b0000000:
                                cdb_data_o = A_i + B_i;
                            7'b0100000:
                                cdb_data_o = A_i - B_i;
                            default: ;
                        endcase
                    end
                    3'b001:
                        cdb_data_o = A_i << B_i[5:0];
                    3'b010:
                        cdb_data_o = $signed(A_i) < $signed(B_i);
                    3'b011:
                        cdb_data_o = A_i < B_i;
                    3'b100:
                        cdb_data_o = A_i ^ B_i;
                    3'b101: begin
                        case (Funct7_i)
                            7'b0000000: 
                                cdb_data_o = A_i >> B_i[5:0];
                            7'b0100000:
                                cdb_data_o = $signed(A_i) >> B_i[5:0];
                            default: ;
                        endcase
                    end
                    3'b110:
                        cdb_data_o = A_i | B_i;
                    3'b111:
                        cdb_data_o = A_i & B_i;
                    default: ;
                endcase
            end
            7'b1100111: begin
                cdb_data_o = pc_i + 32'h4;
                cdb_pc_o = A_i + Imm_i;
                cdb_cond_o = 1'b1;
            end
            7'b1101111: begin
                cdb_data_o = pc_i + 32'h4;
                cdb_pc_o = pc_i + Imm_i;
                cdb_cond_o = 1'b1;
            end
            7'b1100011: begin
                cdb_data_o = 32'bx;
                cdb_pc_o = pc_i + Imm_i;
                case (Funct3_i)
                    3'b000:
                        cdb_cond_o = A_i == B_i;
                    3'b001:
                        cdb_cond_o = A_i != B_i;
                    3'b100:
                        cdb_cond_o = $signed(A_i) < $signed(B_i);
                    3'b101:
                        cdb_cond_o = $signed(A_i) >= $signed(B_i);
                    3'b110:
                        cdb_cond_o = A_i < B_i;
                    3'b111:
                        cdb_cond_o = A_i >= B_i;
                    default: ;
                endcase
            end
            default: ;
        endcase
    end
end

endmodule // EX
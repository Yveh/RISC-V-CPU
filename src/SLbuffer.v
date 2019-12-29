module SLbuffer(
    input wire clk,
    input wire rst,
    input wire rst_c,
    input wire rdy,

    output reg empty_o,
    output reg full_o,
    //to RS
    input wire RS_en_i,
    input wire[31:0] A_i,
    input wire[31:0] B_i,
    input wire[31:0] Imm_i,
    input wire[6:0] OP_i,
    input wire[2:0] Funct3_i, 
    input wire[4:0] ROB_id_i,

    //to cache
    input wire rdy_i,
    input wire[31:0] data_i,
    output reg en_o,
    output reg rw_o,
    output reg[31:0] addr_o,
    output reg[31:0] data_o,
    output reg[2:0] width_o,

    output reg cdb_en_o,
    output reg[4:0] cdb_id_o,
    output reg[31:0] cdb_data_o
);

parameter cap = 5'h1f;

reg[31:0] A[31:0], B[31:0], Imm[31:0];
reg[31:0] OP[6:0];
reg[4:0] ROB_id[31:0];
reg[2:0] Funct3[31:0];
reg[4:0] head, tail;

always @ (posedge clk or negedge rst) begin
    if (rst || rst_c) begin
        head <= 1'b0;
        tail <= 1'b0;
        full_o <= 1'b0;
        empty_o <= 1'b1;
        en_o <= 1'b0;
        cdb_en_o <= 1'b0;
    end
    else if (rdy) begin
        if (RS_en_i) begin
            A[tail] <= A_i;
            B[tail] <= B_i;
            Imm[tail] <= Imm_i;
            OP[tail] <= OP_i;
            Funct3[tail] <= Funct3_i;
            ROB_id[tail] <= ROB_id_i;
        end
        head <= head + rdy_i;
        tail <= tail + RS_en_i;
        full_o <= (tail - head - rdy_i + RS_en_i == cap) ? 1'b1 : 1'b0;
        empty_o <= (tail - head - rdy_i + RS_en_i == 1'b0) ? 1'b1 : 1'b0;

        if (tail - head - rdy_i == 1'b0) begin
            if (RS_en_i) begin
                en_o = 1'b1;
                addr_o <= A_i + Imm_i;
                data_o <= B_i;
                case (OP_i)
                    7'b0000011: begin
                        rw_o <= 1'b1;
                    end
                    7'b0100011:
                        rw_o <= 1'b0;
                    default: ;
                endcase
                case (Funct3_i)
                    3'b000, 3'b100:
                        width_o <= 3'h1;
                    3'b001, 3'b101:
                        width_o <= 3'h2;
                    3'b010:
                        width_o <= 3'h4;
                    default: 
                        width_o <= 3'b0;
                endcase
            end
            else
                en_o = 1'b0;
        end
        else begin
            en_o <= 1'b1;
            addr_o <= A[head + rdy_i] + Imm[head + rdy_i];
            data_o <= B[head + rdy_i];
            case (OP[head + rdy_i])
                7'b0000011: begin
                    rw_o <= 1'b1;
                end
                7'b0100011:
                    rw_o <= 1'b0;
                default: ;
            endcase
            case (Funct3[head + rdy_i])
                3'b000, 3'b100:
                    width_o <= 3'h1;
                3'b001, 3'b101:
                    width_o <= 3'h2;
                3'b010:
                    width_o <= 3'h4;
                default: 
                    width_o <= 3'b0;
            endcase
        end

        if (rdy_i) begin
            cdb_en_o <= 1'b1;
            cdb_id_o <= ROB_id[head];
            case (Funct3[head])
                3'b000: 
                    cdb_data_o <= {{24{data_i[7]}}, data_i[7:0]};
                3'b001:
                    cdb_data_o <= {{16{data_i[15]}}, data_i[15:0]};
                3'b010:
                    cdb_data_o <= data_i;
                3'b100:
                    cdb_data_o <= {24'b0, data_i[7:0]};
                3'b101:
                    cdb_data_o <= {16'b0, data_i[15:0]};
                default: 
                    cdb_data_o <= 32'b0;
            endcase
        end
        else begin
            cdb_en_o <= 1'b0;
        end
    end
end
endmodule // SLbuffer
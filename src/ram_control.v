module ram_control(
    input wire clk,
    input wire rst,
    input wire rst_c,
    input wire rdy,
    //rinst
    input wire inst_en_i,
    input wire[31:0] inst_addr_i,
    output reg inst_rdy_o,
    output reg[31:0] inst_inst_o,
    //rdata
    input wire data_en_i,
    input wire data_rw_i,
    input wire[2:0] data_width_i,
    input wire[31:0] data_addr_i,
    input wire[31:0] data_data_i,
    output reg data_rdy_o,
    output reg[31:0] data_data_o,
    //ram
    input wire[7:0] ram_i,
    output reg ram_rw_o,
    output reg[31:0] ram_addr_o,
    output reg[7:0] ram_data_o
);

parameter IDLE = 3'b000;
parameter S0 = 3'b001;
parameter S1 = 3'b010;
parameter S2 = 3'b011;
parameter S3 = 3'b100;
parameter OK = 3'b101;

parameter None = 2'b00;
parameter Rinst = 2'b01;
parameter Rdata = 2'b10;
parameter Wdata = 2'b11;

reg[2:0] state, state_p;
reg[31:0] data_o;
reg[1:0] mod_p;

always @ (posedge clk) begin
    if (rst || rst_c) begin
        inst_rdy_o <= 1'b0;
        data_rdy_o <= 1'b0;
    end
    else if (rdy) begin
        case (mod_p)
            Rinst: begin
                case (state_p)
                    S0: begin
                        data_o[7:0] <= ram_i;
                        inst_rdy_o <= 1'b0;
                        data_rdy_o <= 1'b0;
                    end
                    S1: begin
                        data_o[15:8] <= ram_i;
                        inst_rdy_o <= 1'b0;
                        data_rdy_o <= 1'b0;
                    end
                    S2: begin
                        data_o[23:16] <= ram_i;
                        inst_rdy_o <= 1'b0;
                        data_rdy_o <= 1'b0;
                    end
                    S3: begin
                        data_o[31:24] <= ram_i;
                        inst_rdy_o <= 1'b1;
                        inst_inst_o <= {ram_i, data_o[23:0]};
                        data_rdy_o <= 1'b0;
                    end
                    default: begin
                        inst_rdy_o <= 1'b0;
                        data_rdy_o <= 1'b0;
                    end
                endcase
            end
            Rdata: begin
                case (state_p)
                    S0: begin
                        data_o[7:0] <= ram_i;
                        inst_rdy_o <= 1'b0;
                        if (data_width_i == 3'h1) begin
                            data_rdy_o <= 1'b1;
                            data_data_o <= {23'b0, ram_i};
                        end
                        else begin
                            data_rdy_o <= 1'b0;
                        end
                    end
                    S1: begin
                        data_o[15:8] <= ram_i;
                        inst_rdy_o <= 1'b0;
                        if (data_width_i == 3'h2) begin
                            data_rdy_o <= 1'b1;
                            data_data_o <= {16'b0, ram_i, data_o[7:0]};
                        end
                        else begin
                            data_rdy_o <= 1'b0;
                        end
                    end
                    S2: begin
                        data_o[23:16] <= ram_i;
                        inst_rdy_o <= 1'b0;
                        data_rdy_o <= 1'b0;
                    end
                    S3: begin
                        data_o[31:24] <= ram_i;
                        inst_rdy_o <= 1'b0;
                        data_rdy_o <= 1'b1;
                        data_data_o <= {ram_i, data_o[23:0]};
                    end
                    default: begin
                        inst_rdy_o <= 1'b0;
                        data_rdy_o <= 1'b0;
                    end
                endcase
            end
            Wdata: begin
                case (state_p)
                    S0: begin
                        inst_rdy_o <= 1'b0;
                        if (data_width_i == 3'h1) begin
                            data_rdy_o <= 1'b1;
                        end
                        else begin
                            data_rdy_o <= 1'b0;
                        end
                    end
                    S1: begin
                        inst_rdy_o <= 1'b0;
                        if (data_width_i == 3'h2) begin
                            data_rdy_o <= 1'b1;
                        end
                        else begin
                            data_rdy_o <= 1'b0;
                        end
                    end
                    S2: begin
                        inst_rdy_o <= 1'b0;
                        data_rdy_o <= 1'b0;
                    end
                    S3: begin
                        inst_rdy_o <= 1'b0;
                        data_rdy_o <= 1'b1;
                    end
                    default: begin
                        inst_rdy_o <= 1'b0;
                        data_rdy_o <= 1'b0;
                    end
                endcase
            end
            default: begin
                inst_rdy_o <= 1'b0;
                data_rdy_o <= 1'b0;
            end
        endcase

    end
end

always @ (posedge clk) begin
    if (rst || rst_c) begin
        state <= IDLE;
        state_p <= IDLE;
        mod_p <= None;
    end
    else if (rdy) begin
        state_p <= state;
        case (state)
            IDLE: begin
                if (data_en_i && !data_rw_i) begin
                    mod_p <= Wdata;
                    state <= S0;
                end
                else if (data_en_i && data_rw_i) begin
                    mod_p <= Rdata;
                    state <= S0;
                end
                else if (inst_en_i) begin
                    mod_p <= Rinst;
                    state <= S0;
                end
                else begin
                    mod_p <= None;
                    state <= IDLE;
                end
            end
            S0: begin
                if ((mod_p == Rdata || mod_p == Wdata) && data_width_i == 3'h1)
                    state <= OK;
                else
                    state <= S1;
            end
            S1: begin
                if ((mod_p == Rdata || mod_p == Wdata) && data_width_i == 3'h2)
                    state <= OK;
                else
                    state <= S2;
            end
            S2: begin
                state <= S3;
            end
            S3: begin
                state <= OK;
            end
            OK: begin
                mod_p <= None;
                state <= IDLE;
            end
            default: ;
        endcase
    end
end

always @ (*) begin
    if (rst) begin
        ram_rw_o = 1'b0;
        ram_addr_o = 32'b0;
        ram_data_o = 8'b0;
    end
    else begin
        case (state)
            S0: begin
                case (mod_p)
                    Rinst: begin
                        ram_rw_o = 1'b0;
                        ram_addr_o = inst_addr_i;
                        ram_data_o = 8'b0;
                    end
                    Rdata: begin
                        ram_rw_o = 1'b0;
                        ram_addr_o = data_addr_i;
                        ram_data_o = 8'b0;
                    end
                    Wdata: begin
                        ram_rw_o = 1'b1;
                        ram_addr_o = data_addr_i;
                        ram_data_o = data_data_i[7:0];
                    end
                    default: ;
                endcase
            end
            S1: begin
                case (mod_p)
                    Rinst: begin
                        ram_rw_o = 1'b0;
                        ram_addr_o = inst_addr_i + 32'h1;
                        ram_data_o = 8'b0;
                    end
                    Rdata: begin
                        ram_rw_o = 1'b0;
                        ram_addr_o = data_addr_i + 32'h1;
                        ram_data_o = 8'b0;
                    end
                    Wdata: begin
                        ram_rw_o = 1'b1;
                        ram_addr_o = data_addr_i + 32'h1;
                        ram_data_o = data_data_i[15:8];
                    end
                    default: ;
                endcase
            end
            S2: begin
                case (mod_p)
                    Rinst: begin
                        ram_rw_o = 1'b0;
                        ram_addr_o = inst_addr_i + 32'h2;
                        ram_data_o = 8'b0;
                    end
                    Rdata: begin
                        ram_rw_o = 1'b0;
                        ram_addr_o = data_addr_i + 32'h2;
                        ram_data_o = 8'b0;
                    end
                    Wdata: begin
                        ram_rw_o = 1'b1;
                        ram_addr_o = data_addr_i + 32'h2;
                        ram_data_o = data_data_i[23:16];
                    end
                    default: ;
                endcase
            end
            S3: begin
                case (mod_p)
                    Rinst: begin
                        ram_rw_o = 1'b0;
                        ram_addr_o = inst_addr_i + 32'h3;
                        ram_data_o = 8'b0;
                    end
                    Rdata: begin
                        ram_rw_o = 1'b0;
                        ram_addr_o = data_addr_i + 32'h3;
                        ram_data_o = 8'b0;
                    end
                    Wdata: begin
                        ram_rw_o = 1'b1;
                        ram_addr_o = data_addr_i + 32'h3;
                        ram_data_o = data_data_i[31:24];
                    end
                    default: ;
                endcase
            end
            OK: begin
                ram_rw_o = 1'b0;
                ram_addr_o = 32'b0;
                ram_data_o = 8'b0;
            end
            default: begin
                ram_rw_o = 1'b0;
                ram_addr_o = 32'b0;
                ram_data_o = 8'b0;
            end
        endcase
    end
end
endmodule // ram_control
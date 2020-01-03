module datacache(
    input wire clk,
    input wire rst,
    input wire rdy,

    input wire en_i,
    input wire rw_i,
    input wire[2:0] width_i,
    input wire[31:0] addr_i,
    input wire[31:0] data_i,
    output reg rdy_o,
    output reg[31:0] data_o,
    //RC
    input wire rdy_i,
    input wire[31:0] data_rc_i,
    output reg en_o,
    output reg rw_o,
    output reg[2:0] width_o,
    output reg[31:0] addr_rc_o,
    output reg[31:0] data_rc_o
);


reg[31:0] cache[511:0];
reg[20:0] tag[511:0];
reg[511:0] valid;

always @ (posedge clk) begin
    if (rst) begin
        valid <= 1'b0;
    end
    else if (rdy) begin
        if (rdy_i && !rw_i && addr_i[17:16] != 2'b11) begin
            if (width_i == 3'h4) begin
                tag[addr_i[10:2]] <= addr_i[31:11];
                cache[addr_i[10:2]] <= data_i;
                valid[addr_i[10:2]] <= 1'b1;
            end
            else begin
                valid[addr_i[10:2]] <= 1'b0;
            end
        end
        else if (rdy_i && rw_i && addr_i[17:16] != 2'b11) begin
            tag[addr_i[10:2]] <= addr_i[31:11];
            cache[addr_i[10:2]] <= data_rc_i;
            valid[addr_i[10:2]] <= 1'b1;
        end
    end
end

always @ (*) begin
    if (rst || !en_i) begin
        rdy_o = 1'b0;
        data_o = 32'b0;
        en_o = 1'b0;
        rw_o = 1'b0;
        width_o = 1'b0;
        addr_rc_o = 32'b0;
        data_rc_o = 32'b0;
    end
    else if (rdy_i && !rw_i) begin
        rdy_o = 1'b1;
        data_o = 32'b0;
        en_o = 1'b0;
        rw_o = 1'b0;
        width_o = 1'b0;
        addr_rc_o = 32'b0;
        data_rc_o = 32'b0;
    end
    else if (rdy_i && rw_i) begin
        rdy_o = 1'b1;
        if (addr_i[17:16] == 2'b11) begin
            data_o = data_rc_i;
        end
        else begin
            case (width_i)
                3'h1: begin
                    case (addr_i[1:0])
                        2'b00:
                            data_o = {24'b0, data_rc_i[7:0]};
                        2'b01:
                            data_o = {24'b0, data_rc_i[15:8]};
                        2'b10:
                            data_o = {24'b0, data_rc_i[23:16]};
                        2'b11:
                            data_o = {24'b0, data_rc_i[31:24]};
                        default:
                            data_o = 32'b0;
                    endcase
                end
                3'h2: begin
                    case (addr_i[1:0])
                        2'b00:
                            data_o = {16'b0, data_rc_i[15:0]};
                        2'b01:
                            data_o = {16'b0, data_rc_i[23:8]};
                        2'b10:
                            data_o = {16'b0, data_rc_i[31:16]};
                        default: 
                            data_o = 32'b0;
                    endcase
                end
                3'h4: begin
                    data_o = data_rc_i;
                end
                default: 
                    data_o = 32'b0;
            endcase
        end
        en_o = 1'b0;
        rw_o = 1'b0;
        width_o = 1'b0;
        addr_rc_o = 32'b0;
        data_rc_o = 32'b0;
    end
    else if (!rw_i) begin
        rdy_o = 1'b0;
        data_o = 32'b0;
        en_o = 1'b1;
        rw_o = 1'b0;
        addr_rc_o = addr_i;
        data_rc_o = data_i;
        width_o = width_i;
    end
    else begin
        rdy_o = 1'b0;
        data_o = 32'b0;
        en_o = 1'b0;
        rw_o = 1'b1;
        width_o = 1'b0;
        addr_rc_o = 32'b0;
        data_rc_o = 32'b0;
        if (valid[addr_i[10:2]] && tag[addr_i[10:2]] == addr_i[31:11]) begin
            rdy_o = 1'b1;
            case (width_i)
                3'h1: begin
                    case (addr_i[1:0])
                        2'b00:
                            data_o = {24'b0, cache[addr_i[10:2]][7:0]};
                        2'b01:
                            data_o = {24'b0, cache[addr_i[10:2]][15:8]};
                        2'b10:
                            data_o = {24'b0, cache[addr_i[10:2]][23:16]};
                        2'b11:
                            data_o = {24'b0, cache[addr_i[10:2]][31:24]};
                        default:
                            data_o = 32'b0;
                    endcase
                end
                3'h2: begin
                    case (addr_i[1:0])
                        2'b00:
                            data_o = {16'b0, cache[addr_i[10:2]][15:0]};
                        2'b01:
                            data_o = {16'b0, cache[addr_i[10:2]][23:8]};
                        2'b10:
                            data_o = {16'b0, cache[addr_i[10:2]][31:16]};
                        default: 
                            data_o = 32'b0;
                    endcase
                end
                3'h4: begin
                    data_o = cache[addr_i[10:2]];
                end
                default: 
                    data_o = 32'b0;
            endcase
        end
        else begin
            en_o = 1'b1;
            if (addr_i[17:16] == 2'b11) begin
                width_o = width_i;
                addr_rc_o = addr_i;
            end
            else begin
                width_o = 3'h4;
                addr_rc_o = {addr_i[31:2], 2'b0};
            end
        end
    end
end

endmodule // datacache
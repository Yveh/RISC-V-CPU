module datacache(
    input wire clk,
    input wire rst,
    input wire rdy,

    input wire en_i,
    input wire rw_i,
    input wire[31:0] addr_i,
    input wire[31:0] data_i,
    input wire[2:0] width_i,
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


reg[7:0] cache[1023:0];
reg[21:0] tag[1023:0];
reg valid[1023:0];

always @ (posedge clk) begin
    if (rst) begin
        for (integer i = 0; i < 1024; i = i + 1)
            valid[i] <= 1'b0;
    end
    else if (rdy) begin
        if (rdy_i && !rw_i) begin
            case (width_i)
                3'h1: begin
                    tag[addr_i[9:0]] <= addr_i[31:10];
                    cache[addr_i[9:0]] <= data_i[7:0];
                    valid[addr_i[9:0]] <= 1'b1;
                end 
                3'h2: begin
                    tag[addr_i[9:0]] <= addr_i[31:10];
                    tag[addr_i[9:0] + 3'h1] <= {{10'b0, addr_i} + 3'h1} >> 10;
                    cache[addr_i[9:0]] <= data_i[7:0];
                    cache[addr_i[9:0] + 3'h1] <= data_i[15:8];
                    valid[addr_i[9:0]] <= 1'b1;
                    valid[addr_i[9:0] + 3'h1] <= 1'b1;
                end
                3'h4: begin
                    tag[addr_i[9:0]] <= addr_i[31:10];
                    tag[addr_i[9:0] + 3'h1] <= {{10'b0, addr_i} + 3'h1} >> 10;
                    tag[addr_i[9:0] + 3'h2] <= {{10'b0, addr_i} + 3'h2} >> 10;
                    tag[addr_i[9:0] + 3'h3] <= {{10'b0, addr_i} + 3'h3} >> 10;
                    cache[addr_i[9:0]] <= data_i[7:0];
                    cache[addr_i[9:0] + 3'h1] <= data_i[15:8];
                    cache[addr_i[9:0] + 3'h2] <= data_i[23:16];
                    cache[addr_i[9:0] + 3'h3] <= data_i[31:24];
                    valid[addr_i[9:0]] <= 1'b1;
                    valid[addr_i[9:0] + 3'h1] <= 1'b1;
                    valid[addr_i[9:0] + 3'h2] <= 1'b1;
                    valid[addr_i[9:0] + 3'h3] <= 1'b1;
                end
                default: ;
            endcase
        end
        else if (rdy_i && rw_i) begin
            case (width_i)
                3'h1: begin
                    tag[addr_i[9:0]] <= addr_i[31:10];
                    cache[addr_i[9:0]] <= data_rc_i[7:0];
                    valid[addr_i[9:0]] <= 1'b1;
                end 
                3'h2: begin
                    tag[addr_i[9:0]] <= addr_i[31:10];
                    tag[addr_i[9:0] + 3'h1] <= {{10'b0, addr_i} + 3'h1} >> 10;
                    cache[addr_i[9:0]] <= data_rc_i[7:0];
                    cache[addr_i[9:0] + 3'h1] <= data_rc_i[15:8];
                    valid[addr_i[9:0]] <= 1'b1;
                    valid[addr_i[9:0] + 3'h1] <= 1'b1;
                end
                3'h4: begin
                    tag[addr_i[9:0]] <= addr_i[31:10];
                    tag[addr_i[9:0] + 3'h1] <= {{10'b0, addr_i} + 3'h1} >> 10;
                    tag[addr_i[9:0] + 3'h2] <= {{10'b0, addr_i} + 3'h2} >> 10;
                    tag[addr_i[9:0] + 3'h3] <= {{10'b0, addr_i} + 3'h3} >> 10;
                    cache[addr_i[9:0]] <= data_rc_i[7:0];
                    cache[addr_i[9:0] + 3'h1] <= data_rc_i[15:8];
                    cache[addr_i[9:0] + 3'h2] <= data_rc_i[23:16];
                    cache[addr_i[9:0] + 3'h3] <= data_rc_i[31:24];
                    valid[addr_i[9:0]] <= 1'b1;
                    valid[addr_i[9:0] + 3'h1] <= 1'b1;
                    valid[addr_i[9:0] + 3'h2] <= 1'b1;
                    valid[addr_i[9:0] + 3'h3] <= 1'b1;
                end
                default: ;
            endcase
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
        data_o = data_rc_i;
        en_o = 1'b0;
        rw_o = 1'b0;
        width_o = 1'b0;
        addr_rc_o = 32'b0;
        data_rc_o = 32'b0;
    end
    else if (rw_i) begin
        rdy_o = 1'b0;
        data_o = 32'b0;
        en_o = 1'b0;
        rw_o = 1'b1;
        width_o = width_i;
        addr_rc_o = 32'b0;
        data_rc_o = 32'b0;
        case (width_i)
            3'h1: begin
                if (valid[addr_i[9:0]] && tag[addr_i[9:0]] == addr_i[31:10]) begin
                    rdy_o = 1'b1;
                    data_o = {24'b0, cache[addr_i[9:0]]};
                end
                else begin
                    en_o = 1'b1;
                    addr_rc_o = addr_i;
                end
            end
            3'h2: begin
                if (valid[addr_i[9:0]] && tag[addr_i[9:0]] == addr_i[31:10] &&
                    valid[addr_i[9:0] + 3'h1] && tag[addr_i[9:0] + 3'h1] == {{10'b0, addr_i} + 3'h1} >> 10) begin
                    rdy_o = 1'b1;
                    data_o = {16'b0, cache[addr_i[9:0] + 3'h1], cache[addr_i[9:0]]};
                end
                else begin
                    en_o = 1'b1;
                    addr_rc_o = addr_i;
                end
            end
            3'h4: begin
                if (valid[addr_i[9:0]] && tag[addr_i[9:0]] == addr_i[31:10] &&
                    valid[addr_i[9:0] + 3'h1] && tag[addr_i[9:0] + 3'h1] == {{10'b0, addr_i} + 3'h1} >> 10 &&
                    valid[addr_i[9:0] + 3'h2] && tag[addr_i[9:0] + 3'h2] == {{10'b0, addr_i} + 3'h2} >> 10 &&
                    valid[addr_i[9:0] + 3'h3] && tag[addr_i[9:0] + 3'h3] == {{10'b0, addr_i} + 3'h3} >> 10) begin
                    rdy_o = 1'b1;
                    data_o = {cache[addr_i[9:0] + 3'h3], cache[addr_i[9:0] + 3'h2], cache[addr_i[9:0] + 3'h1], cache[addr_i[9:0]]};
                end
                else begin
                    en_o = 1'b1;
                    addr_rc_o = addr_i;
                end
            end
            default: ;
        endcase
    end
    else begin
        // rdy_o = 1'b0;
        // data_o = 32'b0;
        // en_o = 1'b1;
        // rw_o = 1'b0;
        // width_o = width_i;
        // addr_rc_o = addr_i;
        // data_rc_o = data_i;
    end
end

endmodule // datacache
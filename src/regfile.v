module regfile(
    input wire rst,
    input wire rst_c,
    input wire clk,
    input wire rdy,

    //to ID
    input wire se,
    input wire[4:0] saddr,
    input wire[4:0] sid,

    //to ROB
    input wire we,
    input wire[4:0] waddr,
    input wire[4:0] wid,
    input wire[31:0] wdata,

    //to ID
    input wire re1,
    input wire[4:0] raddr1,
    input wire re2,
    input wire[4:0] raddr2,
    output reg[31:0] rdata1,
    output reg[4:0] rid1,
    output reg rrdy1,
    output reg[31:0] rdata2,
    output reg[4:0] rid2,
    output reg rrdy2
);

reg[31:0] regs[31:0];
reg[4:0] rid[31:0];
reg rdytag[31:0];

always @ (posedge clk or negedge rst) begin
    if (rst) begin
        for (integer i = 0; i < 32; i = i + 1) begin
            regs[i] <= 1'b0;
            rdytag[i] <= 1'b1;
        end
    end
    else if (rdy) begin
        if (we && waddr != 1'b0)
            regs[waddr] <= wdata;
        if (se)
            rid[saddr] <= sid;

        if (rst_c) begin
            for (integer i = 0; i < 32; i = i + 1)
                rdytag[i] <= 1'b1;
        end
        else if (se && we && waddr == saddr) begin
            rdytag[saddr] <= 1'b0;
        end
        else begin
            if (we && rid[waddr] == wid)
                rdytag[waddr] <= 1'b1;
            if (se)
                rdytag[saddr] <= 1'b0;
        end
    end
end

always @ (*) begin
    if (rst || rst_c) begin
        rdata1 = 32'b0;
        rrdy1 = 1'b0;
        rid1 = 5'b0;
    end
    else if (!re1) begin
        rdata1 = 32'b0;
        rrdy1 = 1'b0;
        rid1 = 5'b0;
    end
    else if (raddr1 == 5'h0) begin
        rdata1 = 32'h0;
        rrdy1 = 1'b1;
        rid1 = 5'b0;
    end
    else if (we && raddr1 == waddr && wid == rid[waddr]) begin
        rdata1 = wdata;
        rrdy1 = 1'b1;
        rid1 = 5'b0;
    end
    else begin
        rdata1 = regs[raddr1];
        rrdy1 = rdytag[raddr1];
        rid1 = rid[raddr1];
    end
end

always @ (*) begin
    if (rst || rst_c) begin
        rdata2 = 32'b0; 
        rrdy2 = 1'b0;
        rid2 = 5'b0;
    end
    else if (!re2) begin
        rdata2 = 32'b0; 
        rrdy2 = 1'b0;
        rid2 = 5'b0;
    end
    else if (raddr2 == 5'h0) begin
        rdata2 = 32'h0; 
        rrdy2 = 1'b1;
        rid2 = 5'b0;
    end
    else if (we && raddr2 == waddr && wid == rid[waddr]) begin
        rdata2 = wdata; 
        rrdy2 = 1'b1;
        rid2 = 5'b0;
    end
    else begin
        rdata2 = regs[raddr2];
        rrdy2 = rdytag[raddr2];
        rid2 = rid[raddr2];
    end
end

endmodule // regfile
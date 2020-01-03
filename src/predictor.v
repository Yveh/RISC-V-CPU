module predictor(
    input wire rst,
    input wire clk,
    input wire rdy,
    input wire[31:0] addr,
    input wire en,
    input wire res,
    input wire[31:0] uaddr,
    output wire taken
);

reg[2:0] btb[511:0];

assign taken = (btb[addr[10:2]] >= 2'b10) ? 1'b1 : 1'b0;

integer i;

always @ (posedge clk) begin
    if (rst) begin
        for (i = 0; i < 512; i = i + 1) begin
            btb[i] <= 2'b00;
        end
    end
    else if (rdy && en) begin
        if (res)
            btb[uaddr[10:2]] <= btb[uaddr[10:2]] == 2'b11 ? 2'b11 : btb[uaddr[10:2]] + 1'b1;
        else
            btb[uaddr[10:2]] <= btb[uaddr[10:2]] == 2'b00 ? 2'b00 : btb[uaddr[10:2]] - 1'b1;
    end
end

endmodule // predictor
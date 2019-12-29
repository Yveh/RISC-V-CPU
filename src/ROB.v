module ROB(
    input wire clk,
    input wire rst,
    input wire rst_c,
    input wire rdy,

    output reg full_o,
    output reg empty_o,
    /*push or pop*/
    //to id
    input wire add_en_i,
    input wire[4:0] add_regaddr_i,
    input wire[1:0] add_branch_tag_i,
    output reg[4:0] add_id,
    //to commit
    input wire commit_rdy_i,
    output reg commit_en_o,
    output reg[4:0] commit_id_o,
    output reg[4:0] commit_regaddr_o,
    output reg[31:0] commit_data_o,
    output reg[31:0] commit_pc_o,
    output reg[1:0] commit_branch_tag_o,
    output reg commit_cond_o,
    /*update*/
    //to cdb
    input wire cdb1_en_i,
    input wire[4:0] cdb1_id_ROB_i,
    input wire[31:0] cdb1_data_i,
    input wire[31:0] cdb1_pc_i,
    input wire cdb1_cond_i,

    input wire cdb2_en_i,
    input wire[4:0] cdb2_id_ROB_i,
    input wire[31:0] cdb2_data_i,
    input wire[31:0] cdb2_pc_i,
    input wire cdb2_cond_i,

    input wire cdb3_en_i,
    input wire[4:0] cdb3_id_ROB_i,
    input wire[31:0] cdb3_data_i,
    //to id
    input wire re1_i,
    input wire re2_i,
    input wire[4:0] rid1_i,
    input wire[4:0] rid2_i,
    output reg rrdy1_o,
    output reg rrdy2_o,
    output reg[31:0] rdata1_o,
    output reg[31:0] rdata2_o
);

parameter cap = 5'h1f;

reg[31:0] data[31:0], pc[31:0];
reg cond[31:0];
reg[4:0] regaddr[31:0];
reg[1:0] branch_tag[31:0];
reg rdytag[31:0];

reg[4:0] head, tail;

always @ (posedge clk) begin
    if (rst || rst_c) begin
        for (integer i = 0; i < 32; i = i + 1)
            rdytag[i] = 1'b0;
        head <= 5'h0;
        tail <= 5'h0;
        full_o <= 1'b0;
        empty_o <= 1'b1;
        commit_en_o <= 1'b0;
        add_id <= 5'b0;
    end
    else if (rdy) begin
        if (add_en_i) begin
            regaddr[tail] <= add_regaddr_i;
            rdytag[tail] <= 1'b0;
            branch_tag[tail] <= add_branch_tag_i;
        end
        if (cdb1_en_i) begin
            rdytag[cdb1_id_ROB_i] <= 1'b1;
            data[cdb1_id_ROB_i] <= cdb1_data_i;
            cond[cdb1_id_ROB_i] <= cdb1_cond_i;
            pc[cdb1_id_ROB_i] <= cdb1_pc_i;
        end
        if (cdb2_en_i) begin
            rdytag[cdb2_id_ROB_i] <= 1'b1;
            data[cdb2_id_ROB_i] <= cdb2_data_i;
            cond[cdb2_id_ROB_i] <= cdb2_cond_i;
            pc[cdb2_id_ROB_i] <= cdb2_pc_i;
        end
        if (cdb3_en_i) begin
            rdytag[cdb3_id_ROB_i] <= 1'b1;
            data[cdb3_id_ROB_i] <= cdb3_data_i;
        end
        add_id <= tail + add_en_i;
        head <= head + commit_rdy_i;
        tail <= tail + add_en_i;
        full_o <= (tail - head + add_en_i - commit_rdy_i == cap) ? 1'b1 : 1'b0;
        empty_o <= (tail - head + add_en_i - commit_rdy_i == 1'b0) ? 1'b1 : 1'b0;

        if ((tail - head - commit_rdy_i != 1'b0) && 
            rdytag[head + commit_rdy_i]) begin
            commit_en_o <= 1'b1;
            commit_data_o <= data[head + commit_rdy_i];
            commit_id_o <= head + commit_rdy_i;
            commit_regaddr_o <= regaddr[head + commit_rdy_i];
            commit_pc_o <= pc[head + commit_rdy_i];
            commit_branch_tag_o <= branch_tag[head + commit_rdy_i];
            commit_cond_o <= cond[head + commit_rdy_i];
        end
        else begin
            commit_en_o <= 1'b0;
        end 
    end 
end

always @ (*) begin
    if (rst || rst_c) begin
        rrdy1_o = 1'b0;
        rdata1_o = 32'bx; 
    end
    else if (!re1_i) begin
        rrdy1_o = 1'b0;
        rdata1_o = 32'bx; 
    end
    else if (cdb1_en_i && rid1_i == cdb1_id_ROB_i) begin
        rrdy1_o = 1'b1;
        rdata1_o = cdb1_data_i;
    end
    else if (cdb2_en_i && rid1_i == cdb2_id_ROB_i) begin
        rrdy1_o = 1'b1;
        rdata1_o = cdb2_data_i;
    end
    else if (cdb3_en_i && rid1_i == cdb3_id_ROB_i) begin
        rrdy1_o = 1'b1;
        rdata1_o = cdb3_data_i;
    end
    else if (rdytag[rid1_i]) begin
        rrdy1_o = 1'b1;
        rdata1_o = data[rid1_i];
    end
    else begin
        rrdy1_o = 1'b0;
        rdata1_o = 32'bx;
    end
end

always @ (*) begin
    if (rst || rst_c) begin
        rrdy2_o = 1'b0;
        rdata2_o = 32'bx; 
    end
    else if (!re2_i) begin
        rrdy2_o = 1'b0;
        rdata2_o = 32'bx; 
    end
    else if (cdb1_en_i && rid2_i == cdb1_id_ROB_i) begin
        rrdy2_o = 1'b1;
        rdata2_o = cdb1_data_i; 
    end
    else if (cdb2_en_i && rid2_i == cdb2_id_ROB_i) begin
        rrdy2_o = 1'b1;
        rdata2_o = cdb2_data_i; 
    end
    else if (cdb3_en_i && rid2_i == cdb3_id_ROB_i) begin
        rrdy2_o = 1'b1;
        rdata2_o = cdb3_data_i; 
    end
    else if (rdytag[rid2_i]) begin
        rrdy2_o = 1'b1;
        rdata2_o = data[rid2_i];
    end
    else begin
        rrdy2_o = 1'b0;
        rdata2_o = 32'bx;
    end
end


endmodule // ROB
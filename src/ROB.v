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
    input wire add_rdytag_i,
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
    output reg[31:0] rdata2_o,

    output reg en_SL_o
);

parameter cap = 5'h1e;

reg[31:0] data[31:0], pc[31:0];
reg cond[31:0];
reg[4:0] regaddr[31:0];
reg[1:0] branch_tag[31:0];
reg rdytag[31:0];

reg[31:0] head, tail, before;

wire full, empty;
wire[4:0] head_p, before_p, tail_p;

assign full = (tail + add_en_i - head - commit_rdy_i >= cap) ? 1'b1 : 1'b0;
assign empty = (tail + add_en_i - head - commit_rdy_i == 1'b0) ? 1'b1 : 1'b0;
assign head_p = head[4:0] + commit_rdy_i;
assign before_p = before[4:0];
assign tail_p = tail[4:0];

always @ (posedge clk) begin
    if (rst || rst_c) begin
        head <= 1'b0;
        tail <= 1'b0;
        before <= 1'b0;
        full_o <= 1'b0;
        empty_o <= 1'b1;
        commit_en_o <= 1'b0;
        add_id <= 5'b0;
        en_SL_o <= 1'b0;
    end
    else if (rdy) begin
        if (add_en_i) begin
            regaddr[tail_p] <= add_regaddr_i;
            rdytag[tail_p] <= add_rdytag_i;
            branch_tag[tail_p] <= add_branch_tag_i;
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
        add_id <= tail_p + add_en_i;
        head <= head + commit_rdy_i;
        tail <= tail + add_en_i;
        full_o <= full;
        empty_o <= empty;

        if (before < tail) begin
            if (head + commit_rdy_i > before)
                before <= head + commit_rdy_i;
            else
                before <= before + ((branch_tag[before_p] == 2'b11 || branch_tag[before_p] == 2'b00) ? 1'b1 : 1'b0);
            en_SL_o <= branch_tag[before_p] == 2'b11 ? 1'b1 : 1'b0;
        end
        else begin
            en_SL_o <= 1'b0;
        end

        if ((tail_p != head_p) && rdytag[head_p]) begin
            commit_en_o <= 1'b1;
            commit_data_o <= data[head_p];
            commit_id_o <= head_p;
            commit_regaddr_o <= regaddr[head_p];
            commit_pc_o <= pc[head_p];
            commit_branch_tag_o <= branch_tag[head_p];
            commit_cond_o <= cond[head_p];
        end
        else begin
            commit_en_o <= 1'b0;
        end 
    end 
end

always @ (*) begin
    if (rst || rst_c) begin
        rrdy1_o = 1'b0;
        rdata1_o = 32'b0; 
    end
    else if (!re1_i) begin
        rrdy1_o = 1'b0;
        rdata1_o = 32'b0; 
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
        rdata1_o = 32'b0;
    end
end

always @ (*) begin
    if (rst || rst_c) begin
        rrdy2_o = 1'b0;
        rdata2_o = 32'b0; 
    end
    else if (!re2_i) begin
        rrdy2_o = 1'b0;
        rdata2_o = 32'b0; 
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
        rdata2_o = 32'b0;
    end
end


endmodule // ROB
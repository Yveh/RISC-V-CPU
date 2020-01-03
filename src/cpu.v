// RISCV32I CPU top module
// port modification allowed for debugging purposes

module cpu(
    input  wire                 clk_in,			// system clock signal
    input  wire                 rst_in,			// reset signal
	  input  wire					        rdy_in,			// ready signal, pause cpu when low

    input  wire [ 7:0]          mem_din,		// data input bus
    output wire [ 7:0]          mem_dout,		// data output bus
    output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
    output wire                 mem_wr,			// write/read signal (1 for write)

	  output wire [31:0]			dbgreg_dout		// cpu register output (debugging demo)
);

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read takes 2 cycles(wait till next cycle), write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)

wire rst_c;

wire IF_rdy_cache_i, IF_full_queue_i, IF_en_i;
wire[31:0] IF_inst_cache_i;
wire[31:0] IF_pc_i;

wire instqueue_we_i, instqueue_re_i;
wire[31:0] instqueue_inst_i, instqueue_pc_i;
wire instcache_en_i, instcache_rdy_i;
wire[31:0] instcache_addr_i, instcache_inst_i;

wire datacache_en_i, datacache_rw_i;
wire[31:0] datacache_addr_i, datacache_data_i;
wire[2:0] datacache_width_i;
wire datacache_rrdy_i, datacache_rdy_i;
wire[31:0] datacache_data_rc_i;

wire rc_inst_en_i;
wire[31:0] rc_inst_addr_i;
wire[7:0] rc_ram_i;
wire rc_data_en_i, rc_data_rw_i;
wire[31:0] rc_data_addr_i, rc_data_data_i;
wire[2:0] rc_data_width_i;

wire ram_r_nw_i;
wire[7:0] ram_d_i;
wire[16:0] ram_a_i;

wire ID_empty_queue_i, ID_full_ROB_i;
wire[31:0] ID_inst_queue_i, ID_pc_queue_i;
wire[4:0] ID_add_id_ROB_i;
wire ID_busy1_i, ID_busy2_i, ID_busySL_i;

wire[2:0] fetch_RS_id_i;
wire[31:0] fetch_Imm_i, fetch_pc_i;
wire[6:0] fetch_OP_i, fetch_Funct7_i;
wire[2:0] fetch_Funct3_i;
wire[4:0] fetch_ROB_id_i, fetch_A_addr_i, fetch_B_addr_i;
wire fetch_data1_rdy_regfile_i, fetch_data2_rdy_regfile_i;
wire[31:0] fetch_data1_regfile_i, fetch_data2_regfile_i;
wire[4:0] fetch_data1_rid_regfile_i, fetch_data2_rid_regfile_i;
wire fetch_data1_rdy_ROB_i, fetch_data2_rdy_ROB_i;
wire[31:0] fetch_data1_ROB_i, fetch_data2_ROB_i;

wire RS1_en_i, RS1_A_rdy_i, RS1_B_rdy_i;
wire[31:0] RS1_A_i, RS1_B_i, RS1_Imm_i, RS1_pc_i;
wire[4:0] RS1_A_id_i, RS1_B_id_i, RS1_ROB_id_i;
wire[6:0] RS1_OP_i, RS1_Funct7_i;
wire[2:0] RS1_Funct3_i;

wire RS2_en_i, RS2_A_rdy_i, RS2_B_rdy_i;
wire[31:0] RS2_A_i, RS2_B_i, RS2_Imm_i, RS2_pc_i;
wire[4:0] RS2_A_id_i, RS2_B_id_i, RS2_ROB_id_i;
wire[6:0] RS2_OP_i, RS2_Funct7_i;
wire[2:0] RS2_Funct3_i;

wire RS3_en_i, RS3_A_rdy_i, RS3_B_rdy_i;
wire[31:0] RS3_A_i, RS3_B_i, RS3_Imm_i;
wire[4:0] RS3_A_id_i, RS3_B_id_i, RS3_ROB_id_i;
wire[6:0] RS3_OP_i;
wire[2:0] RS3_Funct3_i;
wire RS3_full_SLB_i;

wire EX1_en_i;
wire[31:0] EX1_A_i, EX1_B_i, EX1_Imm_i, EX1_pc_i;
wire[6:0] EX1_OP_i, EX1_Funct7_i;
wire[2:0] EX1_Funct3_i;
wire[4:0] EX1_ROB_id_i;

wire EX2_en_i;
wire[31:0] EX2_A_i, EX2_B_i, EX2_Imm_i, EX2_pc_i;
wire[6:0] EX2_OP_i, EX2_Funct7_i;
wire[2:0] EX2_Funct3_i;
wire[4:0] EX2_ROB_id_i;

wire regfile_re1, regfile_re2, regfile_se_i, regfile_we_i;
wire[4:0] regfile_raddr1_i, regfile_raddr2_i;
wire[4:0] regfile_saddr_i, regfile_sid_i;
wire[4:0] regfile_waddr_i, regfile_wid_i;
wire[31:0] regfile_wdata_i; 

wire ROB_add_en_i, ROB_re1_i, ROB_re2_i;
wire ROB_commit_rdy_i, ROB_add_rdytag_i;
wire[4:0] ROB_add_regaddr_i, ROB_rid1_i, ROB_rid2_i;
wire[1:0] ROB_branch_tag_i;

wire commit_en_i;
wire[4:0] commit_regaddr_i, commit_id_i;
wire[31:0] commit_data_i, commit_pc_i;
wire[1:0] commit_branch_tag_i;
wire commit_cond_i;

wire SLB_en_i, SLB_add_en_i, SLB_rdy_i, SLB_en_SL_i;
wire[31:0] SLB_A_i, SLB_B_i, SLB_Imm_i, SLB_data_i;
wire[6:0] SLB_OP_i;
wire[2:0] SLB_Funct3_i;
wire[4:0] SLB_ROB_id_i, SLB_LS_id_i;
wire[1:0] SLB_branch_tag_i;

wire cdb1_en, cdb2_en, cdb3_en;
wire[4:0] cdb1_id_ROB, cdb2_id_ROB, cdb3_id_ROB;
wire[31:0] cdb1_data, cdb2_data, cdb3_data;
wire[31:0] cdb1_pc, cdb2_pc;
wire cdb1_cond, cdb2_cond;

IF IF0(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    .rdy_cache_i(IF_rdy_cache_i),
    .inst_cache_i(IF_inst_cache_i),
    .en_cache_o(instcache_en_i),
    .addr_cache_o(instcache_addr_i),

    .en_i(IF_en_i),
    .pc_i(IF_pc_i),

    .full_queue_i(IF_full_queue_i),
    .we_queue_o(instqueue_we_i),
    .inst_queue_o(instqueue_inst_i),
    .pc_queue_o(instqueue_pc_i)
);

instqueue instqueue0(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    .rst_c(rst_c),
    .we_i(instqueue_we_i),
    .inst_i(instqueue_inst_i),
    .pc_i(instqueue_pc_i),
    .re_i(instqueue_re_i),
    .inst_o(ID_inst_queue_i),
    .pc_o(ID_pc_queue_i),
    .full_o(IF_full_queue_i),
    .empty_o(ID_empty_queue_i)
);

ID ID0(
    .clk(clk_in),
    .rst(rst_in),
    //to instqueue
    .inst_queue_i(ID_inst_queue_i),
    .pc_queue_i(ID_pc_queue_i),
    .inst_empty_queue_i(ID_empty_queue_i),
    .re_queue_o(instqueue_re_i),
    //to ROB
    .add_full_ROB_i(ID_full_ROB_i),
    .add_id_ROB_i(ID_add_id_ROB_i),
    .add_en_ROB_o(ROB_add_en_i),
    .add_rdytag_o(ROB_add_rdytag_i),
    .add_branch_tag_ROB_o(ROB_branch_tag_i),
    .add_regaddr_ROB_o(ROB_add_regaddr_i),
    //to regfile
    .wait_en_regfile_o(regfile_se_i),
    .wait_regaddr_regfile_o(regfile_saddr_i),
    .wait_id_regfile_o(regfile_sid_i),
    //to EX
    .busySL_i(ID_busySL_i),
    .busy1_i(ID_busy1_i),
    .busy2_i(ID_busy2_i),
    .RS_id_o(fetch_RS_id_i),
    .Imm_o(fetch_Imm_i),
    .OP_o(fetch_OP_i),
    .Funct7_o(fetch_Funct7_i),
    .Funct3_o(fetch_Funct3_i),
    .ROB_id_o(fetch_ROB_id_i),
    .pc_o(fetch_pc_i),
    .A_addr_o(fetch_A_addr_i),
    .B_addr_o(fetch_B_addr_i)
);

fetch fetch0(
    .clk(clk_in),
    .rst(rst_in),
    .RS_id_i(fetch_RS_id_i),
    .Imm_i(fetch_Imm_i),
    .OP_i(fetch_OP_i),
    .Funct7_i(fetch_Funct7_i),
    .Funct3_i(fetch_Funct3_i),
    .pc_i(fetch_pc_i),
    .ROB_id_i(fetch_ROB_id_i),
    .A_addr_i(fetch_A_addr_i),
    .B_addr_i(fetch_B_addr_i),
    
    .data1_rdy_regfile_i(fetch_data1_rdy_regfile_i),
    .data2_rdy_regfile_i(fetch_data2_rdy_regfile_i),
    .data1_regfile_i(fetch_data1_regfile_i),
    .data2_regfile_i(fetch_data2_regfile_i),
    .data1_rid_regfile_i(fetch_data1_rid_regfile_i),
    .data2_rid_regfile_i(fetch_data2_rid_regfile_i),
    .re1_regfile_o(regfile_re1_i),
    .re2_regfile_o(regfile_re2_i),
    .addr1_regfile_o(regfile_raddr1_i),
    .addr2_regfile_o(regfile_raddr2_i),

    .data1_rdy_ROB_i(fetch_data1_rdy_ROB_i),
    .data2_rdy_ROB_i(fetch_data2_rdy_ROB_i),
    .data1_ROB_i(fetch_data1_ROB_i),
    .data2_ROB_i(fetch_data2_ROB_i),
    .re1_ROB_o(ROB_re1_i),
    .re2_ROB_o(ROB_re2_i),
    .rid1_ROB_o(ROB_rid1_i),
    .rid2_ROB_o(ROB_rid2_i),
    
    .RS1_en_o(RS1_en_i),
    .A_RS1_o(RS1_A_i),
    .B_RS1_o(RS1_B_i),
    .A_rdy_RS1_o(RS1_A_rdy_i),
    .B_rdy_RS1_o(RS1_B_rdy_i),
    .A_id_RS1_o(RS1_A_id_i),
    .B_id_RS1_o(RS1_B_id_i),
    .Imm_RS1_o(RS1_Imm_i),
    .OP_RS1_o(RS1_OP_i),
    .Funct7_RS1_o(RS1_Funct7_i),
    .Funct3_RS1_o(RS1_Funct3_i),
    .pc_RS1_o(RS1_pc_i),
    .ROB_id_RS1_o(RS1_ROB_id_i),

    .RS2_en_o(RS2_en_i),
    .A_RS2_o(RS2_A_i),
    .B_RS2_o(RS2_B_i),
    .A_rdy_RS2_o(RS2_A_rdy_i),
    .B_rdy_RS2_o(RS2_B_rdy_i),
    .A_id_RS2_o(RS2_A_id_i),
    .B_id_RS2_o(RS2_B_id_i),
    .Imm_RS2_o(RS2_Imm_i),
    .OP_RS2_o(RS2_OP_i),
    .Funct7_RS2_o(RS2_Funct7_i),
    .Funct3_RS2_o(RS2_Funct3_i),
    .pc_RS2_o(RS2_pc_i),
    .ROB_id_RS2_o(RS2_ROB_id_i),

    .RS3_en_o(RS3_en_i),
    .A_RS3_o(RS3_A_i),
    .B_RS3_o(RS3_B_i),
    .A_rdy_RS3_o(RS3_A_rdy_i),
    .B_rdy_RS3_o(RS3_B_rdy_i),
    .A_id_RS3_o(RS3_A_id_i),
    .B_id_RS3_o(RS3_B_id_i),
    .Imm_RS3_o(RS3_Imm_i),
    .OP_RS3_o(RS3_OP_i),
    .Funct3_RS3_o(RS3_Funct3_i),
    .ROB_id_RS3_o(RS3_ROB_id_i)
);

RS RS1(
    .clk(clk_in),
    .rst(rst_in),
    .rst_c(rst_c),
    .rdy(rdy_in),

    .en_i(RS1_en_i),
    .A_i(RS1_A_i),
    .B_i(RS1_B_i),
    .A_rdy_i(RS1_A_rdy_i),
    .B_rdy_i(RS1_B_rdy_i),
    .A_id_i(RS1_A_id_i),
    .B_id_i(RS1_B_id_i),
    .pc_i(RS1_pc_i),
    .Imm_i(RS1_Imm_i),
    .OP_i(RS1_OP_i),
    .Funct7_i(RS1_Funct7_i),
    .Funct3_i(RS1_Funct3_i),
    .ROB_id_i(RS1_ROB_id_i),
    .busy(ID_busy1_i),

    .cdb1_en_i(cdb1_en),
    .cdb1_id_ROB_i(cdb1_id_ROB),
    .cdb1_data_i(cdb1_data),

    .cdb2_en_i(cdb2_en),
    .cdb2_id_ROB_i(cdb2_id_ROB),
    .cdb2_data_i(cdb2_data),

    .cdb3_en_i(cdb3_en),
    .cdb3_id_ROB_i(cdb3_id_ROB),
    .cdb3_data_i(cdb3_data),

    .A_o(EX1_A_i),
    .B_o(EX1_B_i),
    .Imm_o(EX1_Imm_i),
    .pc_o(EX1_pc_i),
    .OP_o(EX1_OP_i),
    .Funct7_o(EX1_Funct7_i),
    .Funct3_o(EX1_Funct3_i),
    .ROB_id_o(EX1_ROB_id_i),
    .en_EX_o(EX1_en_i)
);

RS RS2(
    .clk(clk_in),
    .rst(rst_in),
    .rst_c(rst_c),
    .rdy(rdy_in),

    .en_i(RS2_en_i),
    .A_i(RS2_A_i),
    .B_i(RS2_B_i),
    .A_rdy_i(RS2_A_rdy_i),
    .B_rdy_i(RS2_B_rdy_i),
    .A_id_i(RS2_A_id_i),
    .B_id_i(RS2_B_id_i),
    .pc_i(RS2_pc_i),
    .Imm_i(RS2_Imm_i),
    .OP_i(RS2_OP_i),
    .Funct7_i(RS2_Funct7_i),
    .Funct3_i(RS2_Funct3_i),
    .ROB_id_i(RS2_ROB_id_i),
    .busy(ID_busy2_i),

    .cdb1_en_i(cdb1_en),
    .cdb1_id_ROB_i(cdb1_id_ROB),
    .cdb1_data_i(cdb1_data),

    .cdb2_en_i(cdb2_en),
    .cdb2_id_ROB_i(cdb2_id_ROB),
    .cdb2_data_i(cdb2_data),

    .cdb3_en_i(cdb3_en),
    .cdb3_id_ROB_i(cdb3_id_ROB),
    .cdb3_data_i(cdb3_data),

    .A_o(EX2_A_i),
    .B_o(EX2_B_i),
    .Imm_o(EX2_Imm_i),
    .pc_o(EX2_pc_i),
    .OP_o(EX2_OP_i),
    .Funct7_o(EX2_Funct7_i),
    .Funct3_o(EX2_Funct3_i),
    .ROB_id_o(EX2_ROB_id_i),
    .en_EX_o(EX2_en_i)
);

RS_SL RS3(
    .clk(clk_in),
    .rst(rst_in),
    .rst_c(rst_c),
    .rdy(rdy_in),

    .en_i(RS3_en_i),
    .A_i(RS3_A_i),
    .B_i(RS3_B_i),
    .A_rdy_i(RS3_A_rdy_i),
    .B_rdy_i(RS3_B_rdy_i),
    .A_id_i(RS3_A_id_i),
    .B_id_i(RS3_B_id_i),
    .Imm_i(RS3_Imm_i),
    .OP_i(RS3_OP_i),
    .Funct3_i(RS3_Funct3_i),
    .ROB_id_i(RS3_ROB_id_i),
    .busy(ID_busySL_i),

    .cdb1_en_i(cdb1_en),
    .cdb1_id_ROB_i(cdb1_id_ROB),
    .cdb1_data_i(cdb1_data),

    .cdb2_en_i(cdb2_en),
    .cdb2_id_ROB_i(cdb2_id_ROB),
    .cdb2_data_i(cdb2_data),

    .cdb3_en_i(cdb3_en),
    .cdb3_id_ROB_i(cdb3_id_ROB),
    .cdb3_data_i(cdb3_data),

    .full_i(RS3_full_SLB_i),
    .A_o(SLB_A_i),
    .B_o(SLB_B_i),
    .Imm_o(SLB_Imm_i),
    .OP_o(SLB_OP_i),
    .Funct3_o(SLB_Funct3_i),
    .ROB_id_o(SLB_ROB_id_i),
    .en_o(SLB_en_i)
);

EX EX1(
    .clk(clk_in),
    .rst(rst_in),
    .en_i(EX1_en_i),
    .A_i(EX1_A_i),
    .B_i(EX1_B_i),
    .Imm_i(EX1_Imm_i),
    .pc_i(EX1_pc_i),
    .OP_i(EX1_OP_i),
    .Funct7_i(EX1_Funct7_i),
    .Funct3_i(EX1_Funct3_i),
    .ROB_id_i(EX1_ROB_id_i),
    .cdb_en_o(cdb1_en),
    .cdb_id_ROB_o(cdb1_id_ROB),
    .cdb_data_o(cdb1_data),
    .cdb_pc_o(cdb1_pc),
    .cdb_cond_o(cdb1_cond)
);

EX EX2(
    .clk(clk_in),
    .rst(rst_in),
    .en_i(EX2_en_i),
    .A_i(EX2_A_i),
    .B_i(EX2_B_i),
    .Imm_i(EX2_Imm_i),
    .pc_i(EX2_pc_i),
    .OP_i(EX2_OP_i),
    .Funct7_i(EX2_Funct7_i),
    .Funct3_i(EX2_Funct3_i),
    .ROB_id_i(EX2_ROB_id_i),
    .cdb_en_o(cdb2_en),
    .cdb_id_ROB_o(cdb2_id_ROB),
    .cdb_data_o(cdb2_data),
    .cdb_pc_o(cdb2_pc),
    .cdb_cond_o(cdb2_cond)
);

ROB ROB0(
    .clk(clk_in),
    .rst(rst_in),
    .rst_c(rst_c),
    .rdy(rdy_in),
    .full_o(ID_full_ROB_i),
    .empty_o(),
    //to ID
    .add_en_i(ROB_add_en_i),
    .add_rdytag_i(ROB_add_rdytag_i),
    .add_regaddr_i(ROB_add_regaddr_i),
    .add_branch_tag_i(ROB_branch_tag_i),
    .add_id(ID_add_id_ROB_i),
    //to ID
    .re1_i(ROB_re1_i),
    .re2_i(ROB_re2_i),
    .rid1_i(ROB_rid1_i),
    .rid2_i(ROB_rid2_i),
    .rdata1_o(fetch_data1_ROB_i),
    .rdata2_o(fetch_data2_ROB_i),
    .rrdy1_o(fetch_data1_rdy_ROB_i),
    .rrdy2_o(fetch_data2_rdy_ROB_i),
    //to commit
    .commit_rdy_i(ROB_commit_rdy_i),
    .commit_en_o(commit_en_i),
    .commit_id_o(commit_id_i),
    .commit_regaddr_o(commit_regaddr_i),
    .commit_data_o(commit_data_i),
    .commit_pc_o(commit_pc_i),
    .commit_branch_tag_o(commit_branch_tag_i),
    .commit_cond_o(commit_cond_i),
    //to cdb
    .cdb1_en_i(cdb1_en),
    .cdb1_id_ROB_i(cdb1_id_ROB),
    .cdb1_data_i(cdb1_data),
    .cdb1_pc_i(cdb1_pc),
    .cdb1_cond_i(cdb1_cond),

    .cdb2_en_i(cdb2_en),
    .cdb2_id_ROB_i(cdb2_id_ROB),
    .cdb2_data_i(cdb2_data),
    .cdb2_pc_i(cdb2_pc),
    .cdb2_cond_i(cdb2_cond),

    .cdb3_en_i(cdb3_en),
    .cdb3_id_ROB_i(cdb3_id_ROB),
    .cdb3_data_i(cdb3_data),

    .en_SL_o(SLB_en_SL_i)
);

commit commit0(
    .clk(clk_in),
    .rst(rst_in),

    .en_i(commit_en_i),
    .regaddr_i(commit_regaddr_i),
    .id_i(commit_id_i),
    .data_i(commit_data_i),
    .pc_i(commit_pc_i),
    .branch_tag_i(commit_branch_tag_i),
    .cond_i(commit_cond_i),

    .we_regfile_o(regfile_we_i),
    .waddr_regfile_o(regfile_waddr_i),
    .wid_regfile_o(regfile_wid_i),
    .wdata_regfile_o(regfile_wdata_i),
    .rdy_o(ROB_commit_rdy_i),
    
    .rst_c(rst_c),
    .en_if_o(IF_en_i),
    .pc_if_o(IF_pc_i)
);

regfile regfile0(
    .rst(rst_in),
    .rst_c(rst_c),
    .clk(clk_in),
    .rdy(rdy_in),
    .se(regfile_se_i),
    .saddr(regfile_saddr_i),
    .sid(regfile_sid_i),
    .we(regfile_we_i),
    .waddr(regfile_waddr_i),
    .wid(regfile_wid_i),
    .wdata(regfile_wdata_i),
    .re1(regfile_re1_i),
    .raddr1(regfile_raddr1_i),
    .re2(regfile_re2_i),
    .raddr2(regfile_raddr2_i),
    .rdata1(fetch_data1_regfile_i),
    .rrdy1(fetch_data1_rdy_regfile_i),
    .rid1(fetch_data1_rid_regfile_i),
    .rdata2(fetch_data2_regfile_i),
    .rrdy2(fetch_data2_rdy_regfile_i),
    .rid2(fetch_data2_rid_regfile_i)
);

SLbuffer SLbuffer0(
    .rst(rst_in),
    .rst_c(rst_c),
    .clk(clk_in),
    .rdy(rdy_in),
    
    .empty_o(),
    .full_o(RS3_full_SLB_i),

    .en_SL_i(SLB_en_SL_i),
    
    .RS_en_i(SLB_en_i),
    .A_i(SLB_A_i),
    .B_i(SLB_B_i),
    .Imm_i(SLB_Imm_i),
    .OP_i(SLB_OP_i),
    .Funct3_i(SLB_Funct3_i),
    .ROB_id_i(SLB_ROB_id_i),
    
    .rdy_i(SLB_rdy_i),
    .data_i(SLB_data_i),
    .en_o(datacache_en_i),
    .rw_o(datacache_rw_i),
    .addr_o(datacache_addr_i),
    .data_o(datacache_data_i),
    .width_o(datacache_width_i),

    .cdb_en_o(cdb3_en),
    .cdb_id_o(cdb3_id_ROB),
    .cdb_data_o(cdb3_data)
);

instcache instcache0(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    
    .en_i(instcache_en_i),
    .addr_i(instcache_addr_i),
    .rdy_o(IF_rdy_cache_i),
    .inst_o(IF_inst_cache_i),

    .rdy_i(instcache_rdy_i),
    .inst_i(instcache_inst_i),
    .en_o(rc_inst_en_i),
    .addr_o(rc_inst_addr_i)
);

datacache datacache0(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    
    .en_i(datacache_en_i),
    .rw_i(datacache_rw_i),
    .addr_i(datacache_addr_i),
    .data_i(datacache_data_i),
    .width_i(datacache_width_i),
    .rdy_o(SLB_rdy_i),
    .data_o(SLB_data_i),

    .rdy_i(datacache_rdy_i),
    .data_rc_i(datacache_data_rc_i),
    
    .en_o(rc_data_en_i),
    .rw_o(rc_data_rw_i),
    .width_o(rc_data_width_i),
    .addr_rc_o(rc_data_addr_i),
    .data_rc_o(rc_data_data_i)
);

ram_control rc0(
    .clk(clk_in),
    .rst(rst_in),
    .rst_c(rst_c),
    .rdy(rdy_in),
    
    .inst_en_i(rc_inst_en_i),
    .inst_addr_i(rc_inst_addr_i),
    .inst_rdy_o(instcache_rdy_i),
    .inst_inst_o(instcache_inst_i),

    .data_en_i(rc_data_en_i),
    .data_rw_i(rc_data_rw_i),
    .data_width_i(rc_data_width_i),
    .data_addr_i(rc_data_addr_i),
    .data_data_i(rc_data_data_i),
    .data_rdy_o(datacache_rdy_i),
    .data_data_o(datacache_data_rc_i),

    .ram_i(mem_din),
    .ram_rw_o(mem_wr),
    .ram_addr_o(mem_a),
    .ram_data_o(mem_dout)
);

endmodule
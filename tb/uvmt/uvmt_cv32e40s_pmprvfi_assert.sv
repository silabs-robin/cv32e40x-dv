`default_nettype none

module uvmt_cv32e40s_pmprvfi_assert
  import cv32e40s_pkg::*;
  import cv32e40s_rvfi_pkg::*;
  import uvm_pkg::*;
  import uvmt_cv32e40s_pkg::*;
#(
  parameter int  PMP_GRANULARITY = 0,
  parameter int  PMP_NUM_REGIONS = 0
)(
  // Clock and Reset
  input wire  clk_i,
  input wire  rst_ni,

  // RVFI
  input wire         rvfi_valid,
  input wire [31:0]  rvfi_insn,
  input wire [ 1:0]  rvfi_mode,
  input rvfi_trap_t  rvfi_trap,
  input wire [ 4:0]  rvfi_rd_addr,
  input wire [31:0]  rvfi_rd_wdata,
  input wire [ 4:0]  rvfi_rs1_addr,
  input wire [31:0]  rvfi_rs1_rdata,
  input wire [31:0]  rvfi_pc_rdata,
  input wire [31:0]  rvfi_mem_addr,
  input wire [ 3:0]  rvfi_mem_wmask,
  input wire [ 3:0]  rvfi_mem_rmask,

  // RVFI CSR
  //(pmpcfg)
  input wire [PMP_MAX_REGIONS/4-1:0][31:0]  rvfi_csr_pmpcfg_rdata,
  input wire [PMP_MAX_REGIONS/4-1:0][31:0]  rvfi_csr_pmpcfg_wdata,
  input wire [PMP_MAX_REGIONS/4-1:0][31:0]  rvfi_csr_pmpcfg_wmask,
  //(pmpaddr)
  input wire [PMP_MAX_REGIONS-1:0]  [31:0]  rvfi_csr_pmpaddr_rdata,
  input wire [PMP_MAX_REGIONS-1:0]  [31:0]  rvfi_csr_pmpaddr_wdata,
  input wire [PMP_MAX_REGIONS-1:0]  [31:0]  rvfi_csr_pmpaddr_wmask,
  //(mseccfg[h])
  input wire [31:0]  rvfi_csr_mseccfg_rdata,
  input wire [31:0]  rvfi_csr_mseccfg_wdata,
  input wire [31:0]  rvfi_csr_mseccfg_wmask,
  input wire [31:0]  rvfi_csr_mseccfgh_rdata,
  input wire [31:0]  rvfi_csr_mseccfgh_wdata,
  input wire [31:0]  rvfi_csr_mseccfgh_wmask,
  //(mstatus)
  input wire [31:0]  rvfi_csr_mstatus_rdata
);


  // Defines

  localparam logic [1:0] MODE_U = 2'b 00;
  localparam logic [1:0] MODE_M = 2'b 11;

  localparam logic [5:0] EXC_INSTR_ACC_FAULT    = 6'd 1;
  localparam logic [5:0] EXC_ILL_INSTR          = 6'd 2;
  localparam logic [5:0] EXC_LOAD_ACC_FAULT     = 6'd 5;
  localparam logic [5:0] EXC_STORE_ACC_FAULT    = 6'd 7;
  localparam logic [5:0] EXC_INSTR_BUS_FAULT    = 6'd 48;
  localparam logic [5:0] EXC_INSTR_CHKSUM_FAULT = 6'd 49;

  localparam logic [2:0] DBG_TRIGGER = 3'd 2;

  localparam int NUM_CFG_REGS  = 16;
  localparam int NUM_ADDR_REGS = 64;

  localparam int CSRADDR_FIRST_PMPCFG  = 12'h 3A0;
  localparam int CSRADDR_FIRST_PMPADDR = 12'h 3B0;
  localparam int CSRADDR_MSECCFG       = 12'h 747;


  // Defaults

  default clocking @(posedge clk_i); endclocking
  default disable iff !(rst_ni);


  // Helper signals

  wire  is_rvfi_csr_instr =
    rvfi_valid  &&
    (rvfi_insn[6:0] == 7'b 1110011)  &&
    (rvfi_insn[14:12] inside {1, 2, 3, 5, 6, 7});
  wire  is_rvfi_exception =
    rvfi_valid  &&
    rvfi_trap.trap  &&
    rvfi_trap.exception;
  wire  is_rvfi_exc_ill_instr =
    is_rvfi_exception  &&
    (rvfi_trap.exception_cause == EXC_ILL_INSTR);
  wire  is_rvfi_exc_instr_acc_fault =
    is_rvfi_exception  &&
    (rvfi_trap.exception_cause == EXC_INSTR_ACC_FAULT);
  wire  is_rvfi_exc_instr_bus_fault=
    is_rvfi_exception  &&
    (rvfi_trap.exception_cause == EXC_INSTR_BUS_FAULT);
  wire  is_rvfi_exc_instr_chksum_fault=
    is_rvfi_exception  &&
    (rvfi_trap.exception_cause == EXC_INSTR_CHKSUM_FAULT);
  wire  is_rvfi_dbg_trigger =
    rvfi_valid  &&
    rvfi_trap.debug  &&
    (rvfi_trap.debug_cause == DBG_TRIGGER);
  wire  is_rvfi_csr_read_instr =
    is_rvfi_csr_instr  &&
    rvfi_rd_addr;
    // TODO:ropeders double check correctness
  wire  is_rvfi_csr_write_instr =
    is_rvfi_csr_instr  &&
    !((rvfi_insn[13:12] inside {2'b 10, 2'b 11}) && !rvfi_rs1_addr);  // CSRRS/C[I] w/ rs1=x0/0
    // TODO:ropeders double check correctness
  wire [1:0]  rvfi_effective_mode =
    rvfi_csr_mstatus_rdata[17]      ?  // "mstatus.MPRV", modify privilege?
      rvfi_csr_mstatus_rdata[12:11] :  // "mstatus.MPP", loadstores act as if "mode==MPP"
      rvfi_mode;                       // Else, act as actual mode
  wire [31:0]  rvfi_mem_upperaddr =  // TODO:silabs-robin  "32:0" to avoid overflow problems?
    (rvfi_mem_rmask[3] || rvfi_mem_wmask[3]) ? (
      rvfi_mem_addr + 3
    ) : (
      (rvfi_mem_rmask[2] || rvfi_mem_wmask[2]) ? (
        rvfi_mem_addr + 2
      ) : (
        (rvfi_mem_rmask[1] || rvfi_mem_wmask[1]) ? (
          rvfi_mem_addr + 1
        ) : (
          rvfi_mem_addr
        )
      )
    );
  wire  is_split_datatrans =
    (rvfi_mem_upperaddr[31:2] != rvfi_mem_addr[31:2]);

  pmp_csr_t  pmp_csr_rvfi_rdata;
  pmp_csr_t  pmp_csr_rvfi_wdata;
  pmp_csr_t  pmp_csr_rvfi_wmask;
  for (genvar i = 0; i < PMP_MAX_REGIONS; i++) begin: gen_pmp_csr_readout
    localparam pmpcfg_reg_i    = i / 4;
    localparam pmpcfg_field_hi = (8 * (i % 4)) + 7;
    localparam pmpcfg_field_lo = (8 * (i % 4));

    assign pmp_csr_rvfi_rdata.cfg[i]  = rvfi_csr_pmpcfg_rdata[pmpcfg_reg_i][pmpcfg_field_hi : pmpcfg_field_lo];
    assign pmp_csr_rvfi_wdata.cfg[i]  = rvfi_csr_pmpcfg_wdata[pmpcfg_reg_i][pmpcfg_field_hi : pmpcfg_field_lo];
    assign pmp_csr_rvfi_wmask.cfg[i]  = rvfi_csr_pmpcfg_wmask[pmpcfg_reg_i][pmpcfg_field_hi : pmpcfg_field_lo];

    assign pmp_csr_rvfi_rdata.addr[i] = {rvfi_csr_pmpaddr_rdata[i], 2'b 00};  // TODO:ropeders is this assignment correct?
    assign pmp_csr_rvfi_wdata.addr[i] = {rvfi_csr_pmpaddr_wdata[i], 2'b 00};  // TODO:ropeders is this assignment correct?
    assign pmp_csr_rvfi_wmask.addr[i] = {rvfi_csr_pmpaddr_wmask[i], 2'b 00};  // TODO:ropeders is this assignment correct?
  end
  assign pmp_csr_rvfi_rdata.mseccfg = {rvfi_csr_mseccfgh_rdata, rvfi_csr_mseccfg_rdata};
  assign pmp_csr_rvfi_wdata.mseccfg = {rvfi_csr_mseccfgh_wdata, rvfi_csr_mseccfg_wdata};
  assign pmp_csr_rvfi_wmask.mseccfg = {rvfi_csr_mseccfgh_wmask, rvfi_csr_mseccfg_wmask};

  match_status_t  match_status_instr;
  match_status_t  match_status_data;
  match_status_t  match_status_upperdata;
  uvmt_cv32e40s_pmp_model #(
    .PMP_GRANULARITY  (PMP_GRANULARITY),
    .PMP_NUM_REGIONS  (PMP_NUM_REGIONS)
  ) model_instr_i (
    .clk   (clk_i),
    .rst_n (rst_ni),

    .csr_pmp_i      (pmp_csr_rvfi_rdata),
    .priv_lvl_i     (privlvl_t'(rvfi_mode)),
    .pmp_req_addr_i (rvfi_pc_rdata),
    .pmp_req_type_i (PMP_ACC_EXEC),
    .pmp_req_err_o  ('Z),

    .match_status_o (match_status_instr)
  );
  uvmt_cv32e40s_pmp_model #(
    .PMP_GRANULARITY  (PMP_GRANULARITY),
    .PMP_NUM_REGIONS  (PMP_NUM_REGIONS)
  ) model_data_i (
    .clk   (clk_i),
    .rst_n (rst_ni),

    .csr_pmp_i      (pmp_csr_rvfi_rdata),
    .priv_lvl_i     (privlvl_t'(rvfi_effective_mode)),
    .pmp_req_addr_i (rvfi_mem_addr),  // TODO:silabs-robin  Multi-op instructions
    .pmp_req_type_i (rvfi_mem_wmask ? PMP_ACC_WRITE : PMP_ACC_READ),  // TODO:silabs-robin  Not completely accurate...
    .pmp_req_err_o  ('Z),

    .match_status_o (match_status_data)
  );
  uvmt_cv32e40s_pmp_model #(
    .PMP_GRANULARITY  (PMP_GRANULARITY),
    .PMP_NUM_REGIONS  (PMP_NUM_REGIONS)
  ) model_upperdata_i (
    .clk   (clk_i),
    .rst_n (rst_ni),

    .csr_pmp_i      (pmp_csr_rvfi_rdata),
    .priv_lvl_i     (privlvl_t'(rvfi_effective_mode)),
    .pmp_req_addr_i (rvfi_mem_upperaddr),  // TODO:silabs-robin  Multi-op instructions
    .pmp_req_type_i (rvfi_mem_wmask ? PMP_ACC_WRITE : PMP_ACC_READ),  // TODO:silabs-robin  Not completely accurate...
    .pmp_req_err_o  ('Z),

    .match_status_o (match_status_upperdata)
  );


  // Assertions

  // PMP CSRs only accessible from M-mode
  property p_csrs_mmode_only;
    is_rvfi_csr_instr  &&
    (rvfi_mode == MODE_U)  &&
    (rvfi_insn[31:20] inside {['h3A0 : 'h3EF], 'h747, 'h757})
    |->
    is_rvfi_exc_ill_instr  ^
    is_rvfi_exc_instr_acc_fault  ^
    is_rvfi_dbg_trigger ^
    is_rvfi_exc_instr_bus_fault  ^
    is_rvfi_exc_instr_chksum_fault;
  endproperty : p_csrs_mmode_only
  a_csrs_mmode_only: assert property (
    p_csrs_mmode_only
  );
  cov_csrs_mmod_only: cover property (
    p_csrs_mmode_only  and  is_rvfi_exc_ill_instr
  );

  // NAPOT, some bits read as ones, depending on G
  if (PMP_GRANULARITY >= 2) begin: gen_napot_ones_g2
    //TODO:ropeders no magic numbers
    for (genvar i = 0; i < PMP_NUM_REGIONS; i++) begin: gen_napot_ones_i
      a_napot_ones: assert property (
        rvfi_valid  &&
        pmp_csr_rvfi_rdata.cfg[i].mode[1]
        |->
        (pmp_csr_rvfi_rdata.addr[i][PMP_GRANULARITY-2:0] == '1)
      );
    end
  end

  // OFF/TOR, some bits read as zeros, depending on G
  if (PMP_GRANULARITY >= 1) begin: gen_all_zeros_g1
    for (genvar i = 0; i < PMP_NUM_REGIONS; i++) begin: gen_all_zeros_i
      a_all_zeros: assert property (
        rvfi_valid  &&
        (pmp_csr_rvfi_rdata.cfg[i].mode[1] === 1'b 0)
        |->
        (pmp_csr_rvfi_rdata.addr[i][PMP_GRANULARITY-1:0] == '0)
      );
    end
  end

  // Software-view on PMP CSRs matches RVFI-view
  for (genvar i = 0; i < NUM_CFG_REGS; i++) begin: gen_swview_cfg
    a_pmpcfg_swview: assert property (
      // TODO:ropeders no magic numbers
      is_rvfi_csr_read_instr  &&
      (rvfi_insn[31:20] == (CSRADDR_FIRST_PMPCFG + i))
      |->
      (rvfi_rd_wdata == rvfi_csr_pmpcfg_rdata[i])
    );
  end
  for (genvar i = 0; i < NUM_ADDR_REGS; i++) begin: gen_swview_addr
    a_pmpaddr_swview: assert property (
      // TODO:ropeders no magic numbers
      is_rvfi_csr_read_instr  &&
      (rvfi_insn[31:20] == (CSRADDR_FIRST_PMPADDR + i))
      |->
      (rvfi_rd_wdata == rvfi_csr_pmpaddr_rdata[i])
    );
  end

  // Software views does not change underlying register value
  property p_storage_unaffected(i);
    logic [31:0] pmpaddr;
    accept_on (
      is_rvfi_csr_write_instr  &&
      (rvfi_insn[31:20] == (CSRADDR_FIRST_PMPADDR + i))
    )
      rvfi_valid  ##0
      pmp_csr_rvfi_rdata.cfg[i].mode[1]  ##0
      (1, pmpaddr = pmp_csr_rvfi_rdata.addr[i])
      ##1
      (rvfi_valid [->1])  ##0
      (pmp_csr_rvfi_rdata.cfg[i].mode[1] == 1'b 0)
      ##1
      (rvfi_valid [->1])  ##0
      pmp_csr_rvfi_rdata.cfg[i].mode[1]
    |->
    (pmp_csr_rvfi_rdata.addr[i][31:0] == pmpaddr);
    // Note, this _can_ be generalized more, but at a complexity/readability cost
  endproperty : p_storage_unaffected
  for (genvar i = 0; i < PMP_NUM_REGIONS; i++) begin: gen_storage_unaffected
    a_storage_unaffected: assert property (
      p_storage_unaffected(i)
    );
  end

  // TODO:ropeders "uvm_error" on all assertions

  // Software-view can read the granularity level
  a_granularity_determination: assert property (
    (is_rvfi_csr_instr && (rvfi_insn[14:12] == 3'b 001)) &&  // CSRRW instr,
    (rvfi_insn[31:20] == (CSRADDR_FIRST_PMPADDR + 0))    &&  // to a "pmpaddr" CSR,
    ((rvfi_rs1_rdata == '1) && rvfi_rs1_addr)            &&  // writing all ones.
    (pmp_csr_rvfi_rdata.cfg[0] == '0)                    &&  // Related cfg is 0,
    (pmp_csr_rvfi_rdata.cfg[0+1] == '0)                  &&  // above cfg is 0.
    !rvfi_trap                                               // (Trap doesn't meddle.)
    |=>
    (rvfi_valid [->1])  ##0
    (rvfi_csr_pmpaddr_rdata[0][31:PMP_GRANULARITY] == '1)  &&
    (rvfi_csr_pmpaddr_rdata[0][PMP_GRANULARITY-1:0] == '0)
    // Note: _Can_ be generalized for all i
  );

  // Locking is forever
  for (genvar i = 0; i < PMP_NUM_REGIONS; i++) begin: gen_until_reset
    a_until_reset: assert property (
      pmp_csr_rvfi_rdata.cfg[i].lock  &&
      !pmp_csr_rvfi_rdata.mseccfg.rlb
      |->
      always pmp_csr_rvfi_rdata.cfg[i].lock
    );
  end
  // Stickiness isn't effectuated before triggered  (vplan "UntilReset")
  property  p_until_reset_notbefore;
    logic  rlb;
    $rose(rst_ni)                                               ##0
    (rvfi_valid [->1])                                          ##0  // First retire
    (is_rvfi_csr_write_instr && (rvfi_insn[14:12] == 3'b 001))  ##0  // ..."csrrw"
    (rvfi_insn[31:20] == CSRADDR_MSECCFG)                       ##0  // ...to mseccfg
    !rvfi_trap                                                  ##0
    (1, rlb = rvfi_rs1_rdata[2])                                     // (Write-attempt's data)
    |->
    pmp_csr_rvfi_wmask.mseccfg.rlb          &&  // Must attempt
    (pmp_csr_rvfi_wdata.mseccfg.rlb == rlb)     // Must succeed
    ;
  endproperty : p_until_reset_notbefore
  a_until_reset_notbefore: assert property (
    p_until_reset_notbefore
  );

  // Locked entries, ignore pmpicfg/pmpaddri writes
  for (genvar i = 0; i < PMP_NUM_REGIONS; i++) begin: gen_ignore_writes_notrap
    // "Ignored writes" don't trap:
    a_ignore_writes_notrap: assert property (
      is_rvfi_csr_write_instr  &&
      (rvfi_insn[31:20] inside {(CSRADDR_FIRST_PMPADDR + i), (CSRADDR_FIRST_PMPCFG + i)})  &&
      (pmp_csr_rvfi_rdata.cfg[i].lock && !pmp_csr_rvfi_rdata.mseccfg.rlb)  &&
      (rvfi_mode == MODE_M)
      |->
      (rvfi_trap.exception_cause != EXC_ILL_INSTR)
    );
  end

  // Locked entries, ignore pmpicfg/pmpaddri writes
  for (genvar i = 0; i < PMP_NUM_REGIONS; i++) begin: gen_ignore_writes_nochange
    // Ignored writes means stable data
    a_ignore_writes_nochange: assert property (
      rvfi_valid &&
      (pmp_csr_rvfi_rdata.cfg[i].lock && !pmp_csr_rvfi_rdata.mseccfg.rlb)
      |=>
      always (
        $stable(pmp_csr_rvfi_rdata.cfg[i])  &&
        $stable(pmp_csr_rvfi_rdata.addr[i])
      )
    );
  end

  // Locked entries, ignore pmpicfg/pmpaddri writes
  for (genvar i = 0; i < PMP_NUM_REGIONS; i++) begin: gen_not_ignore_writes_torcfg
    // We can see change even if "above config" is locked TOR
    property p_not_ignore_writes_torcfg;
      logic [7:0] cfg;
      rvfi_valid  &&
      pmp_csr_rvfi_rdata.cfg[i+1].lock  &&
      (pmp_csr_rvfi_rdata.cfg[i+1].mode == PMP_MODE_TOR)  ##0
      (1, cfg = pmp_csr_rvfi_rdata.cfg[i])
      ##1
      (rvfi_valid [->1])  ##0
      (pmp_csr_rvfi_rdata.cfg[i] != cfg);
    endproperty : p_not_ignore_writes_torcfg
    cov_not_ignore_writes_torcfg: cover property (
      p_not_ignore_writes_torcfg
      // TODO:silabs-robin  Reconsider, rewrite.
    );
  end

  // Written cfg is written as expected
  for (genvar i = 0; i < PMP_NUM_REGIONS; i++) begin: gen_cfg_expected
    wire pmpncfg_t  cfg_expected = rectify_cfg_write(pmp_csr_rvfi_rdata.cfg[i], rvfi_rs1_rdata[8*(i%4) +: 8]);
    property  p_cfg_expected;
      (is_rvfi_csr_write_instr && (rvfi_insn[14:12] == 3'b 001))  &&  // "csrrw"
      (rvfi_insn[31:20] == (CSRADDR_FIRST_PMPCFG + i/4))          &&  // ...to cfg's csr
      (!rvfi_trap)
      |->
      (pmp_csr_rvfi_wmask.cfg[i] == 8'h FF)  &&  // Must write cfg
      (pmp_csr_rvfi_wdata.cfg[i] == cfg_expected)
      // Note, this doesn't check csrr(s/c)[i]
      ;
    endproperty : p_cfg_expected
    a_cfg_expected: assert property (
      p_cfg_expected
    );
    a_not_ignore_writes_cfg_unlocked: assert property (
      // Locked entries, ignore pmpicfg writes
      p_cfg_expected  and
      !pmp_csr_rvfi_rdata.cfg[i].lock
      // This is redundant, but explicitly covers non-locked regions
    );
    cov_cfg_expected_updates: cover property (
      if (pmp_csr_rvfi_wdata.cfg[i] != pmp_csr_rvfi_rdata.cfg[i]) (
        p_cfg_expected
      )
    );
    cov_cfg_expected_ones: cover property (
      p_cfg_expected  and
      (rvfi_rs1_rdata[8*(i%4) +: 8] == '1)
    );
  end
  // Written cfg is legal  (vplan "ExecIgnored", ...)
  for (genvar i = 0; i < PMP_NUM_REGIONS; i++) begin: gen_cfgwdata_legal
    wire [7:0] rectified_cfg = rectify_cfg_write(pmp_csr_rvfi_rdata.cfg[i], pmp_csr_rvfi_wdata.cfg[i]);
    a_cfgwdata_legal: assert property (
      rvfi_valid  &&
      pmp_csr_rvfi_wmask.cfg[i]
      |->
      (pmp_csr_rvfi_wdata.cfg[i] == rectified_cfg)
    );
  end
  // Read cfg is as expected
  for (genvar i = 0; i < PMP_NUM_REGIONS; i++) begin: gen_cfgrdata_expected
    property p_cfgrdata_expected;
      pmpncfg_t  cfg_prev;
      rvfi_valid  ##0
      (1, cfg_prev = pmp_csr_rvfi_rdata.cfg[i])
      ##1
      (rvfi_valid [->1])
      |->
      (pmp_csr_rvfi_rdata.cfg[i] == rectify_cfg_write(cfg_prev, pmp_csr_rvfi_rdata.cfg[i]))
      ;
    endproperty : p_cfgrdata_expected
    a_cfgrdata_expected: assert property (
      p_cfgrdata_expected
    );
  end

  // addr/addr-1  unlocked->unstable
  sequence  seq_csrrw_pmpaddri(i);
    (is_rvfi_csr_write_instr && (rvfi_insn[14:12] == 3'b 001))  &&  // "csrrw"
    (rvfi_insn[31:20] == (CSRADDR_FIRST_PMPADDR + i))         &&  // ...to addr csr
    (!rvfi_trap)
    ;
  endsequence : seq_csrrw_pmpaddri
  for (genvar i = 0; i < PMP_NUM_REGIONS; i++) begin: gen_addr_writes
    a_addr_writeattempt: assert property (
      seq_csrrw_pmpaddri(i)
      |->
      (pmp_csr_rvfi_wmask.addr[i][33:2] == 32'h FFFF_FFFF)
    );
    a_addr_nonlocked: assert property (
      seq_csrrw_pmpaddri(i)  and
      !pmp_csr_rvfi_rdata.cfg[i].lock
      |->
      (pmp_csr_rvfi_wdata.addr[i][33:2] == rvfi_rs1_rdata)
      // TODO:silabs-robin  This might not be complete. Waiting for RTL/RVFI fix first.
    );
  end
  for (genvar i = 1; i < PMP_NUM_REGIONS; i++) begin: gen_addr_tor
    a_addr_nonlocked_tor: assert property (
      seq_csrrw_pmpaddri(i - 1)                         and
      (pmp_csr_rvfi_rdata.cfg[i].mode == PMP_MODE_TOR)  and
      !pmp_csr_rvfi_rdata.cfg[i  ].lock                 and
      !pmp_csr_rvfi_rdata.cfg[i-1].lock
      |->
      (pmp_csr_rvfi_wdata.addr[i-1] == rvfi_rs1_rdata)
      // TODO:silabs-robin  This might not be complete. Waiting for RTL/RVFI fix first.
    );
  end

  // RVFI: Reported CSR (cfg) writes take effect
  for (genvar i = 0; i < PMP_NUM_REGIONS; i++) begin: gen_rvfi_csr_writes
    property  p_rvfi_csr_writes;
      logic [7:0]  cfg, cfg_r, cfg_w;
      rvfi_valid  ##0
      (1, cfg_w = (pmp_csr_rvfi_wdata.cfg[i] &  pmp_csr_rvfi_wmask.cfg[i]))  ##0
      (1, cfg_r = (pmp_csr_rvfi_rdata.cfg[i] & ~pmp_csr_rvfi_wmask.cfg[i]))  ##0
      (1, cfg = (cfg_r | cfg_w))
      |=>
      (rvfi_valid [->1])  ##0
      (pmp_csr_rvfi_rdata.cfg[i] == cfg)
      ;
    endproperty : p_rvfi_csr_writes
    a_rvfi_csr_writes: assert property (
      p_rvfi_csr_writes
    );
  end

  // Locked TOR, ignore i-1 addr writes
  for (genvar i = 1; i < PMP_NUM_REGIONS; i++) begin: gen_ignore_tor
    a_ignore_tor: assert property (
      rvfi_valid &&
      (pmp_csr_rvfi_rdata.cfg[i].lock && !pmp_csr_rvfi_rdata.mseccfg.rlb)  &&
      (pmp_csr_rvfi_rdata.cfg[i].mode == PMP_MODE_TOR)
      |=>
      always $stable(pmp_csr_rvfi_rdata.addr[i-1][31:PMP_GRANULARITY])
    );
  end

  // TODO  ("WaitUpdate"/"AffectSuccessors")
  a_noexec_musttrap: assert property (
    rvfi_valid  &&
    !match_status_instr.is_access_allowed
    |->
    rvfi_trap
    // TODO:silabs-robin  Can assert the opposite too?
  );
  a_noexec_cause: assert property (
    rvfi_valid  &&
    !match_status_instr.is_access_allowed  &&
    rvfi_trap.exception
    |->
    (rvfi_trap.exception_cause == EXC_INSTR_ACC_FAULT)
    // Note, if we implement etrigger etc then priority will change
  );

  // TODO  ("WaitUpdate"/"AffectSuccessors")
  a_noloadstore_musttrap: assert property (
    rvfi_valid  &&
    (rvfi_mem_rmask || rvfi_mem_wmask)  &&
    !match_status_data.is_access_allowed
    |->
    rvfi_trap
  );
  a_noloadstore_cause_load: assert property (
    (rvfi_valid && rvfi_mem_rmask)  &&
    !match_status_data.is_access_allowed  &&
    rvfi_trap.exception
    |->
    (rvfi_trap.exception_cause == EXC_LOAD_ACC_FAULT)
  );
  a_noloadstore_cause_store: assert property (
    (rvfi_valid && rvfi_mem_wmask)  &&
    !match_status_data.is_access_allowed  &&
    rvfi_trap.exception
    |->
    (rvfi_trap.exception_cause == EXC_STORE_ACC_FAULT)
  );
  a_noloadstore_splittrap: assert property (
    rvfi_valid  &&
    is_split_datatrans  &&
    !match_status_upperdata.is_access_allowed
    |->
    rvfi_trap
    // TODO:silabs-robin  Instr-side.
  );

  // RWX has reservations
  for (genvar i = 0; i < PMP_NUM_REGIONS; i++) begin: gen_rwx_mml
    a_rwx_mml: assert property (
      !pmp_csr_rvfi_rdata.mseccfg.mml
      |->
      (pmp_csr_rvfi_rdata.cfg[i][1:0] != 2'b 10)
    );
  end

  // RLB lifts restrictions
  for (genvar i = 0; i < PMP_NUM_REGIONS; i++) begin: gen_rlblifts_lockedexec
    wire pmpncfg_t  cfg_attempt = rvfi_rs1_rdata[8*(i%4) +: 8];
    a_rlblifts_lockedexec: assert property (
      pmp_csr_rvfi_rdata.mseccfg.rlb  &&
      pmp_csr_rvfi_rdata.mseccfg.mml
      ##0
      (is_rvfi_csr_write_instr && (rvfi_insn[14:12] == 3'b 001))  &&  // "csrrw"
      (rvfi_insn[31:20] == (CSRADDR_FIRST_PMPCFG + i/4))          &&  // ...to cfg's csr
      !rvfi_trap
      ##0
      ({cfg_attempt.lock, cfg_attempt.read, cfg_attempt.write, cfg_attempt.exec}
        inside {4'b 1001, 4'b 1010, 4'b 1011, 4'b 1101})
      |->
      //({pmp_csr_rvfi_wdata.cfg[i].lock, pmp_csr_rvfi_wdata.cfg[i].read, pmp_csr_rvfi_wdata.cfg[i].write, pmp_csr_rvfi_wdata.cfg[i].exec}
      //  inside {4'b 1001, 4'b 1010, 4'b 1011, 4'b 1101})
      // TODO:robin-silabs  && (wdata == attempt) ?
      (pmp_csr_rvfi_wdata.cfg[i] == cfg_attempt)
    );
  end
  cov_rlb_mml: cover property (
    rvfi_valid  &&
    pmp_csr_rvfi_rdata.mseccfg.rlb  &&
    pmp_csr_rvfi_rdata.mseccfg.mml
  );


  // Translate write-attempts to legal values
  function automatic pmpncfg_t  rectify_cfg_write (pmpncfg_t cfg_pre, pmpncfg_t cfg_attempt);
    pmpncfg_t  cfg_rfied;

    // Initial assumption: Attempt is ok
    cfg_rfied = cfg_attempt;

    // Pick "pre-state" where required
    begin
      // RWX collective WARL
      if ((cfg_attempt[2:0] inside {2, 6}) && !pmp_csr_rvfi_rdata.mseccfg.mml) begin
        cfg_rfied[2:0] = cfg_pre[2:0];
      end

      // NA4, G=0
      if ((PMP_GRANULARITY >= 1) && (cfg_attempt.mode == PMP_MODE_NA4)) begin
        cfg_rfied.mode = cfg_pre.mode;
      end

      // Locked config can't change
      if (cfg_pre.lock && !pmp_csr_rvfi_rdata.mseccfg.rlb) begin
        cfg_rfied = cfg_pre;
      end

      // MML, no locked-executable
      if (
        (pmp_csr_rvfi_rdata.mseccfg.mml && !pmp_csr_rvfi_rdata.mseccfg.rlb)  &&
        ({cfg_attempt.lock, cfg_attempt.read, cfg_attempt.write, cfg_attempt.exec}
          inside {4'b 1001, 4'b 1010, 4'b 1011, 4'b 1101})
        // TODO:silabs-robin  && (wdata != rdata))  // Unchanged is not "adding"
      )
      begin
        cfg_rfied = cfg_pre;
        // TODO:silabs-robin  Test "a_cfg_expected" without this clause.
      end
    end

    // Tied zero
    cfg_rfied.zero0 = '0;

    // TODO:silabs-robin  Move function to shared functions file?
    return  cfg_rfied;
  endfunction : rectify_cfg_write

endmodule : uvmt_cv32e40s_pmprvfi_assert

`default_nettype wire

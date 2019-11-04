// Code your testbench here
// or browse Examples



class sfr_seq_item extends uvm_sequence_item;

`uvm_object_utils(sfr_seq_item)

function new(string name = "sfr_seq_item");
  super.new(name);
endfunction

 rand bit[2:0] req;
  bit [2:0] grant;
  
  constraint req_c {($countones (req)) == 1;}
 
function string convert_to_string();
  string s;

//  s = $sformatf("%t req: %0h, grant : %0h", $time(), req,grant);

  return s;
endfunction
  
  endclass: sfr_seq_item

class sfr_test_seq extends uvm_sequence #(sfr_seq_item);

`uvm_object_utils(sfr_test_seq)

function new(string name = "sfr_test_seq");
  super.new(name);
endfunction

task body;
  sfr_seq_item item = sfr_seq_item::type_id::create("item");

  repeat(30) begin
    start_item(item);
  assert(item.randomize());
   
    `uvm_info("seq_body", item.convert_to_string(), UVM_LOW);
    finish_item(item);
  end

endtask: body

endclass: sfr_test_seq
  
 class sfr_config_object extends uvm_object;

`uvm_object_utils(sfr_config_object)

function new(string name = "sfr_config_object");
  super.new(name);
endfunction

bit is_active;

virtual sfr_master_bfm SFR_MASTER;
virtual sfr_monitor_bfm SFR_MONITOR;

endclass: sfr_config_object

class sfr_driver extends uvm_driver #(sfr_seq_item);

`uvm_component_utils(sfr_driver)

function new(string name = "sfr_driver", uvm_component parent = null);
  super.new(name, parent);
endfunction

virtual sfr_master_bfm SFR;

extern task run_phase(uvm_phase phase);

endclass: sfr_driver

task sfr_driver::run_phase(uvm_phase phase);
  sfr_seq_item item;

  forever begin
    seq_item_port.get_next_item(item);
    SFR.execute(item);
    seq_item_port.item_done();
  end

endtask: run_phase
  

  
  interface sfr_master_bfm(input clk, 
                           input reset,
                           output logic[2:0] req,
                           input logic [2:0] grant);
                         
//  import sfr_agent_pkg::*;

  always @(reset or posedge clk) begin
    if(reset == 1) begin
      req <= 0;
    end
  end

  task execute(sfr_seq_item item);
    if(reset == 1) begin
      wait(reset == 0);
    end
    else begin
      @(posedge clk);
     req = item.req;
  
      // Output coming back from the DUT
      item.grant = grant;
      end
  endtask: execute

endinterface: sfr_master_bfm
  
  class sfr_monitor extends uvm_component;

`uvm_component_utils(sfr_monitor)

function new(string name = "sfr_monitor", uvm_component parent = null);
  super.new(name, parent);
endfunction

virtual sfr_monitor_bfm SFR;
uvm_analysis_port #(sfr_seq_item) ap;

extern function void build_phase(uvm_phase phase);
extern task run_phase(uvm_phase phase);

endclass: sfr_monitor

function void sfr_monitor::build_phase(uvm_phase phase);
  ap = new("ap", this);
endfunction: build_phase

task sfr_monitor::run_phase(uvm_phase phase);
  sfr_seq_item item;

  forever begin
    item = sfr_seq_item::type_id::create("item");
    SFR.monitor(item);
    ap.write(item);
  end

endtask: run_phase

  
  interface sfr_monitor_bfm(input clk, 
                            input reset,
                            input[2:0] req,
                            input[2:0] grant);
                          
 // import sfr_agent_pkg::*;


  task monitor(sfr_seq_item item);
    @(posedge clk);
    item.req = req;
    item.grant = grant;
    
    // Output coming back from the DUT
       
    
  endtask: monitor

endinterface: sfr_monitor_bfm
  
  
class sfr_agent extends uvm_component;

`uvm_component_utils(sfr_agent)

uvm_analysis_port #(sfr_seq_item) ap;

uvm_sequencer #(sfr_seq_item) sequencer;

sfr_driver driver;
sfr_monitor monitor;

sfr_config_object cfg;

function new(string name = "sfr_agent", uvm_component parent = null);
  super.new(name, parent);
endfunction

extern function void build_phase(uvm_phase phase);
extern function void connect_phase(uvm_phase phase);

endclass: sfr_agent

function void sfr_agent::build_phase(uvm_phase phase);
  if(cfg == null) begin
    if(!uvm_config_db #(sfr_config_object)::get(this, "", "SFR_CFG", cfg)) begin
      `uvm_error("BUILD_PHASE", "Unable to find sfr agent config object in the uvm_config_db")
    end
  end
  ap = new("ap", this);
  monitor = sfr_monitor::type_id::create("monitor", this);
  if(cfg.is_active == 1) begin
    driver = sfr_driver::type_id::create("driver", this);
    sequencer = uvm_sequencer #(sfr_seq_item)::type_id::create("sequencer", this);
  end
endfunction: build_phase

function void sfr_agent::connect_phase(uvm_phase phase);
  monitor.SFR = cfg.SFR_MONITOR;
  monitor.ap.connect(ap);
  if(cfg.is_active == 1) begin
    driver.SFR = cfg.SFR_MASTER;
    driver.seq_item_port.connect(sequencer.seq_item_export);
  end
endfunction: connect_phase
  
  
  class sfr_env_config extends uvm_object;

`uvm_object_utils(sfr_env_config)

function new(string name = "sfr_env_config");
  super.new(name);
endfunction

sfr_config_object sfr_agent_cfg;

endclass: sfr_env_config
  
class sfr_scoreboard extends uvm_subscriber #(sfr_seq_item);

`uvm_component_utils(sfr_scoreboard)

  virtual sfr_monitor_bfm test;

int errors;
int req;

function new(string name = "sfr_scoreboard", uvm_component parent = null);
  super.new(name, parent);
  errors = 0;
  req = 0;
endfunction



extern function void write(sfr_seq_item t);
extern function void report_phase(uvm_phase phase);

endclass: sfr_scoreboard

function void sfr_scoreboard::write(sfr_seq_item t);
  if(t.req !=0 ) begin
    
      req++;
   
    if(t.grant != t.req) begin
      `uvm_info("** UVM SCOREBOARD **", $sformatf("SFR SB mismatch grant %d req %d", t.grant,t.req), UVM_LOW)
        errors++;
      end
    end
  
 
  
endfunction: write

function void sfr_scoreboard::report_phase(uvm_phase phase);
  if(errors == 0) begin
    `uvm_info("** UVM TEST PASSED **", $sformatf("SFR agent test passed with no errors in %0d valid read scenarios", req), UVM_LOW)
  end
  else begin
    `uvm_error("!! UVM TEST FAILED !!", $sformatf("SFR agent test failed with %0d errors in %0d valid read scenarios", errors, req))
  end
endfunction: report_phase

  
  class sfr_env extends uvm_component;

`uvm_component_utils(sfr_env)

function new(string name = "sfr_env", uvm_component parent = null);
  super.new(name, parent);
endfunction

sfr_env_config cfg;
sfr_scoreboard sb;
sfr_agent agent;

extern function void build_phase(uvm_phase phase);
extern function void connect_phase(uvm_phase phase);

endclass: sfr_env

function void sfr_env::build_phase(uvm_phase phase);
  if(cfg == null) begin
    if(!uvm_config_db #(sfr_env_config)::get(this, "", "CFG", cfg)) begin
      `uvm_error("BUILD_PHASE", "Unable to find environment configuration object in the uvm_config_db")
    end
  end
  sb = sfr_scoreboard::type_id::create("sb", this);
  agent = sfr_agent::type_id::create("agent", this);
  agent.cfg = cfg.sfr_agent_cfg;
endfunction: build_phase

function void sfr_env::connect_phase(uvm_phase phase);
  agent.ap.connect(sb.analysis_export);
endfunction: connect_phase
  
  
  
  
  
  class sfr_test extends uvm_component;

`uvm_component_utils(sfr_test)

function new(string name = "sfr_test", uvm_component parent = null);
  super.new(name, parent);
endfunction

sfr_env_config env_cfg;
sfr_config_object sfr_agent_cfg;

sfr_env env;

extern function void build_phase(uvm_phase phase);
extern task run_phase(uvm_phase phase);

endclass: sfr_test

function void sfr_test::build_phase(uvm_phase phase);
  env_cfg = sfr_env_config::type_id::create("env_cfg");
  sfr_agent_cfg = sfr_config_object:: type_id::create("sfr_agent_cfg");
  if(!uvm_config_db #(virtual sfr_master_bfm)::get(this, "", "SFR_MASTER", sfr_agent_cfg.SFR_MASTER)) begin
    `uvm_error("BUILD_PHASE", "Unable to find virtual interface sfr_master_bfm in the uvm_config_db")
  end
  if(!uvm_config_db #(virtual sfr_monitor_bfm)::get(this, "", "SFR_MONITOR", sfr_agent_cfg.SFR_MONITOR)) begin
    `uvm_error("BUILD_PHASE", "Unable to find virtual interface sfr_master_bfm in the uvm_config_db")
  end
  sfr_agent_cfg.is_active = 1;
  env_cfg.sfr_agent_cfg = sfr_agent_cfg;
  env = sfr_env::type_id::create("env", this);
  env.cfg = env_cfg;
endfunction: build_phase

task sfr_test::run_phase(uvm_phase phase);
  sfr_test_seq seq = sfr_test_seq::type_id::create("seq");

  phase.raise_objection(this);

  seq.start(env.agent.sequencer);

  phase.drop_objection(this);

endtask: run_phase

  module hdl_top;

import uvm_pkg::*;

logic clk;
logic reset;
    wire[2:0] req;
    wire[2:0] grant;

sfr_master_bfm SFR_MASTER(.clk(clk),
                          .reset(reset),
                          .req(req),
                          .grant(grant)
                         );
                          
sfr_monitor_bfm SFR_MONITOR(.clk(clk),
                            .reset(reset),
                            .req (req),
                            .grant (grant));

round_robin_arbiter dut (.clk(clk),
                         .rst(reset),
             .req(req),
             .grant(grant)
             );

initial begin
  reset <= 1;
  clk <= 0;
  repeat(10) begin
    #10ns clk <= ~clk;
  end
  reset <= 0;
  forever begin
    #10ns clk <= ~clk;
  end
end
    
    initial begin
  
      run_test ();
      

      
    end

    initial begin
      $dumpfile ("dump.vcd");
      $dumpvars (0,hdl_top);
    end
    
initial begin
  uvm_config_db #(virtual sfr_master_bfm)::set(null, "uvm_test_top", "SFR_MASTER", SFR_MASTER);
  uvm_config_db #(virtual sfr_monitor_bfm)::set(null, "uvm_test_top", "SFR_MONITOR", SFR_MONITOR);
end

endmodule
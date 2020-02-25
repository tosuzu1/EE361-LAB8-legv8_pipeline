

// LEGLitePipe
//
// This is empty, so you have to fill it up with parts
// and the controller such as
// * registers between pipeline stages, e.g., IF/ID register
// * ALU
// * multiplexers
// * register file
// * Instruction memory
// * controller
//
// Note that you can get most of these parts from Parts.V
// Remember that RegFile is synchronized with negative clock
//    edge, e.g., always @(negedge clock)
//
// In the code below, comments show where to put each stage
//    and the registers between stages.


module LEGLitePipe(
	output logic [15:0] imemaddr, 	// Instruction memory addr
	output logic [15:0] dmemaddr,	// Data memory addr
	output logic [15:0] dmemwdata,	// Data memory write-data
	output logic dmemwrite,	// Data memory write enable
	output logic dmemread,	// Data memory read enable
	output logic [15:0] aluresult, // Output from the ALU:  for debugging
	input logic clock,
	input logic [15:0] imemrdata, // Instruction memory read data
	input logic [15:0] dmemrdata, // Data memory read data
	input logic reset,	// Reset
	output logic [15:0] probe
	);

//------- state_tracker------------
reg [1:0] controller_state ;

always_ff@(posedge clock)
	begin
	if (reset==1 || controller=='b11)
		controller_state <= 0;
	else 
		controller_state <= controller_state + 1;
	end 

	
//------- IF stage ----------------
//ports
wire [15:0] pc_input, unbranched_add, branch_add;
reg [15:0] current_pc;

//adder for pc
assign unbranched_add = current_pc + 2;

//MUX for pc increment
MUX2 pc_mux(
	pc_input,
	unbranched_add,
	branch_add,
	PCSrc
	);
	
// placeholder pc controller	
always_ff@(posedge clock)
	begin
	if (reset==1)
		current_pc <= 0;
	else if(state == 0)
		current_pc <= current_pc + pc_input;
	end 

//------- IF/ID register ----------
// To implement this register, you must declare
// register variables, e.g.,
reg IFIDinstr[15:0];
reg IFIDpc[15:0];
always_ff @(posedge clock)
   begin
   IFIDinstr[15:0] <= imemrdata;
   IFIDpc <= current_pc;
   end


//------- ID stage ----------------
//Sign extension
wire [15:0] signextension;
assign signextension = {{10{IFIDinstr[11]}},IFIDinstr[11:6]};

//Controller
wire IDreg2loc;
wire IDuncondbranch;
wire IDbranch;
wire IDmemread;
wire IDmemtoreg;
wire [2:0] IDalu_sel;
wire IDmemwrite;
wire IDalusrc;
wire IDregwrite;

//reg
wire [15:0] IDrdata1;
wire [15:0] IDrdata2;

Control legv8_control(
	IDreg2loc,
	IDuncondbranch,
	IDbranch,
	IDmemread,
	IDmemtoreg,
	IDalu_sel,
	IDmemwrite,
	IDalusrc,
	IDregwrite,
	IFIDinstr[15:12]
	);
	
RegFile legv8_register(
	IDrdata1,
	IDrdata2,
	clock,
	dmemwdata,
	{IFIDinstr[2:0]},
	{IFIDinstr[5:3]},
	radd2[2:0],
	regwrite
	);
	
MUX2 reg2loc_mux(
	radd2,
	{{13'd0},IFIDinstr [11:9]},
	{{13'd0},IFIDinstr [2:0]},
	reg2loc_mux
	);
	


Control
	
//------- ID/EX register ----------


//------- EX stage ----------------


//------- EX/MEM register ----------


//------- MEM Stage ----------------


//------- MEM/WB pipeline register ----


//------- WB Stage ------------------

//------- DEBUGG PROBE --------------
	
endmodule

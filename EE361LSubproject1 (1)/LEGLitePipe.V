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
	if (reset==1 || controller_state=='b11)
		controller_state <= 0;
	else 
		controller_state <= controller_state + 1;
	end 

	
//------- IF stage ----------------
//ports
wire [15:0] pc_input, unbranched_add, IFbranch_add;
reg [15:0] IFcurrent_pc;

//adder for pc
assign unbranched_add = IFcurrent_pc + 2;

//MUX for pc increment
MUX2 pc_mux(
	pc_input,
	unbranched_add,
	IFbranch_add,
	pcBranchSrc
	);
	
//pc controller	(not sure)
always_ff@(posedge clock)
	begin
	if (reset==1)
		IFcurrent_pc <= 0;
      else if(controller_state == 3)
		IFcurrent_pc <=  pc_input;
    else
      	IFcurrent_pc <= IFcurrent_pc;
	end 

  assign  imemaddr = IFcurrent_pc;
//------- IF/ID register ----------
//ports
reg [15:0] IFIDinstr;
reg [15:0] IFIDpc;

//assign
always_ff @(posedge clock)
   begin
   IFIDinstr <= imemrdata;
   IFIDpc <= IFcurrent_pc;
   end


//------- ID stage ----------------
//wire through
wire [15:0] IDcurrent_pc;
wire [15:0] IDinstr;
assign IDcurrent_pc = IFcurrent_pc;
assign IDinstr = IFIDinstr; 

//Sign extension
wire [15:0] IDsignextension;
  assign IDsignextension[15:6] = {10{IFIDinstr[11]}};
  assign IDsignextension[5:0] = IFIDinstr[11:6];
  
//Controller
wire IDreg2loc;
wire IDuncondbranch;
wire IDbranch;
wire IDmemread;
wire IDmemtoreg;
wire [2:0] IDalu_sel;
wire IDmemwrite;
wire IDalusrc;
wire IDregwrite
wire oregwrite;

//reg
wire [15:0] IDrdata1;
wire [15:0] IDrdata2;
wire [15:0] IDwdataIn;
wire [15:0] radd2;

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
	IDwdataIn,
	{IFIDinstr[2:0]},
	{IFIDinstr[5:3]},
	radd2[2:0],
	oregwrite
	);
	
MUX2 reg2loc_mux(
	radd2,
	{{13'd0},IFIDinstr [11:9]},
	{{13'd0},IFIDinstr [2:0]},
	IDreg2loc
	);
	
//------- ID/EX register ----------
//controller ports
reg IDEXuncondbranch;
reg IDEXbranch;
reg IDEXmemread;
reg IDEXmemtoreg;
reg [2:0] IDEXalu_sel;
reg IDEXmemwrite;
reg IDEXalusrc;
reg IDEXregwrite;

//pc port
reg [15:0] IDEXcurrent_pc;

//registerfile port
reg [15:0]IDEXrdata1;
reg [15:0]IDEXrdata2;

//sigext port
reg [15:0]IDEXsigext;

always_ff @(posedge clock)
   begin
	//control wires
   IDEXuncondbranch <= IDuncondbranch;
   IDEXbranch <= IDbranch;
   IDEXmemread <= IDmemread;
   IDEXmemtoreg <= IDmemtoreg;
   IDEXalu_sel <= IDalu_sel;
   IDEXmemwrite <= IDmemwrite;
   IDEXalusrc <= IDalusrc;
   IDEXregwrite <= IDregwrite;
   //pass through
   IDEXcurrent_pc <= IDcurrent_pc;
   IDEXrdata1 <= IDrdata1;
   IDEXrdata2 <= IDrdata2;
   IDEXsigext <= IDsignextension;
   end

//------- EX stage ----------------
//wire for ex stage controller
wire EXuncondbranch;
wire EXbranch;
wire EXmemread;
wire EXmemtoreg;
wire [2:0] EXalu_sel;
wire EXmemwrite;
wire EXalusrc;
wire EXregwrite;
//Wires for ex stage ports
wire [15:0] EXcurrent_pc; 
wire [15:0] EXrdata1;
wire [15:0] EXrdata2;
wire [15:0] EXsigext;

//intermiate wire
wire [15:0 ]ALUinput2;

//Output wires
wire [15:0] EXalu_out;
wire EXalu_zout;

//branch_alu
wire [15:0] EXbranch_offset;
assign EXbranch_offset = EXcurrent_pc + (EXsigext << 1);

//assign controller
assign EXuncondbranch = IDEXuncondbranch;
assign EXbranch = IDEXbranch;
assign EXmemread = IDEXmemread;
assign EXmemtoreg = IDEXmemtoreg;
assign EXalu_sel = IDEXalu_sel;
assign EXmemwrite = IDEXmemwrite;
assign EXalusrc = IDEXalusrc;
assign EXregwrite = IDEXregwrite;
//EX wires
assign EXcurrent_pc = IDEXcurrent_pc;
assign EXrdata1 = IDEXrdata1;
assign EXrdata2 = IDEXrdata2;
assign EXsigext = IDEXsigext;

MUX2 alusrc_mux(
	ALUinput2,
	EXrdata2,
	EXsigext,
	EXalusrc
);

ALU mainALU(
	EXalu_out,
	EXalu_zout,
	EXrdata1,
	ALUinput2,
	EXalu_sel
);
 assign aluresult = EXalu_out;

//------- EX/MEM register ----------
//controller regs
reg EXMEMuncondbranch;
reg EXMEMbranch;
reg EXMEMmemread;
reg EXMEMmemtoreg;
reg EXMEMmemwrite;
reg EXMEMregwrite;
//pc reg
reg [15:0] EXMEMcurrent_pc;
//alu
reg [15:0]EXMEMalu_out;
reg EXMEMalu_zout;
//sigext reg
reg [15:0] EXMEMbranch_offset;
//instruction
reg [15:0] EXMEMinstr;
reg [15:0] EXMEMrdata2;

always_ff @(posedge clock)
	begin
	//Control wires
	EXMEMuncondbranch <= EXuncondbranch;
	EXMEMbranch <= EXbranch;
	EXMEMmemread <= EXmemread;
	EXMEMmemtoreg <= EXmemtoreg; 
	EXMEMmemwrite <= EXmemwrite; 
	EXMEMregwrite <= EXregwrite;
	//wire through 
	EXMEMcurrent_pc <= EXcurrent_pc; // not in use, no branch with link
	EXMEMalu_out <= EXalu_out;
	EXMEMalu_zout <= EXalu_zout;
	EXMEMrdata2 <= EXrdata2;
	EXMEMbranch_offset <= EXbranch_offset;
	end

//------- MEM Stage ----------------
//Wires from previous stage
//controller part
wire MEMuncondbranch;
wire MEMbranch;
wire MEMmemread;
wire MEMmemtoreg;
wire MEMmemwrite;
wire MEMregwrite;
//other wires
wire [15:0]MEMalu_out;
wire MEMalu_zout;
wire [15:0] MEMrdata2;

assign MEMuncondbranch = EXMEMuncondbranch;
assign MEMbranch = EXMEMbranch;
assign MEMmemread = EXMEMmemread;
assign MEMmemtoreg = EXMEMmemtoreg;
assign MEMmemwrite = EXMEMmemwrite;
assign MEMregwrite = EXMEMregwrite;
//assign MEMcurrent_pc = EXMEMcurrent_pc; 	not in use, no branch with link
assign MEMalu_out = EXMEMalu_out;
assign MEMalu_zout = EXMEMalu_zout;
assign MEMrdata2 = EXMEMrdata2;
assign IFbranch_add = EXMEMbranch_offset;

//Assign mem
assign dmemwrite = MEMmemwrite;
assign dmemread = MEMmemread;
assign dmemaddr = MEMalu_out;
assign dmemwdata = MEMrdata2;

//MAYBE MAKE ALWAYS COMB??????????????????
logic pcBranchSrc;
assign pcBranchSrc = ((MEMbranch && MEMalu_zout) || MEMuncondbranch);

//------- MEM/WB pipeline register ----
reg MEMWBmemtoreg;
reg [15:0] MEMWBmemrdata;
reg [15:0] MEMWBalu_out;
reg MEMWBregwrite;

always_ff @(posedge clock)
	begin
	MEMWBmemtoreg <= MEMmemtoreg;
	MEMWBmemrdata <= dmemrdata;
	MEMWBalu_out <= MEMalu_out;
	MEMWBregwrite <= MEMregwrite;
	end

//------- WB Stage ------------------
wire WBmemtoreg;
wire [15:0] WBmemrdata;
wire [15:0] WBalu_out;

assign WBmemtoreg = MEMWBmemtoreg;
assign WBmemrdata = MEMWBmemrdata;
assign WBalu_out = MEMWBalu_out;
assign oregwrite = MEMWBregwrite;

MUX2 mem2reg_mux(
	IDwdataIn,
	MEMWBalu_out,
	dmemwdata,
	WBmemtoreg 
);


//------- DEBUGG PROBE --------------
  assign probe = { IDregwrite,10'b0, MEMWBalu_out[4:0],  EXmemtoreg};		
  //assign probe = EXsigext;
endmodule


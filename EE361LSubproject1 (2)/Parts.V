// 16-bit MIPS Parts
// 
// * Data Memory and IO:  This is the data memory, and some IO hardware
// * 8x16 register file:  eight 16-bit registers
// * 16-bit ALU
// * 2:1 16-bit Multiplexer
// * 4:1 16-bit Multiplexer

//----------------------------------------------------------
// Data Memory and IO
// The data memory is 128 16-bit words.  The addresses are
// 0, 2, 4, ...., 254.  Note that the address of words are 
// divisible by 2 (memory is byte addressable and big endian).
// This module also has some hardware for IO.  In particular,
// There are three ports:
//
//     Address	Type		What's it connected to
//     0xfffa	Output	Seven segment display
//     0xfff0	Input		Switches sw1 and sw0
//
// Output port 0xfffa is connected to an 7-bit register. So
// when storing a word "w" to the port, the value
// w[6:0] gets stored in the port's register.  The output
// of this register is connected to a seven segment display.
// The display has pin names
//
//    -a-
//   f   b
//    -g-
//   e   c
//    -d-
//
// and (a,b,c,d,e,f,g) = (w[6],w[5],....w[0]).  For example,
// to display the number "5", then w = (1,0,1,1,0,1,1).
//
// The input port 0xfff0 is connected to switches sw1 and sw0.  
//
// After reading a word "w" from the port, then
//    w[1] = sw1, w[0] = sw0.
//
module DMemory_IO(
     output logic [15:0] rdata,  // read data
     output logic [6:0] io_display, // IO port connected to 7 segment display
     input logic clock,  // clock
     input logic [15:0] addr,   // address
     input logic [15:0] wdata,  // write data
     input logic write,  // write enable
     input logic read,   // read enable
     input logic io_sw0, // IO port connected to sliding switch 0
     input logic io_sw1  // IO port connected to sliding switch 1
     );
		

reg [15:0] memcell[0:127]; // 128 half-words for memory

// This is basically a multiplexer, that chooses to output the
// memory or IO.  
always_comb
	begin
	if (read == 0) rdata = 0;
	else // read = 1
		begin
		if (addr >= 0 && addr < 256) 
               rdata = memcell[addr[7:1]]; 
		else if (addr == 16'hfff0) 		
               rdata = {14'd0,io_sw1,io_sw0};
		else rdata = 0; // default 
		end
	end

// IO port 0xfffa that is connected to the seven segment display.
always_ff @(posedge clock)
	if (write == 1 && addr == 16'hfffa) 
         io_display <= wdata[6:0];

// Note that if waddr[15:0] = 0 
//   then 0 <= waddr < 256 and one of the
// 256 memory cells is being accessed
always_ff @(posedge clock)
     if (write == 1 && addr>= 0 && addr < 256) 
          memcell[addr[7:1]] <= wdata;

endmodule

//----------------------------------------------------------
// 8x16 Register File
module RegFile(
     output logic [15:0] rdata1,  // read data output 1
     output logic [15:0] rdata2,  // read data output 2
     input logic clock,		
     input logic [15:0] wdata,   // write data input
     input logic [2:0] waddr,   // write address
     input logic [2:0] raddr1,  // read address 1
     input logic [2:0] raddr2,  // read address 2
     input logic write    // write enable
     );			

reg [15:0] regcell[0:7];		// Eight registers

// Writing to a register
always_ff @(posedge clock) 
     if (write==1) regcell[waddr]<=wdata;

// Reading from a register
always_comb
     begin
     if (raddr1 == 7) 	rdata1 = 0;
     else rdata1 = regcell[raddr1];
     end

// Reading from a register
always_comb
     begin
     if (raddr2 == 7) 	rdata2 = 0;
     else rdata2 = regcell[raddr2];
     end

endmodule

//----------------------------------------------------------
// ALU
// 
// Function table
// select	function
// 0		add
// 1		subtract
// 2		pass through 'indata1' to the output 'result'
// 3		or
// 4		and
//
module ALU(
     output logic [15:0] result, // 16-bit output from the ALU
     output logic zero_result, // equals 1 if the result is 0, and 0 otherwise
     input logic [15:0] indata0,     // data input
     input logic [15:0] indata1,     // data input
     input logic [2:0] select       // 3-bit select
     );		

always_comb
	case(select)
	0: result = indata0 + indata1;
	1: result = indata0 - indata1;
	2: result = indata1;
	3: result = indata0 | indata1;
	4: result = indata0 & indata1;
	default: result = 0;
	endcase

always_comb // This is basically a NOR operation
	if (result == 0) 	zero_result = 1;
	else 			  	zero_result = 0;

endmodule

//----------------------------------------------------------
// 2:1 Multiplexer

module MUX2(
     output logic [15:0] result,   // Output of multiplexer
     input logic [15:0] indata0,  // Input 0
     input logic [15:0] indata1,  // Input 1
     input logic select    // 1-bit select
     );	

always_comb
	case(select)
	0: result = indata0;
	1: result = indata1;
	endcase

endmodule

//----------------------------------------------------------
// 4:1 Multiplexer
module MUX4(
     output logic [15:0] result, // 16 bit output
     input logic [15:0] indata0, // Input 0
     input logic [15:0] indata1, // Input 1
     input logic [15:0] indata2, // Input 2
     input logic [15:0] indata3, // Input 3
     input logic [1:0] select    // 2-bit select input
     );	

always_comb
	case(select)
	0: result = indata0;
	1: result = indata1;
	2: result = indata2;
	3: result = indata3;
	endcase

endmodule



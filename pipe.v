//EE480 Team 12 Assignment 3


//-------------------------DEFINITIONS-------------------------------
// Definitions from Madison's old group; modify as needed
`define STATE    [4:0]
`define TEXT     [15:0]
`define DATA     [31:0]
`define REGSIZE  [63:0]					//Changed to 64 bit.
`define CODESIZE [65535:0]
`define MEMSIZE  [65535:0]

`define WORD	 [15:0]
`define OP		 [4:0]


// field locations within instruction
`define Opcode   [15:12]
`define Dest     [11:8]
`define Src      [7:4]
`define Arg      [3:0]
`define Imm      [7:0]


// opcode and state number             
`define OPadd    4'b0000
`define OPaddv   4'b0001
`define OPand    4'b0010
`define OPor     4'b0011
`define OPxor    4'b0100
`define OPshift  4'b0101
`define OPpack   4'b0110
`define OPunpack 4'b0111
`define OPli     4'b1000
`define OPmorei  4'b1001
`define OPany    4'b1010
`define OPanyv   4'b1011
`define OPneg    4'b1100
`define OPnegv   4'b1101
`define OPsys    4'b1110
`define OPextra  4'b1111


// state numbers only for extra opcodes
`define OPst     5'b10000
`define OPld     5'b10001
`define OPjnz    5'b10010
`define OPjz     5'b10011
`define OPnop    5'b10100
`define Start    5'b11111
`define Start1   5'b11110


// arg field values for extra opcodes
`define EXst     4'b0001
`define EXld     4'b0010
`define EXjnz    4'b0011
`define EXjz     4'b0100
`define EXnop    4'b1111


// field locations for vector ops
`define V1       [7:0]
`define V2       [15:8]
`define V3       [23:16]
`define V4       [31:24]


//`define PC		 1'b1


// mask for cutting carry chains
`define MASKaddv 32'h80808080

module processor(halt, reset, clock);

initial begin
   $dumpfile;
   $dumpvars(buf1op);
end

    output reg halt;
    input      reset, clock;
   
    reg `TEXT codemem `CODESIZE;
    reg `DATA mainmem `MEMSIZE;
    reg signed `DATA regfile `REGSIZE;
   
    reg `WORD ir, src, dest;
    //PC is program counter, PCjmp is the pc address to jump to
    reg [15:0] PC, PCjmp, PCnext;
    
    //reg `STATE s = `Start;
  
    wire [3:0] decop, decd, decs, dect;

  	reg [3:0] buf1op, buf1dadr, buf1sadr, buf1tadr;
  	reg [7:0] buf1im, buf1flag;

    //Flag Encoding: ValFwd: 0-no, 1-yes; 
  	reg [3:0] buf2op, buf2dval, buf2sval, buf2tval;
  	reg [7:0] buf2im, buf2flag;
  
  	reg [3:0] buf3op, buf3dadr;
  	reg [7:0] buf3mem, buf3im, buf3flag;
        wire [3:0] buf3dval;

    wire `OP op;
   
    //RESET Procedure
    always @(reset) begin
       $readmemh0(mainmem);
       $readmemh1(regfile);
       $readmemh2(codemem);

       halt = 0;
       PC = 0;      
       //s = `Start

        buf1op = `OPnop;
        buf2op = `OPnop;
        buf3op = `OPnop;

       $display("processor reset");
	end

    decode d(ir, opbits, Dbits, Sbits, Tbits, Immbits);
	alu a(, buf2op, buf2sval, buf2tval);

    always @(*) ir = mainmem[PC];
    
    always @(*) begin
        if(buf3dadr == buf1sadr)
            buf1flag = buf1flag | 8'b10000000;
        
        else if(buf3dadr == buf1tadr)
            buf1flag = buf1flag | 8'b01000000;
        
        if(buf2dval == buf1sadr)
            buf1flag = buf1flag | 8'b11000000;
        
        else if(buf2dval == buf1tadr)
            buf1flag = buf1flag | 8'b00100000;
    end
	
    //Get next PC value
    always @(*) begin
        if ((buf1op != `OPjz) && (buf1op != `OPjnz))
            PCnext = PC + 1;
        else if (buf1op == `OPjz)begin
            if (buf1sadr==0)
                PCnext = buf1tadr;
            else
                PCnext = PC + 1;
        end
        else begin
            if (buf1sadr!=0)
                PCnext = buf1tadr;
            else
                PCnext = PC + 1;
        end
    end
  
    //Fetch Instruction
  	always @(posedge clock) if (!halt) begin
    		buf1op <= opbits;
    		buf1dadr <= Dbits;
    		buf1sadr <= Sbits;
    		buf1tadr <= Tbits;
    		buf1im <= Immbits;
    		buf1flag <= 8'b00000000;
    		PC <= PCnext;
    	end
    
    //Read Register
  	always @(posedge clock) if (!halt) begin
  	       buf2op <= buf1op;
  	       buf2dval <= buf1dadr;
  	       if(buf1flag == 8'b1000000)
  	            buf2sval <= buf3dval;
  	       else
  	            buf2sval <= regfile[buf1sadr];
  	            
  	       if(buf1flag == 8'b01000000)
  	            buf2tval <= buf3dval;
  	       
  	       else
  	            buf2tval <= regfile[buf1tadr];
  	       buf2flag <= buf1flag;
  	    end
  	
  	//ALU Operation
  	always @(posedge clock) if (!halt) begin
  	        buf3dadr <= buf2dval;
  	        if(buf2flag == 8'b11000000)
  	            buf2sval <= buf3dval;
  	            
  	        else if(buf2flag == 8'b00100000)
  	            buf2tval <= buf3dval;
  	            
  	        buf3flag <= buf2flag;
  	    end
  	
  	//Write to Register
  	always @(posedge clock) if (!halt) begin
  	        regfile[buf3dadr] = buf3dval;
  	    end
endmodule


module decode(instr, opcode, D, S, T, imm);
    input `WORD instr;
    output reg `OP opcode;
    output reg [3:0] D, S, T;
    output reg `Imm imm;
    
    always @(*)begin
        if(instr `Opcode == `OPextra)
        begin
            D <= instr `Dest;
            S <= instr `Src;
        
            if(instr `Arg == `EXnop)
                opcode <= `OPnop;
            else if(instr `Arg == `EXst)
                opcode <= `OPst;
            else if(instr `Arg == `EXld)
                opcode <= `OPld;
            else if(instr `Arg == `EXjnz)
                opcode <= `OPjnz;
            else
                opcode <= `OPjz;
        end
        else if((instr `Opcode == `OPli)|(instr `Opcode == `OPmorei))begin
            opcode <= instr `Opcode;
            D <= instr `Dest;
            imm <= instr `Imm;
        end
        else begin
            opcode <= instr `Opcode;
            D <= instr `Dest;
            S <= instr `Src;
        end
    end
endmodule

module alu(bus_out, OP, a, b); //Got rid of clk since processor will handle time
   output reg `DATA bus_out;
   input  OP, en;
   input  signed    `DATA a, b;
   input   [3:0] ctrl;
   
    always begin @(*)      
      case(OP)
	`OPadd:    bus_out <= a + b;
	`OPaddv:   bus_out <= ((a & ~(`MASKaddv)) + (b & ~(`MASKaddv))) ^ ((a & `MASKaddv) ^ (b & `MASKaddv));
	`OPand:    bus_out <= a & b; 
	`OPany:    bus_out <= (a ? 1 : 0);
	`OPanyv: begin
	   bus_out[0]  <= (a & 32'h000000FF ? 1 : 0);
	   bus_out[8]  <= (a & 32'h0000FF00 ? 1 : 0);
	   bus_out[16] <= (a & 32'h00FF0000 ? 1 : 0);
	   bus_out[24] <= (a & 32'hFF000000 ? 1 : 0);
	end
	`OPor:     bus_out <= a | b;
	`OPxor:    bus_out <= a ^ b;
	`OPneg:    bus_out <= -a;
	`OPnegv: begin
	   bus_out `V1 <= -(a `V1);
	   bus_out `V2 <= -(a `V2);
	   bus_out `V3 <= -(a `V3);
	   bus_out `V4 <= -(a `V4);
	end
	`OPshift: begin
	   bus_out <= ( (b < 0) ? (a >> -b) : (a << b) );
	end
      endcase // case (ctrl)   
   end
endmodule // alu

module testbench();
reg reset = 0;
reg clk = 0;
wire halted;
processor PE(halted, reset, clk);
initial begin
  #10 reset = 1;
  #10 reset = 0;
  while (!halted) begin
    #10 clk = 1;
    #10 clk = 0;
  end
  $finish;
end
endmodule
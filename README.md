# Multicycle-Implementation-of-slightly-parallel-processor
UK CS480 - Advanced Computer Architecture : Project 2 - multi-cycle Verilog implementation of loQ Don

Assignment 2: chenmoH loQ Don Qapla'!

nuqneH?

Well, what I want is for your team to build a multi-cycle Verilog implementation of loQ Don, our slightly parallel target machine.

In this project, you'll be determining how to encode the loQ Don instruction set, building an AIK assembler that embodies that coding (wait a second... you all just did that!), creating a multi-cycle implementation of the processor and memory, and testing it with some attention paid to test coverage. That's a lot, so you're not doing it alone, but in teams of 3-4 students. Let's take it one step at a time... which is also how you should do it.

Top Down

I said it in class, but let me repeat it here: you're going to be building a fairly complex collection of stuff. You'll never get it all working unless you're pretty methodical about the development process... which I'm strongly recommending should be top down.

Before doing anything, look at the instruction set. Think about what kind of hardware structures you're going to need to implement each type of instruction. Remember those high-level processor architecture diagrams in EE380? Well, you want to think a bit about what one of those would look like for your IDIOT processor. In fact, your multi-cycle design will probably look a lot like the Simple Processor Architecture from EE380, although there will be various simplifications (e.g., you don't need a MFC line because you can assume your memory completes an access in one cycle). Remember how we built-up that design in EE380 by going through the instruction set and incrementally adding whatever was needed to implement each instruction? Think about this project the same way.

Am I saying you need to draw one of those diagrams right at the start of the project? Not at all. What I'm saying is that you should always have in the back of your head roughly what the big picture is expected to look like. As you think about each instruction, think about what hardware will be involved in executing it and what types of control signals and datapaths will be needed. What things seem hard to do (the fancy title for this is "identify technological risk factors")? Make little notes to yourself. Discuss these things in your team. Make the big or confusing decisions as a team -- and document the non-obvious things in your Implementor's Notes.

Encoding Instructions

The loQ Don ISA contains 20 instructions, described here. They're pretty straightforward except maybe for the vector instructions. Each instruction is to be one 16-bit word long, with no exceptions... you know, like you just did in the previous project. The catch is that now you might want to rethink the encoding to try to simplify your Verilog implementation. You should discuss that within your team.

For example, think about the MIPS instruction set encoding discussed in EE380; remember how the lw and sw instructions used the same instruction field for specifying the register that holds the base memory address? That's the kind of logic you want to apply here. For example, ld $d,$s and any $d,$s should probably use the same instruction bit field to encode $d... or maybe not? The correct answer is whatever field assignment is most convenient for you to implement, which might or might not be the same field arrangements or values any of your team members used in the previous assignment (or that I used in the assembler sample solution given below). It's all up to you.

Now you're probably getting nervous about the encoding choices. Don't be. Unlike the real world, in this class you can always change your mind if you later discover your instruction encoding was awkward. It should also be understood that many different encodings are comparably good, so don't be nervous if you hear that somebody else did things differently... you really can both be equally right. Still nervous? Explaining any nervousness-inducing decisions you made in your Implementor's Notes should help you feel better. ;-)

The Assembler

Once you've designed your instruction set encoding, you need a rigorous way of expressing the encoding. What better way to document it than to build an assembler using AIK? The AIK specification of the assembler is essentially executable documentation of the instruction encoding. Modifying one of the solutions to the previous project should be quite easy... in fact, if you decide to use one of those directly, you might not even need to modify the AIK specification at all. Here are my two sample solutions that we discussed in class.

First, the obviously coded one (and I encourage this type of clarity):

nop			:=	0x0:4	0x0:4	0x0:4	0x0:4
and	$.d, $.s, $.t	:=	0x0:4	.d:4	.s:4	.t:4
or	$.d, $.s, $.t	:=	0x1:4	.d:4	.s:4	.t:4
xor	$.d, $.s, $.t	:=	0x2:4	.d:4	.s:4	.t:4
add	$.d, $.s, $.t	:=	0x4:4	.d:4	.s:4	.t:4
addv	$.d, $.s, $.t	:=	0x5:4	.d:4	.s:4	.t:4
shift	$.d, $.s, $.t	:=	0x7:4	.d:4	.s:4	.t:4

pack	$.d[.p], $.s	:=	0x8:4	.d:4	.s:4	.p:4
unpack	$.d, $.s[.p]	:=	0x9:4	.d:4	.s:4	.p:4

li	$.d, .immed8	:=	0xa:4	.d:4	.immed8:8
morei	$.d, .immed8	:=	0xb:4	.d:4	.immed8:8

ld	$.d, $.s	:=	0xe:4	.d:4	.s:4	0x0:4
any	$.d, $.s	:=	0xe:4	.d:4	.s:4	0x2:4
anyv	$.d, $.s	:=	0xe:4	.d:4	.s:4	0x3:4
neg	$.d, $.s	:=	0xe:4	.d:4	.s:4	0x4:4
negv	$.d, $.s	:=	0xe:4	.d:4	.s:4	0x5:4

st	$.s, $.t	:=	0xf:4	0:4	.s:4	.t:4
jz	$.s, $.t	:=	0xf:4	2:4	.s:4	.t:4
jnz	$.s, $.t	:=	0xf:4	3:4	.s:4	.t:4
sys			:=	0xf:4	0xf:4	0xf:4	0xf:4

.const	zero pc sp fp ra rv u0 u1 u2 u3 u4 u5 u6 u7 u8 u9
.segment .text 16 0x10000 0 .VMEM
.segment .data 32 0x10000 0 .VMEM
.const 0 .lowfirst
Second, here is a version written as somewhat denser AIK, but using the same encoding. However, I've also added a li32 pseudo-instruction to emit from 1-4 instructions minimally loading a 32-bit immediate value.

nop			:=	0:16
.dst	$.d, $.s, $.t	:=	.this:4	.d:4	.s:4	.t:4
.alias	.dst 0 and or xor 4 add addv 7 shift
pack	$.d[.p], $.s	:=	0x8:4	.d:4	.s:4	.p:4
unpack	$.d, $.s[.p]	:=	0x9:4	.d:4	.s:4	.p:4
.di	$.d, .i		:=	.this:4	.d:4	.i:8
.alias	.di 0xa li morei
.ds	$.d, $.s	:=	0xe:4	.d:4	.s:4	.this:4
.alias	.ds 0 ld 2 any anyv neg negv
.st	$.s, $.t	:=	0xf:4	.this:4	.s:4	.t:4
.alias	.st 0 st 2 jz jnz
sys			:=	-1:16
.const	zero pc sp fp ra rv u0 u1 u2 u3 u4 u5 u6 u7 u8 u9
.segment .text 16 0x10000 0 .VMEM
.segment .data 32 0x10000 0 .VMEM
.const 0 .lowfirst

li32	$.d, .i	?(((.i&0xffffff80)==0xffffff80)||((.i&0xffffff80)==0)) := {
	li:4	.d:4	.i:8 }
li32	$.d, .i	?(((.i&0xffff8000)==0xffff8000)||((.i&0xffff8000)==0)) := {
	li:4	.d:4	(.i>>8):8
	morei:4	.d:4	.i:8 }
li32	$.d, .i ?(((.i&0xff800000)==0xff800000)||((.i&0xff800000)==0)) := {
	li:4	.d:4	(.i>>16):8
	morei:4	.d:4	(.i>>8):8
	morei:4	.d:4	.i:8 }
li32	$.d, .i	:= {
	li:4	.d:4	(.i>>24):8
	morei:4	.d:4	(.i>>16):8
	morei:4	.d:4	(.i>>8):8
	morei:4	.d:4	.i:8 }
The Verilog Hardware Design

I bet a lot of you are scared of this. You should be; it could be a huge mess. The trick is to never let it become a huge mess by sticking to that top down structured design discipline.

This design problem is not entirely new for you, but the design work you did in EE380 skipped a lot of implementation details that you cannot skip here. Still, think about things as you were told to in EE380. Step through what each instruction needs to do and logically build-up that big picture of the implementation architecture. Think about what function units, data paths, and control signals you will need. Do this before writing Verilog definitions of any piece. In fact, write it up in your implementor's notes before you write Verilog code.

When you think you're nearly ready to start writing Verilog code, recall that in lecture I showed you a sample solution for the Spring 2016 semester instruction set (IDIOT, as described in this Spring 2016 project handout):

// basic sizes of things
`define WORD	[15:0]
`define Opcode	[15:12]
`define Dest	[11:6]
`define Src	[5:0]
`define STATE	[4:0]
`define REGSIZE [63:0]
`define MEMSIZE [65535:0]

// opcode values, also state numbers
`define OPadd	4'b0000
`define OPinvf	4'b0001
`define OPaddf	4'b0010
`define OPmulf	4'b0011
`define OPand	4'b0100
`define OPor	4'b0101
`define OPxor	4'b0110
`define OPany	4'b0111
`define OPdup	4'b1000
`define OPshr	4'b1001
`define OPf2i	4'b1010
`define OPi2f	4'b1011
`define OPld	4'b1100
`define OPst	4'b1101
`define OPjzsz	4'b1110
`define OPli	4'b1111

// state numbers only
`define OPjz	`OPjzsz
`define OPsys	5'b10000
`define OPsz	5'b10001
`define Start	5'b11111
`define Start1	5'b11110

// source field values for sys and sz
`define SRCsys	6'b000000
`define SRCsz	6'b000001

module processor(halt, reset, clk);
output reg halt;
input reset, clk;

reg `WORD regfile `REGSIZE;
reg `WORD mainmem `MEMSIZE;
reg `WORD pc = 0;
reg `WORD ir;
reg `STATE s = `Start;
integer a;

always @(reset) begin
  halt = 0;
  pc = 0;
  s = `Start;
  $readmemh0(regfile);
  $readmemh1(mainmem);
end

always @(posedge clk) begin
  case (s)
    `Start: begin ir <= mainmem[pc]; s <= `Start1; end
    `Start1: begin
             pc <= pc + 1;            // bump pc
	     case (ir `Opcode)
	     `OPjzsz:
                case (ir `Src)	      // use Src as extended opcode
                `SRCsys: s <= `OPsys; // sys call
                `SRCsz: s <= `OPsz;   // sz
                default: s <= `OPjz;  // jz
	     endcase
             default: s <= ir `Opcode; // most instructions, state # is opcode
	     endcase
	    end

    `OPadd: begin regfile[ir `Dest] <= regfile[ir `Dest] + regfile[ir `Src]; s <= `Start; end
    `OPand: begin regfile[ir `Dest] <= regfile[ir `Dest] & regfile[ir `Src]; s <= `Start; end
    `OPany: begin regfile[ir `Dest] <= |regfile[ir `Src]; s <= `Start; end
    `OPdup: begin regfile[ir `Dest] <= regfile[ir `Src]; s <= `Start; end
    `OPjz: begin if (regfile[ir `Dest] == 0) pc <= regfile[ir `Src]; s <= `Start; end
    `OPld: begin regfile[ir `Dest] <= mainmem[regfile[ir `Src]]; s <= `Start; end
    `OPli: begin regfile[ir `Dest] <= mainmem[pc]; pc <= pc + 1; s <= `Start; end
    `OPor: begin regfile[ir `Dest] <= regfile[ir `Dest] | regfile[ir `Src]; s <= `Start; end
    `OPsz: begin if (regfile[ir `Dest] == 0) pc <= pc + 1; s <= `Start; end
    `OPshr: begin regfile[ir `Dest] <= regfile[ir `Src] >> 1; s <= `Start; end
    `OPst: begin mainmem[regfile[ir `Src]] <= regfile[ir `Dest]; s <= `Start; end
    `OPxor: begin regfile[ir `Dest] <= regfile[ir `Dest] ^ regfile[ir `Src]; s <= `Start; end

    default: halt <= 1;
  endcase
end
endmodule
Don't try to copy and edit that Verilog code; loQ Don is (very deliberately) too different from last semester's IDIOT. However, nothing you're doing requires a solution that is much more complex than the above. If you think your solution needs to be significantly more complex, you're not yet ready to start writing Verilog code: design first, code second.

Structuring Your Verilog Code

As I did in the sample above and suggested in class, I strongly suggest that you think in terms of writing definitions of control signals and dummy top-level modules (with their output and input specifications). I very much like the idea of having an abstracted list of control signal definitions using `define. By consistently using things like `WORD instead of [31:0], the Verilog hardware description becomes just a little more abstract; you no longer have to ask yourself if something that says [31:0] is a 32-bit word or if it is a collection of other things that just happens to also be 32 bits. The same benefit happens by using `Opadd instead of 4'b0000, but you also get three more benefits:

As I did above, directly deriving the control signals and state numbers from the instruction opcode can greatly simplify things. Of course, you can't just use the 4-bit opcode field for loQ Don because there are 20 different types of instructions, but you can create a virtual opcode by combining the instruction opcode field and some other field data -- as I did in the IDIOT example above, where I made a virtual 5-bit opcode value to distinguish OPjz, OPsys, and OPsz.
If you decide to make the ALU a separate module (which I didn't do above, but might be a good thing to do to simplify testing), you know that the module implementing the ALU will understand the same control signal the same way as any module that instantiates an ALU.
Knowing the complete set of ALU operations and their encoding becomes a fairly detailed specification of what your ALU must implement. This little header of `defines is really a both a design specification and a part of the design implementation.
In summary, in lectures you got a fairly detailed overview of how to go about designing hardware for a complete computer system. The bottom line is that you should start by defining the set of function units, data paths, and control signals you will need. Define the interfaces and signals. Then build the modules themselves. Note also that for this project, you are allowed to use things like the Verilog + operator to build an adder: you need synthesizable Verilog, but you don't have to specify things at any particular level.

How Many Modules Should There Be?

Well, it isn't too difficult to build the entire processor as a single module -- as I did above. However, that makes the Verilog code harder to test and debug. It also makes it much harder to reuse pieces of it in the next project, which will be a pipelined implementation of loQ Don. Worse still, if we were rendering the design to an FPGA or ASIC, it is quite possible that a single-module version of the Verilog code will generate unnecessarily complex hardware. This can happen by the compiler failing to factor function units (e.g., creating multiple ALUs when one would suffice) or, even more often, by implementing memories at the gate level because the Verilog compiler failed to recognize that your memory could be implemented using a standard memory structure. Still, how many modules you make is entirely up to you.

The thing you're most likely to want as a separate module is the ALU. Why? Well, how do you implement the SWAR vector operations like addv? Remember that you should always build the critical, but technologically risky, modules first. To help you with this, let's walk through implementing addv.

Implementing add is really simply done by something like:

regfile[d] <= regfile[s] + regfile[t];
However, addv treats regfile[d] as a vector of four 8-bit results. Thus, addv could be:

tmp0 = regfile[s][7:0] + regfile[t][7:0];
tmp1 = regfile[s][15:8] + regfile[t][15:8];
tmp2 = regfile[s][23:16] + regfile[t][23:16];
tmp3 = regfile[s][31:24] + regfile[t][31:24];
regfile[d] <= { tmp3, tmp2, tmp1, tmp0 };
That's fairly obvious Verilog code, but the Verilog compiler will probably not be smart enough to share circuitry between the 32-bit adder and the four 8-bit adders. It seems like we would have to design our own adder to be able to break the carry chain at the right spots...? However, instead, we can use a little trick. To break the carry chain, all we have to do is to zero the top bit of every field before adding and then add them in using an add without carry (which is XOR). Here's one way that can be done:

mask = 0x80808080;
regfile[d] <= ((regfile[s] & ~mask) + (regfile[t] & ~mask)) ^
              ((regfile[s] & mask) ^ (regfile[t] & mask));
Don't see how that works? Well, that sounds like a good reason to build and test a module for it before getting too far into your Verilog coding.

So, which modules should you build first? Well, you'll get more done earlier if you do the easy ones first. Of course, a project that correctly implements some instructions is worth more than one that incorrectly implements all. So, do what you must to learn how to build the critical, but technologically risky, stuff, then complete your design and build the modules your design specifies.

Test Plan

As we discussed in class, testing a complex piece of hardware is a lot more difficult than simply enumerating all input values and comparing circuit outputs to those of an oracle (correct reference) computation. Your project needs to include a test plan (best described in your Implementor's Notes) as well as a testbench implementing the planned test procedure.

In class, we distinguished testing correctness of the design from testing correct operation of an implementation of the design. For this project, you do not need to worry about implementation test issues: i.e., your test plan does not need to target identification of faults caused by faulty manufacture, timing issues, etc. Neither do you need to "design for testability" in this project -- for example, you don't need to insert scan access paths for internal state that would otherwise be unobservable in the circuit implementation. What you need to do is develop a test plan that will give good certainty that your design itself is logically, functionally, correct.

In class, we discussed the covered test coverage tool, the metrics it collects, and what should be considered acceptable coverage values. Fundamentally, the most important type of coverage for this project is that every circuit path (every Verilog statement) should be used in some test case. You need not use the covered tool, nor its version embedded in this course's Verilog WWW form interface, to perform the coverage analysis, but you should provide some explanation in your Implementor's Notes of how your suite of test cases covers approximately 100% of all statements (lines of Verilog). You may (should) assume that built-in Verilog structures and operators, such as +, are operating correctly without exhaustively testing them... but implementations of things like addv probably require some test cases.

The testbench you create to implement your test plan should look a lot like the testbench you wrote for Assignment 0, except:

You may find it impractical to have a separate oracle computation module, instead simply writing Verilog code that directly embeds the manually-determined correct values to compare with. There is nothing wrong with you explictly comparing that an add instruction that was supposed to add 1 + 3 really does equal the constant 4 in your testbench.
Ideally, you should have a single module testbench that tries all the test cases as a single large test sequence -- e.g., a single loQ Don test program. However, it may be simpler for you to write a separate module to perform each test case, and that is acceptable for this project. If you take the multiple-module test approach, you may submit each test module in a separate file such that simply catenating a test module file on the end of your design file will produce the complete Verilog code to test that case. Alternatively, you could have a single module testbench that invokes your individual test modules in sequence, but beware that writing your testbench in that style easily can result in multiple instances of your design being created by the Verilog interpreter, which can be very slow. Be sure to document how your test plan should be executed in your Implementor's Notes.
Note that the online Verilog WWW interface now allows use of $readmem directives, so it is much simpler to use that mechanism to initialize memory for your test cases. Include any such files in your submission as files with names ending in .vmem (to indicate that they are Verilog memory initialization files).


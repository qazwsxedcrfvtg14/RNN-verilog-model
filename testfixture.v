`timescale 1ns/10ps
`define CYCLE      3.8                   // Modify your clock period here
`define SDFFILE    "./layout/RNN_APR.sdf"	  // Modify your sdf file name
`define End_CYCLE  10000000000              // Modify cycle times once your design need more cycle times!

`define X_T            "./data/input1_hex.dat"                   // Modify your "data" directory path
`define W_IH           "./data/weight_ih1_hex.dat"
`define W_HH           "./data/weight_hh1_hex.dat"     
`define B_IH           "./data/bias_ih1_hex.dat"     
`define B_HH           "./data/bias_hh1_hex.dat"     
`define H_T            "./data/golden1_hex.dat"  

module testfixture;

parameter L_INPUT = 32;
parameter L_HIDDEN = 64;
parameter L_TIME = 200;
parameter L_IH = L_INPUT * L_HIDDEN;
parameter L_HH = L_HIDDEN * L_HIDDEN;
parameter L_HT = L_HIDDEN * L_TIME;
parameter LEN = 20'd200;

reg  [L_INPUT-1:0] X_T   [0:L_TIME-1];
reg         [19:0] W_IH  [0:L_IH-1];  
reg         [19:0] W_HH  [0:L_HH-1]; 
reg         [19:0] B_IH  [0:L_HIDDEN-1]; 
reg         [19:0] B_HH  [0:L_HIDDEN-1]; 
reg         [19:0] H_T   [0:L_HT-1];
reg         [19:0] Y_T   [0:L_HT-1];

reg             reset = 0;
reg             clk = 0;
reg             ready = 0;

wire            i_en;
wire            mce;
wire    [16:0]  maddr;
reg     [19:0]  mdata_r;
wire    [19:0]  mdata_w;
wire     [2:0]  msel;

reg     [11:0]  iaddr = 0;
reg     [L_INPUT-1:0]  idata;


integer		err_count, p1;
reg	        check_w=0;

`ifdef SDF
	initial $sdf_annotate(`SDFFILE, u_RNN);
`endif

RNN u_RNN(
			.clk(clk),
			.reset(reset),
			.busy(busy),
			.ready(ready),	
            .i_en(i_en),
			.idata(idata),
			.mdata_w(mdata_w),
			.mce(mce),
			.mdata_r(mdata_r),
			.maddr(maddr),
			.msel(msel)
			);
			


always begin #(`CYCLE/2) clk = ~clk; end

initial begin
	$dumpfile("RNN.vcd");
	$dumpvars;
	//$fsdbDumpMDA;
end

initial begin  // global control
	$display("-----------------------------------------------------\n");
 	$display("  START!!! Simulation Start .....\n");
 	$display("-----------------------------------------------------\n");
	@(negedge clk); #1; reset = 1'b1;  ready = 1'b1;
   	#(`CYCLE*3);  #1;   reset = 1'b0;  
   	wait(busy == 1); #(`CYCLE/4); ready = 1'b0;
end

initial begin // initial pattern and expected result
	wait(reset==1);
	wait ((ready==1) && (busy==0) ) begin
		$readmemh(`X_T, X_T );
		$readmemh(`W_IH,W_IH);
		$readmemh(`W_HH,W_HH);
		$readmemh(`B_IH,B_IH);
		$readmemh(`B_HH,B_HH);
		$readmemh(`H_T ,H_T );
	end
		
end

always@(negedge clk) begin // generate the stimulus input data
	#1;
    if((iaddr < L_TIME) && i_en) begin
        if((ready == 0) & (busy == 1)) begin
            idata = X_T[iaddr];
            iaddr = iaddr + 1;
        end
        else idata <= 'hx;
    end
    else begin
        iaddr = iaddr;
    end
end

always@(negedge clk) begin
	if (mce == 1) begin
		case(msel)
			3'b000: mdata_r <= W_IH[maddr[11:0]] ;
			3'b001: mdata_r <= B_IH[maddr[11:0]] ;
			3'b010: mdata_r <= W_HH[maddr[11:0]] ;
			3'b011: mdata_r <= B_HH[maddr[11:0]] ;
            3'b100: mdata_r <= LEN; 
			3'b101: begin check_w <= 1; Y_T[maddr] <= mdata_w; end
		endcase
	end
end



initial begin
check_w<= 0;
wait(busy==1); wait(busy==0);
if(check_w == 1) begin
	err_count = 0;
	for (p1=0; p1<L_HT; p1=p1+1) begin
		if (Y_T[p1] == H_T[p1]) ;
		else begin
			err_count = err_count + 1;
			begin 
				$display("WRONG! Position %d is wrong!", p1);
				$display("    The output data is %h, but the expected data is %h ", Y_T[p1], H_T[p1]);
			end
		end
	end
end
end


//-------------------------------------------------------------------------------------------------------------------
initial  begin
 #`End_CYCLE ;
 	$display("-----------------------------------------------------\n");
 	$display("Error!!! The simulation can't be terminated under normal operation!\n");
 	$display("-------------------------FAIL------------------------\n");
 	$display("-----------------------------------------------------\n");
 	$finish;
end

initial begin
    wait(busy == 1);
    wait(busy == 0);      
    $display(" ");
	$display("-----------------------------------------------------\n");
	$display("--------------------- S U M M A R Y -----------------\n");
	if( (check_w==1)&(err_count==0) ) $display("Congratulations! All data have been generated successfully! The result is PASS!!\n");
		else if (check_w == 0) $display("FAIL!!! No output data was found!! \n");
		else $display("FAIL!!!  There are %d errors! in Layer 1 \n", err_count);
	$display("-----------------------------------------------------\n");
      #(`CYCLE/2); $finish;
end



   
endmodule



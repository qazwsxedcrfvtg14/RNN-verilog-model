module RNN(clk,reset,busy,ready,i_en,idata,mdata_w,mce,mdata_r,maddr,msel);
input           clk, reset;
input           ready;
input    [31:0] idata;
input    [19:0] mdata_r;

output          busy;
output          i_en;
output          mce;
output   [16:0] maddr;
output   [19:0] mdata_w;
output    [2:0] msel;

// Please DO NOT modified the I/O signal
// TODO

`define PREC 36

integer i;

reg signed [19:0] h_old[0:63];
reg signed [19:0] h_tmp[0:63], tmp;
reg signed [(`PREC-1):0] h_new;
reg signed [10:0] mul_00, mul_01, mul_02, mul_03, mul_10, mul_11, mul_12, mul_13, mul_20, mul_21, mul_22, mul_23, mul_30, mul_31, mul_32, mul_33;
reg [31:0] x_data;

reg busy_sig;
reg i_en_sig;
//reg mce_sig;
reg [19:0] mdata_w_sig;
reg [2:0] msel_sig;
reg [16:0] maddr_sig;

reg [5:0] address;
reg [10:0] t_offset;
reg [5:0] h_offset;

reg inited;
reg initmem;

reg [2:0] stage;
reg next_stage;
reg [19:0] t_count;

reg carry_bit;


//reg signed [39:0] mul_tmp;

// base area: X = 500

// 64*64+64*32+64 cycle 64 mem 20*20 space
// cycle: 20bit_plus + 20bit_mul + 20bit_seq_plus ~= 20_mul
// (64*32+64*64+64)*(1)*(64+20*20+X) = 2880512 + 6208*500 => 5984512

// 64*64+64 cycle + 64*32+64+2048 mem 20*20 space
// cycle: 20bit_plus + 20bit_mul + 20bit_seq_plus ~= 20_mul
// (64*64+64)*(1)*(64*32+64+20*20+X) = 10449920 + 4160*500 => 12529920

// 64 cycle + 64*32+64*64+2048 mem 64*20*20 space
// cycle: 32_20bit_seq_plus + 64_20bit_pal_mul + 64_20bit_seq_plus ~= 4*20_mul
// (64)*(4)*(64*32+64*64+64+64*20*20+X) = 8142848 + 256*500 => 8270848

assign busy = busy_sig;
assign i_en = i_en_sig;
assign mce = busy_sig;
//assign mce = mce_sig;
assign mdata_w = mdata_w_sig;
assign msel = msel_sig;
assign maddr = maddr_sig;

always @(posedge clk ) begin
    busy_sig = inited & !reset & (ready | busy_sig);
    if (reset) begin
        inited = 1;
    end
    if (busy_sig) begin
        //mce_sig = 1;
        case (stage)
            0 : begin
                t_count = mdata_r;
                x_data = idata;
            end
            1 : begin
                h_new = h_new +
                    $signed(mul_00) +
                    $signed({mul_01,5'd0}) + $signed({mul_10,5'd0}) +
                    $signed({mul_02,10'd0}) + $signed({mul_11,10'd0}) + $signed({mul_20,10'd0}) +
                    $signed({mul_03,15'd0}) + $signed({mul_12,15'd0}) + $signed({mul_21,15'd0}) + $signed({mul_30,15'd0}) +
                    $signed({mul_13,20'd0}) + $signed({mul_22,20'd0}) + $signed({mul_31,20'd0}) +
                    $signed({mul_23,25'd0}) + $signed({mul_32,25'd0}) +
                    $signed({mul_33,30'd0});
                h_new[`PREC-1:16] = h_new[`PREC-1:16] + $signed(mdata_r);
            end
            2 : begin
                h_new[`PREC-1:16] = x_data[address] ? 
                    $signed(h_new[`PREC-1:16]) + $signed(mdata_r) : 
                    h_new[`PREC-1:16];
                if(!address) begin
                    carry_bit = h_new[(`PREC-1)] ? (h_new[15] & (|h_new[14:0]) ) : h_new[15];
                    h_new[`PREC-1:16] = h_new[`PREC-1:16] + carry_bit;
                    h_new[15:0] = 0;
                end
            end
            3 : begin
                if(address==1)begin
                    h_new[`PREC-1:16] = h_new[`PREC-1:16] + $signed(mdata_r);
                    if ((|h_new[`PREC-2:32])&!h_new[`PREC-1]) begin
                        tmp = 20'h10000;
                    end else if ((|(~h_new[`PREC-2:32]))&h_new[`PREC-1]) begin
                        tmp = 20'hf0000;
                    end else begin
                        tmp = h_new[35:16];
                    end
                end else begin
                    h_tmp[h_offset] = tmp;
                end
            end
            4 : begin
                if(h_offset==0) begin
                    x_data = idata;
                end
                mul_00 = 0;
                mul_01 = 0;
                mul_02 = 0;
                mul_03 = 0;
                mul_10 = 0;
                mul_11 = 0;
                mul_12 = 0;
                mul_13 = 0;
                mul_20 = 0;
                mul_21 = 0;
                mul_22 = 0;
                mul_23 = 0;
                mul_30 = 0;
                mul_31 = 0;
                mul_32 = 0;
                mul_33 = 0;
                h_new = 0;
            end
            5 : begin
                h_new = h_new +
                    $signed(mul_00) +
                    $signed({mul_01,5'd0}) + $signed({mul_10,5'd0}) +
                    $signed({mul_02,10'd0}) + $signed({mul_11,10'd0}) + $signed({mul_20,10'd0}) +
                    $signed({mul_03,15'd0}) + $signed({mul_12,15'd0}) + $signed({mul_21,15'd0}) + $signed({mul_30,15'd0}) +
                    $signed({mul_13,20'd0}) + $signed({mul_22,20'd0}) + $signed({mul_31,20'd0}) +
                    $signed({mul_23,25'd0}) + $signed({mul_32,25'd0}) +
                    $signed({mul_33,30'd0});

                mul_00 = $signed({1'd0,h_old[address][4:0]})*$signed({1'd0,mdata_r[4:0]});
                mul_01 = $signed({1'd0,h_old[address][4:0]})*$signed({1'd0,mdata_r[9:5]});
                mul_02 = $signed({1'd0,h_old[address][4:0]})*$signed({1'd0,mdata_r[14:10]});
                mul_03 = $signed({1'd0,h_old[address][4:0]})*$signed(mdata_r[17:15]);

                mul_10 = $signed({1'd0,h_old[address][9:5]})*$signed({1'd0,mdata_r[4:0]});
                mul_11 = $signed({1'd0,h_old[address][9:5]})*$signed({1'd0,mdata_r[9:5]});
                mul_12 = $signed({1'd0,h_old[address][9:5]})*$signed({1'd0,mdata_r[14:10]});
                mul_13 = $signed({1'd0,h_old[address][9:5]})*$signed(mdata_r[17:15]);

                mul_20 = $signed({1'd0,h_old[address][14:10]})*$signed({1'd0,mdata_r[4:0]});
                mul_21 = $signed({1'd0,h_old[address][14:10]})*$signed({1'd0,mdata_r[9:5]});
                mul_22 = $signed({1'd0,h_old[address][14:10]})*$signed({1'd0,mdata_r[14:10]});
                mul_23 = $signed({1'd0,h_old[address][14:10]})*$signed(mdata_r[17:15]);
                
                mul_30 = $signed(h_old[address][17:15])*$signed({1'd0,mdata_r[4:0]});
                mul_31 = $signed(h_old[address][17:15])*$signed({1'd0,mdata_r[9:5]});
                mul_32 = $signed(h_old[address][17:15])*$signed({1'd0,mdata_r[14:10]});
                mul_33 = $signed(h_old[address][17:15])*$signed(mdata_r[17:15]);
            end
            default: begin
            end
        endcase
        stage = stage + next_stage;
        stage = stage == (5+(t_offset!=0)) ? 1 : stage;
        next_stage = 0;
        i_en_sig = 0;
        case (stage)
            0 : begin
                i_en_sig = 1;
                msel_sig = 3'b100;
                address = 0;
                maddr_sig = address;
            end
            1 : begin
                msel_sig = 3'b001;
                address = 0;
                maddr_sig = h_offset;
            end
            2 : begin
                msel_sig = 3'b000;
                address = (address - 1) & 31;
                maddr_sig = {h_offset,address[4:0]};
            end
            3 : begin
                msel_sig = 3'b011;
                address = (address - 1) & 1;
                maddr_sig = h_offset;
            end
            4 : begin
                msel_sig = 3'b101;
                address = 0;
                maddr_sig = {t_offset,h_offset};
            end
            5 : begin
                msel_sig = 3'b010;
                address = address - 1;
                maddr_sig = {h_offset,address};
            end
            default: begin
            end
        endcase
        if(address==0) begin
            next_stage = 1;
        end
        if (stage==4) begin
            mdata_w_sig = h_tmp[h_offset];
            if($signed(h_offset)==-1) begin
                i_en_sig = 1;
                for (i = 0; i < 64; i = i + 1) begin
                    h_old[i] = h_tmp[i];
                end
                if(t_count==t_offset) begin
                    inited = 0;
                end
            end
            h_offset = h_offset + 1;
            if(h_offset==0) begin
                t_offset = t_offset + 1;
            end
        end
    end else begin
        stage = 0;
        address = 0;
        t_offset = 0;
        h_offset = 0;
        //mce_sig = 0;
        next_stage = 0;
        h_new = 0;
        mul_00 = 0;
        mul_01 = 0;
        mul_02 = 0;
        mul_03 = 0;
        mul_10 = 0;
        mul_11 = 0;
        mul_12 = 0;
        mul_13 = 0;
        mul_20 = 0;
        mul_21 = 0;
        mul_22 = 0;
        mul_23 = 0;
        mul_30 = 0;
        mul_31 = 0;
        mul_32 = 0;
        mul_33 = 0;
    end
end

endmodule


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
reg signed [8:0] 
    mul_00, mul_01, mul_02, mul_03, mul_04,
    mul_10, mul_11, mul_12, mul_13, mul_14,
    mul_20, mul_21, mul_22, mul_23, mul_24,
    mul_30, mul_31, mul_32, mul_33, mul_34,
    mul_40, mul_41, mul_42, mul_43, mul_44;
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
reg [10:0] t_count;

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
    if (busy_sig) begin
        //mce_sig = 1;
        if(t_count==t_offset) begin
            inited = 0;
        end
        case (stage)
            0 : begin
                t_count = mdata_r;
                x_data = idata;
            end
            1 : begin
                h_new = h_new +
                    $signed(mul_00) +
                    $signed({mul_01,4'd0}) + $signed({mul_10,4'd0}) +
                    $signed({mul_02,8'd0}) + $signed({mul_11,8'd0}) + $signed({mul_20,8'd0}) +
                    $signed({mul_03,12'd0}) + $signed({mul_12,12'd0}) + $signed({mul_21,12'd0}) + $signed({mul_30,12'd0}) +
                    $signed({mul_04,16'd0}) + $signed({mul_13,16'd0}) + $signed({mul_22,16'd0}) + $signed({mul_31,16'd0}) + $signed({mul_40,16'd0}) +
                    $signed({mul_14,20'd0}) + $signed({mul_23,20'd0}) + $signed({mul_32,20'd0}) + $signed({mul_41,20'd0}) +
                    $signed({mul_24,24'd0}) + $signed({mul_33,24'd0}) + $signed({mul_42,24'd0}) +
                    $signed({mul_34,28'd0}) + $signed({mul_43,28'd0}) +
                    $signed({mul_44,32'd0});
                h_new[`PREC-1:16] = h_new[`PREC-1:16] + $signed(mdata_r);
            end
            2 : begin
                h_new[`PREC-1:16] = x_data[address[4:0]] ? 
                    $signed(h_new[`PREC-1:16]) + $signed(mdata_r) : 
                    h_new[`PREC-1:16];
            end
            3 : begin
                if(address[0]==1)begin
                    carry_bit = h_new[(`PREC-1)] ? (h_new[15] & (|h_new[14:0]) ) : h_new[15];
                    h_new[`PREC-1:16] = h_new[`PREC-1:16] + $signed(mdata_r) + carry_bit;
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
                mul_04 = 0;
                mul_10 = 0;
                mul_11 = 0;
                mul_12 = 0;
                mul_13 = 0;
                mul_14 = 0;
                mul_20 = 0;
                mul_21 = 0;
                mul_22 = 0;
                mul_23 = 0;
                mul_24 = 0;
                mul_30 = 0;
                mul_31 = 0;
                mul_32 = 0;
                mul_33 = 0;
                mul_34 = 0;
                mul_40 = 0;
                mul_41 = 0;
                mul_42 = 0;
                mul_43 = 0;
                mul_44 = 0;
                h_new = 0;
            end
            5 : begin
                h_new = h_new +
                    $signed(mul_00) +
                    $signed({mul_01,4'd0}) + $signed({mul_10,4'd0}) +
                    $signed({mul_02,8'd0}) + $signed({mul_11,8'd0}) + $signed({mul_20,8'd0}) +
                    $signed({mul_03,12'd0}) + $signed({mul_12,12'd0}) + $signed({mul_21,12'd0}) + $signed({mul_30,12'd0}) +
                    $signed({mul_04,16'd0}) + $signed({mul_13,16'd0}) + $signed({mul_22,16'd0}) + $signed({mul_31,16'd0}) + $signed({mul_40,16'd0}) +
                    $signed({mul_14,20'd0}) + $signed({mul_23,20'd0}) + $signed({mul_32,20'd0}) + $signed({mul_41,20'd0}) +
                    $signed({mul_24,24'd0}) + $signed({mul_33,24'd0}) + $signed({mul_42,24'd0}) +
                    $signed({mul_34,28'd0}) + $signed({mul_43,28'd0}) +
                    $signed({mul_44,32'd0});

                mul_00 = $signed({1'd0,h_old[address][3:0]})*$signed({1'd0,mdata_r[3:0]});
                mul_01 = $signed({1'd0,h_old[address][3:0]})*$signed({1'd0,mdata_r[7:4]});
                mul_02 = $signed({1'd0,h_old[address][3:0]})*$signed({1'd0,mdata_r[11:8]});
                mul_03 = $signed({1'd0,h_old[address][3:0]})*$signed({1'd0,mdata_r[15:12]});
                mul_04 = $signed({1'd0,h_old[address][3:0]})*$signed(mdata_r[17:16]);

                mul_10 = $signed({1'd0,h_old[address][7:4]})*$signed({1'd0,mdata_r[3:0]});
                mul_11 = $signed({1'd0,h_old[address][7:4]})*$signed({1'd0,mdata_r[7:4]});
                mul_12 = $signed({1'd0,h_old[address][7:4]})*$signed({1'd0,mdata_r[11:8]});
                mul_13 = $signed({1'd0,h_old[address][7:4]})*$signed({1'd0,mdata_r[15:12]});
                mul_14 = $signed({1'd0,h_old[address][7:4]})*$signed(mdata_r[17:16]);

                mul_20 = $signed({1'd0,h_old[address][11:8]})*$signed({1'd0,mdata_r[3:0]});
                mul_21 = $signed({1'd0,h_old[address][11:8]})*$signed({1'd0,mdata_r[7:4]});
                mul_22 = $signed({1'd0,h_old[address][11:8]})*$signed({1'd0,mdata_r[11:8]});
                mul_23 = $signed({1'd0,h_old[address][11:8]})*$signed({1'd0,mdata_r[15:12]});
                mul_24 = $signed({1'd0,h_old[address][11:8]})*$signed(mdata_r[17:16]);

                mul_30 = $signed({1'd0,h_old[address][15:12]})*$signed({1'd0,mdata_r[3:0]});
                mul_31 = $signed({1'd0,h_old[address][15:12]})*$signed({1'd0,mdata_r[7:4]});
                mul_32 = $signed({1'd0,h_old[address][15:12]})*$signed({1'd0,mdata_r[11:8]});
                mul_33 = $signed({1'd0,h_old[address][15:12]})*$signed({1'd0,mdata_r[15:12]});
                mul_34 = $signed({1'd0,h_old[address][15:12]})*$signed(mdata_r[17:16]);
                
                mul_40 = $signed(h_old[address][17:16])*$signed({1'd0,mdata_r[3:0]});
                mul_41 = $signed(h_old[address][17:16])*$signed({1'd0,mdata_r[7:4]});
                mul_42 = $signed(h_old[address][17:16])*$signed({1'd0,mdata_r[11:8]});
                mul_43 = $signed(h_old[address][17:16])*$signed({1'd0,mdata_r[15:12]});
                mul_44 = $signed(h_old[address][17:16])*$signed(mdata_r[17:16]);
            end
            default: begin
            end
        endcase
        stage = stage + (address==0);
        stage = stage == (5+(t_offset!=0)) ? 1 : stage;
        i_en_sig = 0;
        case (stage)
            0 : begin
                i_en_sig = 1;
                // msel_sig = 3'b100;
                // address = 0;
                // maddr_sig = 0;
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
                address = address ^ 1;
                maddr_sig = h_offset;
            end
            4 : begin
                msel_sig = 3'b101;
                address = 0;
                maddr_sig = {t_offset,h_offset};
                mdata_w_sig = h_tmp[h_offset];
                if((&h_offset)) begin
                    i_en_sig = 1;
                    for (i = 0; i < 64; i = i + 1) begin
                        h_old[i] = h_tmp[i];
                    end
                end
                h_offset = h_offset + 1;
                t_offset = t_offset + (h_offset==0);
            end
            5 : begin
                msel_sig = 3'b010;
                address = address - 1;
                maddr_sig = {h_offset,address};
            end
            default: begin
            end
        endcase
    end 
    if (reset) begin
        inited = 1;
        t_count = -1;
        stage = -1;
        address = 0;
        msel_sig = 3'b100;
        maddr_sig = 0;
        t_offset = 0;
        h_offset = 0;
        //mce_sig = 0;
        h_new = 0;
        mul_00 = 0;
        mul_01 = 0;
        mul_02 = 0;
        mul_03 = 0;
        mul_04 = 0;
        mul_10 = 0;
        mul_11 = 0;
        mul_12 = 0;
        mul_13 = 0;
        mul_14 = 0;
        mul_20 = 0;
        mul_21 = 0;
        mul_22 = 0;
        mul_23 = 0;
        mul_24 = 0;
        mul_30 = 0;
        mul_31 = 0;
        mul_32 = 0;
        mul_33 = 0;
        mul_34 = 0;
        mul_40 = 0;
        mul_41 = 0;
        mul_42 = 0;
        mul_43 = 0;
        mul_44 = 0;
    end
end

endmodule


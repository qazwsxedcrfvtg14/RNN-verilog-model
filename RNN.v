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

`define PREC  43 // 36->43  // Size before tanh
`define PREC2 20 // 18->20  // Size of input param
`define PREC3 18 // 20->18  // Size after tanh
`define PREC4 37 // 20->18  // Size after mul


integer i;

reg signed [`PREC3-1:0] h_old[0:63];
reg signed [`PREC3-1:0] h_tmp[0:62], tmp;
reg signed [`PREC-1:0] h_new, h_add;
reg signed [`PREC-1-16:0] h_new_tmp;
reg signed [`PREC4-1:0] mul_tmp, mul_tmp1, mul_tmp2, mul_tmp3;
reg start_mul_sum1;
reg start_mul_sum2;
reg [8:0] single;
reg [8:0] double;
reg [8:0] neg;
reg signed [19:0] mul_data;

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

reg [2:0] stage;
reg [10:0] t_count;

reg carry_bit;

// reg signed [39:0] mul_tmp;

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
    
    mul_tmp = mul_tmp1 + $signed({mul_tmp2,6'd0}) + $signed({mul_tmp3,12'd0});
    
    mul_tmp1 <=
        (single[0] ? $signed({(neg[0]?-mul_data:mul_data)     }) : double[0] ? $signed({(neg[0]?-mul_data:mul_data),1'd0}) : $signed(0) ) +
        (single[1] ? $signed({(neg[1]?-mul_data:mul_data),2'd0}) : double[1] ? $signed({(neg[1]?-mul_data:mul_data),3'd0}) : $signed(0) ) +
        (single[2] ? $signed({(neg[2]?-mul_data:mul_data),4'd0}) : double[2] ? $signed({(neg[2]?-mul_data:mul_data),5'd0}) : $signed(0) ) ;
    mul_tmp2 <=
        (single[3] ? $signed({(neg[3]?-mul_data:mul_data)     }) : double[3] ? $signed({(neg[3]?-mul_data:mul_data),1'd0}) : $signed(0) ) +
        (single[4] ? $signed({(neg[4]?-mul_data:mul_data),2'd0}) : double[4] ? $signed({(neg[4]?-mul_data:mul_data),3'd0}) : $signed(0) ) +
        (single[5] ? $signed({(neg[5]?-mul_data:mul_data),4'd0}) : double[5] ? $signed({(neg[5]?-mul_data:mul_data),5'd0}) : $signed(0) ) ;
    mul_tmp3 <=
        (single[6] ? $signed({(neg[6]?-mul_data:mul_data)     }) : double[6] ? $signed({(neg[6]?-mul_data:mul_data),1'd0}) : $signed(0) ) +
        (single[7] ? $signed({(neg[7]?-mul_data:mul_data),2'd0}) : double[7] ? $signed({(neg[7]?-mul_data:mul_data),3'd0}) : $signed(0) ) +
        (single[8] ? $signed({(neg[8]?-mul_data:mul_data),4'd0}) : double[8] ? $signed({(neg[8]?-mul_data:mul_data),5'd0}) : $signed(0) ) ;

    neg[0] <= h_old[address][1];
    neg[1] <= h_old[address][3];
    neg[2] <= h_old[address][5];
    neg[3] <= h_old[address][7];
    neg[4] <= h_old[address][9];
    neg[5] <= h_old[address][11];
    neg[6] <= h_old[address][13];
    neg[7] <= h_old[address][15];
    neg[8] <= h_old[address][17];

    single[0] <= 0 ^ h_old[address][0];
    single[1] <= h_old[address][1] ^ h_old[address][2];
    single[2] <= h_old[address][3] ^ h_old[address][4];
    single[3] <= h_old[address][5] ^ h_old[address][6];
    single[4] <= h_old[address][7] ^ h_old[address][8];
    single[5] <= h_old[address][9] ^ h_old[address][10];
    single[6] <= h_old[address][11] ^ h_old[address][12];
    single[7] <= h_old[address][13] ^ h_old[address][14];
    single[8] <= h_old[address][15] ^ h_old[address][16];

    double[0] <= (0 == h_old[address][0]) & (h_old[address][0] ^ h_old[address][1]);
    double[1] <= (h_old[address][1] == h_old[address][2]) & (h_old[address][2] ^ h_old[address][3]);
    double[2] <= (h_old[address][3] == h_old[address][4]) & (h_old[address][4] ^ h_old[address][5]);
    double[3] <= (h_old[address][5] == h_old[address][6]) & (h_old[address][6] ^ h_old[address][7]);
    double[4] <= (h_old[address][7] == h_old[address][8]) & (h_old[address][8] ^ h_old[address][9]);
    double[5] <= (h_old[address][9] == h_old[address][10]) & (h_old[address][10] ^ h_old[address][11]);
    double[6] <= (h_old[address][11] == h_old[address][12]) & (h_old[address][12] ^ h_old[address][13]);
    double[7] <= (h_old[address][13] == h_old[address][14]) & (h_old[address][14] ^ h_old[address][15]);
    double[8] <= (h_old[address][15] == h_old[address][16]) & (h_old[address][16] ^ h_old[address][17]);

    mul_data <= mdata_r;

    
    carry_bit <= h_new[15];

    h_new <= h_new + h_add;
    h_add <= 0;
    
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
                if(start_mul_sum2) begin
                    h_add <= mul_tmp + $signed({mdata_r,16'd0});
                end else begin
                    h_add <= $signed({mdata_r,16'd0});
                end
            end
            2 : begin
                if(start_mul_sum2) begin
                    h_add <= mul_tmp + $signed({mdata_r,16'd0});
                end else begin
                    h_add <= $signed({mdata_r,16'd0});
                end
            end
            3 : begin
                if (x_data[address[4:0]]) begin
                    h_add <= $signed({mdata_r,16'd0});
                end
            end
            4 : begin
                h_new_tmp = h_new[`PREC-1:16] + h_add[`PREC-1:16] + carry_bit;
                if ((|h_new_tmp[`PREC-2-16:16])&!h_new_tmp[`PREC-1-16]) begin
                    tmp = 20'h10000;
                end else if ((|(~h_new_tmp[`PREC-2-16:16]))&h_new_tmp[`PREC-1-16]) begin
                    tmp = 20'hf0000;
                end else begin
                    tmp = h_new_tmp[19:0];
                end
            end
            5 : begin
                if(h_offset==0) begin
                    x_data = idata;
                end
                h_new <= 0;
                start_mul_sum1 = 0;
                start_mul_sum2 = 0;
            end
            6 : begin
                if (start_mul_sum2) begin
                    h_add <= mul_tmp;
                end else if (start_mul_sum1) begin
                    start_mul_sum2 = 1;
                end else begin
                    start_mul_sum1 = 1;
                end
            end
            default: begin
            end
        endcase

        stage = stage + (address==0);
        stage = stage == (6+(t_offset!=0)) ? 1 : stage;
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
                // address = 0;
                maddr_sig = h_offset;
            end
            2 : begin
                msel_sig = 3'b011;
                // address = 0;
                // maddr_sig = h_offset;
            end
            3 : begin
                msel_sig = 3'b000;
                address = (address + 1) & 31;
                maddr_sig = {h_offset,address[4:0]};
            end
            4 : begin
                // msel_sig = 3'b000;
                // address = 0;
                // maddr_sig = {h_offset,address[4:0]};
            end
            5 : begin
                msel_sig = 3'b101;
                address = 0;
                maddr_sig = {t_offset,h_offset};
                mdata_w_sig = tmp;
                if((&h_offset)) begin
                    i_en_sig = 1;
                    for (i = 0; i < 63; i = i + 1) begin
                        h_old[i] = h_tmp[i];
                    end
                    h_old[63] = tmp;
                end else begin
                    h_tmp[h_offset] = tmp;
                end
                h_offset = h_offset + 1;
                t_offset = t_offset + (h_offset==0);
            end
            6 : begin
                msel_sig = 3'b010;
                address = address + 1;
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
        h_new <= 0;
        start_mul_sum2 = 0;
    end
    
end

endmodule


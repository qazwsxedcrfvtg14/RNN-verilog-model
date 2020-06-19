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
reg signed [`PREC-1:0] h_new;
reg signed [22:0] adder_d[0:8];
reg signed [23:0] adder_00, adder_01, adder_02, adder_03;
reg signed [20:0] adder_04;
reg signed [28:0] adder_10;
reg signed [29:0] adder_11;
reg signed [38:0] adder_20;
reg signed [19:0] add_data;
reg signed [`PREC-1-16:0] h_new_tmp;
reg signed [`PREC4-1:0] mul_tmp, mul_tmp1, mul_tmp2, mul_tmp3;
reg mul_on;
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

reg [2:0] last_stage;
reg [2:0] stage;
reg [10:0] t_count;
reg has_t_count;

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
    if (busy_sig&&!has_t_count) begin
        // $display("%d",mdata_r);
        has_t_count <= 1;
        t_count <= mdata_r;
    end
    busy_sig <= inited & !reset & (ready | busy_sig);

    h_new <= h_new + adder_20 + $signed({add_data,16'd0});
    adder_20 <= adder_10 + $signed({adder_11,8'd0});

    adder_10 <= adder_00 + $signed({adder_01,4'd0});
    adder_11 <= adder_02 + $signed({adder_03,4'd0}) + $signed({adder_04,8'd0});

    adder_00 <= adder_d[0] + $signed({adder_d[1],2'd0});
    adder_01 <= adder_d[2] + $signed({adder_d[3],2'd0});
    adder_02 <= adder_d[4] + $signed({adder_d[5],2'd0});
    adder_03 <= adder_d[6] + $signed({adder_d[7],2'd0});
    adder_04 <= adder_d[8];

    for (i = 0; i < 9; i = i + 1) begin
        adder_d[i] <= (single[i] ? $signed({(neg[i]?-mul_data:mul_data)     }) : double[i] ? $signed({(neg[i]?-mul_data:mul_data),1'd0}) : $signed(0) );
    end

    if (mul_on) begin
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
    end else begin
        neg <= 0;
        single <= 0;
        double <= 0;
    end

    mul_data <= mdata_r;
    add_data <= 0;
    carry_bit <= h_new[15];
    
    if (busy_sig) begin
        // mce_sig = 1;
        if(t_count==t_offset) begin
            inited = 0;
        end
        case (last_stage)
            0 : begin
                add_data <= $signed(mdata_r);
            end
            1 : begin
                add_data <= $signed(mdata_r);
                if(h_offset == 0) begin
                    x_data = idata;
                end
            end
            2 : begin
                if (x_data[address[4:0]]) begin
                    add_data <= $signed(mdata_r);
                end
            end
            3 : begin
                add_data <= carry_bit;
            end
            4 : begin
            end
            5 : begin
                // h_new_tmp = h_new[`PREC-1:16] + carry_bit;
                h_new_tmp = h_new[`PREC-1:16];
                if ((|h_new_tmp[`PREC-2-16:16])&!h_new_tmp[`PREC-1-16]) begin
                    tmp = 20'h10000;
                end else if ((|(~h_new_tmp[`PREC-2-16:16]))&h_new_tmp[`PREC-1-16]) begin
                    tmp = 20'hf0000;
                end else begin
                    tmp = h_new_tmp[19:0];
                end
            end
            6 : begin
                if(h_offset==0) begin
                    for (i = 0; i < 63; i = i + 1) begin
                        h_old[i] = h_tmp[i];
                    end
                    h_old[63] = tmp;
                end
                h_new <= 0;
            end
            7 : begin
            end
        endcase
        i_en_sig = 0;
        case (stage)
            0 : begin
                mul_on = 0;
                msel_sig = 3'b001;
                // address = 0;
                maddr_sig = h_offset;
            end
            1 : begin
                msel_sig = 3'b011;
                // address = 0;
                // maddr_sig = h_offset;
                if(h_offset == 0) begin
                    i_en_sig = 1;
                end
            end
            2 : begin
                msel_sig = 3'b000;
                address = (address + 1) & 31;
                maddr_sig = {h_offset,address[4:0]};
            end
            3 : begin
                // stall
            end
            4 : begin
                // stall
            end
            5 : begin
                // stall
            end
            6 : begin
                msel_sig = 3'b101;
                address = 0;
                maddr_sig = {t_offset,h_offset};
                mdata_w_sig = tmp;
                if((&h_offset)) begin
                    t_offset = t_offset + 1;
                end else begin
                    h_tmp[h_offset] = tmp;
                end
                h_offset = h_offset + 1;
            end
            7 : begin
                mul_on = 1;
                msel_sig = 3'b010;
                address = address + 1;
                maddr_sig = {h_offset,address};
            end
        endcase
        last_stage = stage;
        if (stage==6&&t_offset==0) begin
            stage = 0;
        end else if (address==0) begin
            stage = stage + 1;
        end
    end 
    if (reset) begin
        inited = 1;
        has_t_count <= 0;
        t_count <= -1;
        last_stage = 7;
        stage = 0;
        address = 0;
        msel_sig = 3'b100;
        maddr_sig = 0;
        t_offset = 0;
        h_offset = 0;
        //mce_sig = 0;
        h_new <= 0;
        mul_on = 0;
    end
end

endmodule


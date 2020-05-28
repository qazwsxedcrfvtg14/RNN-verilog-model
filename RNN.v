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

reg signed [19:0] mem13[0:63];
reg signed [19:0] h_old[0:63];
reg signed [39:0] h_new[0:63];
reg [31:0] x_data;

reg busy_sig;
reg i_en_sig;
reg mce_sig;
reg [19:0] mdata_w_sig;
reg [2:0] msel_sig;

reg [11:0] address;

reg inited;
reg initmem;

reg [1:0] stage;
reg next_stage;
reg [19:0] t_count;

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
assign mce = mce_sig;
assign mdata_w = mdata_w_sig;
assign msel = msel_sig;
assign maddr = address;

always @(posedge clk ) begin
    busy_sig <= ready & inited & !reset;
    inited <= reset | inited;
    if (busy_sig) begin
        mce_sig <= 1;
        case (stage)
            0 : begin
                t_count <= mdata_r;
                x_data <= idata;
            end
            1 : begin
                mem13[address] <= mdata_r;
            end
            2 : begin
                mem13[address] <= mem13[address] + mdata_r;
                h_new[address] <= 0;
            end
            3 : begin
                h_new[address>>5] <= x_data[address&31] ? 
                    h_new[address>>5] + { {4{mdata_r[19]}}, mdata_r, 16'd0 } : 
                    h_new[address>>5];
            end
            4 : begin
                h_new[address] <= h_new[address] + { {4{mem13[address][19]}}, mem13[address], 16'd0 };
                if (h_new[address] > 40'h0100000000) begin
                    h_new[address] <= 40'h0100000000;
                end
                if (h_new[address] < -40'h0100000000) begin
                    h_new[address] <= -40'h0100000000;
                end
                mdata_w_sig <= h_new[address][35:16];
                h_old[address] <= h_new[address][35:16];
                h_new[address] <= 0;
                if(next_stage) begin
                    t_count <= t_count-1;
                    if(t_count==0)begin
                        inited <= 0;
                    end
                end
            end
            5 : begin
                h_new[address>>6] <= h_new[address>>6] + h_old[address&63] * mdata_r;
            end
            default: begin
            end
        endcase
        stage <= stage + next_stage;
        stage <= stage == 6 ? 3 : stage;
        next_stage <= 0;
        case (stage)
            0 : begin
                i_en_sig <= 1;
                msel_sig <= 3'b100;
                address <= 1;
            end
            1 : begin
                i_en_sig <= 0;
                msel_sig <= 3'b001;
                if(address==0) begin
                    address <= 64;
                end
            end
            2 : begin
                msel_sig <= 3'b011;
                if(address==0) begin
                    address <= 64;
                end
            end
            3 : begin
                msel_sig <= 3'b000;
                if(address==0) begin
                    address <= 2048;
                end
            end
            4 : begin
                msel_sig <= 3'b101;
                if(address==0) begin
                    address <= 64;
                end
            end
            5 : begin
                msel_sig <= 3'b010;
                if(address==0) begin
                    address <= 0; // 4096
                end
            end
            default: begin
            end
        endcase
        address <= address - 1;
        if(address==0) begin
            next_stage <= 1;
        end
    end else begin
        stage <= 0;
        address <= 0;
        mce_sig <= 0;
    end
end

endmodule


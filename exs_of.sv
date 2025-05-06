module exs_of #(
    parameter DATA_WIDTH = 32
)(
    input  logic                         clk_i,
    input  logic                         rstn_i,
    input  logic                         valid_i,
    input  logic signed [DATA_WIDTH-1:0] a_i,
    input  logic signed [DATA_WIDTH-1:0] b_i,
    input  logic signed [DATA_WIDTH-1:0] c_i,
    input  logic signed [DATA_WIDTH-1:0] d_i,
    output logic                         valid_o,
    output logic signed [DATA_WIDTH-1:0] q_o
);

    // === Stage 1 === //
    logic signed [DATA_WIDTH:0]   a_minus_b;  // +1 bit
    logic signed [DATA_WIDTH+1:0] c_3;      // +2 bits
    logic signed [DATA_WIDTH-1:0] d;
    logic valid_1;

    always_ff @(posedge clk_i) begin
        if (!rstn_i) begin
            valid_1 <= 0;
        end else begin
            valid_1    <= valid_i;
            a_minus_b  <= a_i - b_i;               // (a - b) 
            c_3        <= (c_i << 1) + c_i + 1;    // 3*c+1 
            d          <= d_i;
        end
    end

    // === Stage 2 === //
    logic signed [DATA_WIDTH+1:0]   d_4;            // +2 bits
    logic signed [2*DATA_WIDTH+2:0] a_b_3_c;      // twice +3 bits 
    logic valid_2;

    always_ff @(posedge clk_i) begin
        if (!rstn_i) begin
            valid_2 <= 0;
        end else begin
            valid_2    <= valid_1;
            a_b_3_c    <= a_minus_b * c_3;       // (a-b)*(3c+1)
            d_4        <= d << 2;                // 4*d
        end
    end

    // === Stage 3 === //
    logic signed [2*DATA_WIDTH+2:0] full_result; 
    logic signed [DATA_WIDTH-1:0]   result;        
    logic                           valid_3;
    logic                           overflow;                     

    always_ff @(posedge clk_i) begin
        if (!rstn_i) begin
            valid_3 <= 0;
        end else begin
            valid_3 <= valid_2;
            full_result <= (a_b_3_c - d_4) >>> 1; 
        end
    end

localparam MIN_VAL = -(2**(DATA_WIDTH-1));
localparam MAX_VAL =  (2**(DATA_WIDTH-1)) - 1;

    always_comb begin
        overflow = (full_result > (2**(DATA_WIDTH-1)-1)) || 
                   (full_result < -(2**(DATA_WIDTH-1)));

        // if overflow - off the scale
        if (overflow) begin
            if (full_result[DATA_WIDTH-1]) begin
                result = MIN_VAL;
            end else begin
                result = MAX_VAL;
            end
        end else begin
            result = full_result[DATA_WIDTH-1:0];
        end
    end

    assign valid_o = valid_3 & ~overflow;
    assign q_o = result;

endmodule
module exs_of_tb;

    parameter DATA_WIDTH = 32;

    logic clk_i;
    logic rstn_i;
    logic valid_i;
    logic signed [DATA_WIDTH-1:0] a_i;
    logic signed [DATA_WIDTH-1:0] b_i;
    logic signed [DATA_WIDTH-1:0] c_i;
    logic signed [DATA_WIDTH-1:0] d_i;

    logic valid_o;
    logic signed [DATA_WIDTH-1:0] q_o;

    integer i;
    integer error_count = 0;

    exs_of #(.DATA_WIDTH(DATA_WIDTH)) uut (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .valid_i(valid_i),
        .a_i(a_i),
        .b_i(b_i),
        .c_i(c_i),
        .d_i(d_i),
        .valid_o(valid_o),
        .q_o(q_o)
    );

    initial begin
        clk_i = 0;
        forever #5 clk_i = ~clk_i;
    end

    initial begin
        rstn_i = 0;
        valid_i = 0;
        a_i = 0;
        b_i = 0;
        c_i = 0;
        d_i = 0;
        #10;
        rstn_i = 1;

        // Test 0: Zero inputs
        i = 0;
        $display("Test %0d: Zero inputs", i);
        apply_test(0, 0, 0, 0);

        // Test 1: Equal a and b
        i++;
        $display("Test %0d: Equal a and b", i);
        apply_test(1000000, 1000000, 1, 0);

        // Test 2: Negative values
        i++;
        $display("Test %0d: Negative values", i);
        apply_test(-1000000, 0, -1000000, 0);

        // Test 3: Typical case
        i++;
        $display("Test %0d: Typical case", i);
        apply_test(129, 1, 255, 10);

        // Test 4: a < b case
        i++;
        $display("Test %0d: a < b case", i);
        apply_test(100, 200, 50, 25);

        // Test 5: Positive values
        i++;
        $display("Test %0d: Positive values", i);
        apply_test(500, 100, 100, 50);

        // Test 6: All negative
        i++;
        $display("Test %0d: All negative", i);
        apply_test(-500, -100, -100, -50);

        // Test 7: Small values
        i++;
        $display("Test %0d: Small values", i);
        apply_test(1, 1, 1, 1);

        // Test 8: Max positive (no overflow)
        i++;
        $display("Test %0d: Max positive", i);
        apply_test(32767, 32767, 32767, 32767);

        // Test 9: Potential overflow case
        i++;
        $display("Test %0d: Potential overflow", i);
        apply_test(2147483647, -2147483647, 2147483647, -2147483647);

        // Test 10: Minimum values
        i++;
        $display("Test %0d: Almost minimum values", i);
        apply_test(-(2**31), -(2**31), -(2**31), -(2**31));

        // Final report
        if (error_count > 0) begin
            $display("\nTEST FAILED: %0d errors found", error_count);
        end
        else begin
            $display("\nTEST PASSED: All cases correct");
        end

        $stop;
    end

    task apply_test(input logic signed [DATA_WIDTH-1:0] a, b, c, d);
        valid_i = 1;
        a_i = a;
        b_i = b;
        c_i = c;
        d_i = d;
        #10 valid_i = 0;
        #20; // Wait for pipeline
        check_results(a, b, c, d, q_o);
    endtask

    task check_results(input logic signed [DATA_WIDTH-1:0] a, b, c, d, q);
        logic signed [DATA_WIDTH-1:0] expected_result;
        expected_result = (((a - b) * (3 * c + 1) - 4 * d) / 2);

        if (valid_o === 0) begin
            $display("INFO: Overflow detected, valid_o is 0");
            // No further checks needed if overflow occurs
        end else begin
            if (expected_result !== q) begin
                $display("ERROR: a=%0d b=%0d c=%0d d=%0d | Expected %0d, got %0d",
                        a, b, c, d, expected_result, q);
                error_count++;
            end
            else begin
                $display("PASS: a=%0d b=%0d c=%0d d=%0d | Result = %0d",
                        a, b, c, d, q);
            end
        end
    endtask

endmodule

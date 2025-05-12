module ps2_keyboard(clk,resetn,ps2_clk,ps2_data);
    input clk,resetn,ps2_clk,ps2_data;

    reg [9:0] buffer;       // ps2_data buffer
    reg [3:0] count;        // count ps2_data bits in buffer
    reg [2:0] ps2_clk_sync; // ps2_clk buffer use 3bit to decrease Metastability Risk

	// reg the ps2_clk
    always @(posedge clk) begin
        ps2_clk_sync <=  {ps2_clk_sync[1:0],ps2_clk};
    end

	// sample in ps2_clk upper edge
    wire sampling = ~ps2_clk_sync[2] & ps2_clk_sync[1];

    always @(posedge clk) begin
        if (resetn == 0) begin // reset
            count <= 0;
        end
        else begin
            if (sampling) begin
              if (count == 4'd10) begin
                if ((buffer[0] == 0) &&   // start bit
                    (ps2_data)       &&   // stop bit
                    (^buffer[9:1])) begin // parity check
                    $display("receive %x", buffer[8:1]);
                end
                count <= 0;     // for next transform
              end else begin
                buffer[count] <= ps2_data;  // reg ps2_data
                count <= count + 3'b1;
              end
            end
        end
    end

endmodule

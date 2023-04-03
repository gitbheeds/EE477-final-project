/**
* Conway's Game of Life Cell
*
* data_i[7:0] is status of 8 neighbor cells
* data_o is status this cell
* 1: alive, 0: death
*
* when en_i==1:
*   simulate the cell transition with 8 given neighors
* else when update_i==1:
*   update the cell status to update_val_i
* else:
*   cell status remains unchanged
**/

module bsg_cgol_cell 
    (input clk_i

    ,input en_i
    ,input [7:0] data_i

    ,input update_i
    ,input update_val_i

    ,output logic data_o
  );

  // TODO: Design your bsg_cgl_cell
  // Hint: Find the module to count the number of neighbors from basejump
  
  wire [3:0] num_ones = `BSG_COUNTONES_SYNTH(data_i);
  logic data_n, data_r;

  always_comb begin
    if (data_r && ~(num_ones == 2 || num_ones == 3)) begin
      data_n = 1'b0;
    end else if (~data_r && num_ones == 3) begin
      data_n = 1'b1;
    end else
      data_n = data_r;
  end

  always_ff @(posedge clk_i) begin
    if (~en_i) begin
      if (update_i) begin
        data_r <= update_val_i;
      end else begin
        data_r <= data_r;
      end
    end else begin
      data_r <= data_n;
    end
  end

  assign data_o = data_r;

endmodule



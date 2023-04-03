module bsg_cgol_ctrl #(
   parameter `BSG_INV_PARAM(max_game_length_p)
  ,localparam game_len_width_lp=`BSG_SAFE_CLOG2(max_game_length_p+1)
) (
   input clk_i
  ,input reset_i

  ,input en_i

  // Input Data Channel
  ,input  [game_len_width_lp-1:0] frames_i
  ,input  v_i
  ,output logic ready_o

  // Output Data Channel
  ,input yumi_i
  ,output logic v_o

  // Cell Array
  ,output logic update_o
  ,output logic en_o
);

  wire unused = en_i; // for clock gating, unused
  
  // TODO: Design your control logic
	typedef enum logic [1:0] {eWAIT, eCOMPUTE, eFINISH} state;


  //Keeps track of game length
  logic [game_len_width_lp-1:0] played_frames;

  //state variables
  state ps, ns;

  logic [game_len_width_lp-1:0] frames_r;

  always_comb begin
    if (reset_i) begin
      ready_o = 0;
      // en_o = 0;
      v_o = 0;
      // update_o = 0;
    end

    //state computation and output updating
    case (ps)

      eWAIT: begin
        
        //ready for inputs
        ready_o = 1'b1;

        //disable cell computation
        // en_o = 1'b0;
        //output not valid
        v_o = 1'b0;

        //check for valid input
        //if valid, allow update, move to compute
        if(v_i) begin
          // update_o = 1'b1;
          ns = eCOMPUTE;
        end else begin
          // update_o = 1'b0;
          ns = ps;
        end

      end

      eCOMPUTE: begin
      
        //enable cell computation
        // en_o = 1'b1;

        //disable ready
        ready_o = 1'b0;

        //output not valid 
        v_o = 1'b0;

        //no update value
        // update_o = 1'b0;

        //game completed
        if(played_frames == frames_r) begin
          ns = eFINISH;
        end else begin
          ns = ps;
        end
      end

      eFINISH: begin
        //output is valid
        v_o = 1'b1;

        //disable ready
        ready_o = 1'b0;

        //disable cell computation
        // en_o = 1'b0;

        //no update value
        // update_o = 1'b0;

        //move to eWAIT when output is accepted 
        if(yumi_i) begin
          ns = eWAIT;
        end else begin
          ns = ps;
        end
      end
    

      default: ns = eWAIT;

    endcase

  end

  // Mealy output to guarantee both exclusivity and 1 cycle minimum
  assign update_o = ps == eWAIT;
  assign en_o = ps == eCOMPUTE;

  //state transition
  always_ff @(posedge clk_i) begin
    if (reset_i) begin
      ps <= eWAIT;
      played_frames <= 0;
    end else begin
      ps <= ns;
    end
    if (ps == eWAIT) begin
      frames_r <= frames_i;
      // Set to 1 to handle cycle accuracy
      played_frames <= 1;
    end
    if (ps == eCOMPUTE) begin
      played_frames <= played_frames + 1;
    end
  end

endmodule

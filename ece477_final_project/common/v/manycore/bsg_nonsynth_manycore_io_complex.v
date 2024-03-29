
`include "bsg_manycore_packet.vh"

// currently only supports south side of chip

module bsg_nonsynth_manycore_io_complex
  #(
    mem_size_p      = -1   // size of memory being loaded, in bytes
    ,max_cycles_p   = -1
    ,addr_width_p   = -1
    ,data_width_p  = 32
    ,num_tiles_x_p = -1
    ,num_tiles_y_p = -1
    ,load_rows_p    =  num_tiles_y_p
    ,load_cols_p    =  num_tiles_x_p
    ,tile_id_ptr_p = -1
    ,x_cord_width_lp  = `BSG_SAFE_CLOG2(num_tiles_x_p)
    ,y_cord_width_lp  = `BSG_SAFE_CLOG2(num_tiles_y_p + 1)
    ,bsg_manycore_link_sif_width_lp = `bsg_manycore_link_sif_width(addr_width_p,data_width_p,x_cord_width_lp,y_cord_width_lp)

    )
   (input clk_i
    ,input reset_i

    ,input  [num_tiles_x_p-1:0][bsg_manycore_link_sif_width_lp-1:0] ver_link_sif_i
    ,output [num_tiles_x_p-1:0][bsg_manycore_link_sif_width_lp-1:0] ver_link_sif_o

    ,output finish_lo
	,output success_lo
	,output timeout_lo
    );

   initial
     begin
        $display("## creating manycore complex num_tiles (x,y) = %-d,%-d (%m)", num_tiles_x_p, num_tiles_y_p);
     end

   `declare_bsg_manycore_packet_s(addr_width_p,data_width_p,x_cord_width_lp,y_cord_width_lp);

   localparam packet_width_lp = `bsg_manycore_packet_width(addr_width_p, data_width_p, x_cord_width_lp, y_cord_width_lp);

   // we add this for easier debugging
  `declare_bsg_manycore_link_sif_s(addr_width_p,data_width_p,x_cord_width_lp,y_cord_width_lp);
   bsg_manycore_link_sif_s  [num_tiles_x_p-1:0] ver_link_sif_i_cast, ver_link_sif_o_cast;
   assign ver_link_sif_i_cast = ver_link_sif_i;
   assign ver_link_sif_o      = ver_link_sif_o_cast;

   wire [39:0] cycle_count;

   bsg_cycle_counter #(.width_p(40),.init_val_p(0))
   cc (.clk_i(clk_i), .reset_i(reset_i), .ctr_r_o(cycle_count));

   logic [addr_width_p-1:0]  mem_addr;
   logic [data_width_p-1:0]  mem_data;

   bsg_manycore_packet_s  loader_data_lo;
   logic                      loader_v_lo;
   logic                      loader_ready_li;

   logic reset_r;
   always_ff @(posedge clk_i)
     begin
       reset_r <= reset_i;
     end

   bsg_manycore_spmd_loader
     #( .mem_size_p    (mem_size_p)
        ,.num_rows_p    (num_tiles_y_p)
        ,.num_cols_p    (num_tiles_x_p)
        ,.load_rows_p   (load_rows_p)
        ,.load_cols_p   (load_cols_p)
        ,.data_width_p  (data_width_p)
        ,.addr_width_p  (addr_width_p)
        ,.tile_id_ptr_p (tile_id_ptr_p)
        ) spmd_loader
       ( .clk_i     (clk_i)
         ,.reset_i  (reset_r)
         ,.data_o   (loader_data_lo )
         ,.v_o      (loader_v_lo    )
         ,.ready_i  (loader_ready_li)
         ,.data_i   (mem_data)
         ,.addr_o   (mem_addr)
         ,.my_x_i   ( x_cord_width_lp '(0) )
         ,.my_y_i   ( y_cord_width_lp ' (num_tiles_y_p) )
         );

   bsg_manycore_io_complex_rom
   #( .addr_width_p(addr_width_p)
      ,.width_p     (data_width_p)
      ) spmd_rom
     ( .addr_i (mem_addr)
       ,.data_o (mem_data)
       );


   wire [num_tiles_x_p-1:0] finish_lo_vec;
   assign finish_lo = | finish_lo_vec;
   
   wire [num_tiles_x_p-1:0] success_lo_vec;
   assign success_lo = | success_lo_vec;
   
   wire [num_tiles_x_p-1:0] timeout_lo_vec;
   assign timeout_lo = | timeout_lo_vec;

   // we only set such a high number because we
   // know these packets can always be consumed
   // at the recipient and do not require any
   // forwarded traffic. for an accelerator
   // this would not be the case, and this
   // number must be set to the same as the
   // number of elements in the accelerator's
   // input fifo

   localparam spmd_max_out_credits_lp = 128;

   genvar                   i;

   for (i = 0; i < num_tiles_x_p; i=i+1)
     begin: rof

        wire pass_thru_ready_lo;

        localparam credits_lp = (i==0) ? spmd_max_out_credits_lp : 4;

        wire [`BSG_SAFE_CLOG2(credits_lp+1)-1:0] creds;

        logic [x_cord_width_lp-1:0] pass_thru_x_li;
        logic [y_cord_width_lp-1:0] pass_thru_y_li;

        assign pass_thru_x_li = x_cord_width_lp ' (i);
        assign pass_thru_y_li = y_cord_width_lp ' (num_tiles_y_p);

        // hook up the ready signal if this is the SPMD loader
        // we handle credits here but could do it in the SPMD module too

        if (i==0)
          begin: fi
             assign loader_ready_li = pass_thru_ready_lo & (|creds);

	     if (0)
             always @(negedge clk_i)
               begin
                  if (~reset_i & loader_ready_li & loader_v_lo)
                    begin
                       $write("Loader: Transmitted addr=%-d'h%h (x_cord_width_lp=%-d)(y_cord_width_lp=%-d) "
                              ,addr_width_p, mem_addr, x_cord_width_lp, y_cord_width_lp);
                       `write_bsg_manycore_packet_s(loader_data_lo);
                       $write("\n");
                    end
                end

          end

        bsg_nonsynth_manycore_monitor #(.x_cord_width_p (x_cord_width_lp)
                                        ,.y_cord_width_p(y_cord_width_lp)
                                        ,.addr_width_p  (addr_width_p)
                                        ,.data_width_p  (data_width_p)
                                        ,.channel_num_p (i)
                                        ,.max_cycles_p(max_cycles_p)
                                        ,.pass_thru_p(i==0)
                                        // for the SPMD loader we don't anticipate
                                        // any backwards flow control; but for an
                                        // accelerator, we must be much more careful about
                                        // setting this
                                        ,.pass_thru_max_out_credits_p (credits_lp)
                                        ) bmm (.clk_i             (clk_i)
                                               ,.reset_i          (reset_r)
                                               ,.link_sif_i       (ver_link_sif_i_cast[i])
                                               ,.link_sif_o       (ver_link_sif_o_cast[i])
                                               ,.pass_thru_data_i (loader_data_lo )
                                               ,.pass_thru_v_i    (loader_v_lo & loader_ready_li    )
                                               ,.pass_thru_ready_o(pass_thru_ready_lo)
                                               ,.pass_thru_out_credits_o(creds)
                                               ,.pass_thru_x_i(pass_thru_x_li)
                                               ,.pass_thru_y_i(pass_thru_y_li)
                                               ,.cycle_count_i(cycle_count)
                                               ,.finish_o     (finish_lo_vec[i])
											   ,.success_o(success_lo_vec[i])
											   ,.timeout_o(timeout_lo_vec[i])
                                               );
     end



endmodule

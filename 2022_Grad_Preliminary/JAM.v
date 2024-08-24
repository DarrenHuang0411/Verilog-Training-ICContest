 module JAM (
input CLK,
input RST,
output [2:0] W,
output [2:0] J,
input [6:0] Cost,
output reg [3:0] MatchCount,
output reg [9:0] MinCost,
output reg Valid 
);

// const. n=7
parameter n = 3'd7;
integer i ,j;

parameter   S_idel              = 3'd0,
            S_Start_next1       = 3'd1, 
            S_Start_next2       = 3'd2,
            S_Start_next3       = 3'd3,                          
            S_Finish            = 3'd4;
//counter
reg [2:0] count_ws_sort;
reg [3:0] count_total;

// Dictionary 
reg [2:0] now_dict [7:0];
reg [9:0] temp_MinCost;

//fsm
reg [2:0] current_state_fsm;
reg [2:0] next_dict [7:0];
reg [2:0] next_dict_temp [7:0];

//fsm S_Start_next1
reg [2:0] change_point_l;
reg [2:0] change_point_r;
reg [2:0] point_l_place;

reg [2:0] for_change_point = n;

//fsm S_Start_next1, 3 ==> flip serial
reg [2:0] flip2next;
reg [2:0] max_place;
reg [2:0] flip_serial [6:0];

//fsm count cost
reg count_total_valid;

//next logic
always @(posedge CLK) begin
  if (RST) begin
  // Dictionary 
      count_ws_sort    <= 3'b0;

      now_dict[0]     <=  3'd7;
      now_dict[1]     <=  3'd6;
      now_dict[2]     <=  3'd5;
      now_dict[3]     <=  3'd4;
      now_dict[4]     <=  3'd3;
      now_dict[5]     <=  3'd2;
      now_dict[6]     <=  3'd1;
      now_dict[7]     <=  3'd0;

  //fsm
      current_state_fsm   <=  3'd0;
      next_dict_temp[0]     <=  3'd0;
      next_dict_temp[1]     <=  3'd0;
      next_dict_temp[2]     <=  3'd0;
      next_dict_temp[3]     <=  3'd0;
      next_dict_temp[4]     <=  3'd0;
      next_dict_temp[5]     <=  3'd0;
      next_dict_temp[6]     <=  3'd0;
      next_dict_temp[7]     <=  3'd0;

      next_dict[0]     <=  3'd7;
      next_dict[1]     <=  3'd6;
      next_dict[2]     <=  3'd5;
      next_dict[3]     <=  3'd4;
      next_dict[4]     <=  3'd3;
      next_dict[5]     <=  3'd2;
      next_dict[6]     <=  3'd1;
      next_dict[7]     <=  3'd0;
      
  //fsm S_Start_next1
      change_point_l  <=  3'd0;
      change_point_r  <=  3'd0;
      point_l_place   <=  3'd0;

  //fsm S_Start_next1, 3 ==> flip serial
      flip2next       <=  3'd0;
      max_place       <=  3'd0;
      flip_serial[0]     <=  3'b0;
      flip_serial[1]     <=  3'b0;
      flip_serial[2]     <=  3'b0;
      flip_serial[3]     <=  3'b0;
      flip_serial[4]     <=  3'b0;
      flip_serial[5]     <=  3'b0;
      flip_serial[6]     <=  3'b0;
  //output
      Valid           <=  1'b0;
  end

  else begin
  case (current_state_fsm)
      S_idel: begin

          flip_serial[0]     <=  3'd0;
          flip_serial[1]     <=  3'd0;
          flip_serial[2]     <=  3'd0;
          flip_serial[3]     <=  3'd0;
          flip_serial[4]     <=  3'd0;
          flip_serial[5]     <=  3'd0;
          flip_serial[6]     <=  3'd0;

          next_dict_temp[0]     <=  next_dict[0];
          next_dict_temp[1]     <=  next_dict[1];
          next_dict_temp[2]     <=  next_dict[2];
          next_dict_temp[3]     <=  next_dict[3];
          next_dict_temp[4]     <=  next_dict[4];
          next_dict_temp[5]     <=  next_dict[5];
          next_dict_temp[6]     <=  next_dict[6];
          next_dict_temp[7]     <=  next_dict[7];
          
          for_change_point    <=  n;
          count_ws_sort       <=  3'd0;
          change_point_l      <=  3'd0;
          change_point_r      <=  3'd7;

        if (now_dict[7] == 3'd7 && now_dict[6] == 3'd6 && now_dict[5] == 3'd5 && now_dict[4] == 3'd4 && now_dict[3] == 3'd3 && now_dict[2] == 3'd2 && now_dict[1] == 3'd1 && now_dict[0] == 3'd0) begin
          Valid       <=  1'b1;
        end
        else begin    
          Valid         <=  1'b0;
          now_dict[0]    <=  next_dict[0];
          now_dict[1]    <=  next_dict[1];
          now_dict[2]    <=  next_dict[2];
          now_dict[3]    <=  next_dict[3];
          now_dict[4]    <=  next_dict[4];
          now_dict[5]    <=  next_dict[5];                
          now_dict[6]    <=  next_dict[6];
          now_dict[7]    <=  next_dict[7];
          current_state_fsm   <=  S_Start_next1; 
        end
      end

      S_Start_next1:begin
          if (next_dict_temp[0]>next_dict_temp[1]) begin
              change_point_l      <= count_ws_sort + 3'd1;
              point_l_place       <= count_ws_sort + 3'd1;
              current_state_fsm   <= S_Start_next2;
          end
          else begin
              count_ws_sort           <= count_ws_sort + 1'b1; 
              current_state_fsm       <= current_state_fsm; 
          end
              next_dict_temp[7]     <=  3'd0;
              next_dict_temp[6]     <=  next_dict_temp[7];
              next_dict_temp[5]     <=  next_dict_temp[6];
              next_dict_temp[4]     <=  next_dict_temp[5];
              next_dict_temp[3]     <=  next_dict_temp[4];
              next_dict_temp[2]     <=  next_dict_temp[3];
              next_dict_temp[1]     <=  next_dict_temp[2];
              next_dict_temp[0]     <=  next_dict_temp[1];       
              //flip the serial & reserve right max
              flip_serial[6]     <=  flip_serial[5];
              flip_serial[5]     <=  flip_serial[4];
              flip_serial[4]     <=  flip_serial[3];
              flip_serial[3]     <=  flip_serial[2];
              flip_serial[2]     <=  flip_serial[1];
              flip_serial[1]     <=  flip_serial[0];
              flip_serial[0]     <=  next_dict_temp[0];
      end

      S_Start_next2:begin
        flip2next <= point_l_place;
        if(change_point_l >= 3'd0 )  begin
          if(flip_serial[change_point_l-1] > next_dict_temp[0] && flip_serial[change_point_l-1] <= change_point_r) begin
            next_dict_temp[0]              <=  flip_serial[change_point_l-1];
            flip_serial[change_point_l-1]  <=  next_dict_temp[0];
            current_state_fsm <=  S_Start_next3;
          end
          else begin
            change_point_l     <=  change_point_l - 3'd1;
            current_state_fsm <=  S_Start_next2;
          end
        end
        else begin
          current_state_fsm   <=  S_Start_next3;          
        end
      end

      S_Start_next3:begin
        if ((for_change_point-point_l_place) > 3'd0) begin
            next_dict[for_change_point]     <=  next_dict_temp[for_change_point - point_l_place];
            for_change_point    <=  for_change_point    -   3'd1;
            current_state_fsm   <=  S_Start_next3;               
        end                
        else if ((for_change_point-point_l_place) == 3'd0) begin
            next_dict[for_change_point]     <=  next_dict_temp[0]; 
            for (j = 4'd0 ; j < point_l_place; j = j+1 ) begin
              next_dict[j]     <=  flip_serial[j];
            end                  
            current_state_fsm   <=  S_idel;           
        end 
      end
      default: begin
          Valid       <=  1'b0;         
      end
  endcase
  end
end

assign  W                   =  (count_total < 4'd8)? count_total : 0;
assign  J                   =  (count_total < 4'd8)? now_dict[count_total] : 0;

// cost value & output
always @(posedge CLK) begin
  if (RST) begin  
    temp_MinCost            <= 10'b0;
    count_total_valid       <= 3'd0;
    MatchCount              <= 4'b0;
    MinCost                 <= 10'd1023;
  end 
  else begin
    case (current_state_fsm)

       S_Start_next1, S_Start_next2, S_Start_next3: begin
        if (count_total == 4'd0) begin
          count_total_valid   <=  3'd1;
          temp_MinCost        <= temp_MinCost;
        end
        else if (count_total <=4'd8 && count_total > 4'd0) begin
          count_total_valid   <=  3'd1;
          temp_MinCost        <= temp_MinCost + Cost;
        end
        else begin
          count_total_valid   <=  3'd0;
          temp_MinCost        <= temp_MinCost;          
        end 
      end

      S_idel: begin
        //count_total_valid   <=  1'b0;
        if (temp_MinCost > MinCost) begin            
            MinCost     <=  MinCost;
            MatchCount  <=  MatchCount;  
        end
        else if (temp_MinCost < MinCost && (temp_MinCost != 10'd0)) begin
            MinCost     <=  temp_MinCost;
            MatchCount  <=  4'd1;                 
        end 
        else if(temp_MinCost ==  MinCost)begin
            MinCost     <=  temp_MinCost;
            MatchCount  <=  MatchCount + 4'd1; 
        end
        else begin
            MinCost     <=  MinCost;
            MatchCount  <=  MatchCount;          
        end
        temp_MinCost    <=  10'd0;
        count_total_valid   <=  3'd1;
      end
      default: begin
          count_total_valid   <=  1'b0;
          MinCost         <=  10'd1023;
      end
    endcase
  end 
end

always @(posedge CLK) begin
    if (RST) begin
      count_total    <= 4'b0;       
    end
    else if(current_state_fsm == S_idel) begin
      count_total    <= 4'b0;
    end
    else if (count_total_valid) begin    
      if (count_total <= 4'd8) begin
        count_total    <= count_total     + 4'd1;         
      end 
      else begin
        count_total    <= count_total; 
      end  
    end
    else begin
        count_total    <= count_total;     
    end
end

endmodule

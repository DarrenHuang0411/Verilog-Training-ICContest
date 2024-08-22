module Bicubic (
    input CLK,
    input RST,
    input enable,
    input [7:0] input_data,
    output logic [13:0] iaddr,
    output logic ird,
    output logic we,
    output logic [13:0] waddr,
    output logic [7:0] output_data,
    input [6:0] V0,
    input [6:0] H0,
    input [4:0] SW,
    input [4:0] SH,
    input [5:0] TW,
    input [5:0] TH,
    output logic DONE
);

//global parameter 
  integer i;
  reg [4:0] count;
  reg [2:0] count_v;
  reg [6:0] q_index_h;
  reg [6:0] q_index_v;
  
  reg [3:0] S_cur, S_nxt;
  parameter IDLE  = 4'd0,
            PX_Y  = 4'd6,
            L_D   = 4'd1,
            CAL_2 = 4'd2,
            CAL   = 4'd3,
            CAL_2_TEMP = 4'd4,
            CAL_TEMP = 4'd5,
            FINISH= 4'd8;
  
  reg [7:0] int_pol_data [0:3];
  reg [7:0] int_pol_data_16 [0:3][0:3];
//Internal Parameter
  reg [31:0] px;
  reg [31:0] py;
  reg [31:0] p_place;
  reg [7:0] cal_data [0:3];

  reg signed [32:0] a;
  reg signed [32:0] b;
  reg signed [32:0] c;
  reg signed [32:0] d;   
  reg [63:0] px_1; 
  wire [31:0] px_1_r;      
  wire [63:0] px_2;  
  wire [31:0] px_2_r;
  wire signed [63:0] px_o1; 
  wire signed [63:0] px_o2; 
  wire signed [63:0] px_o3; 
  wire signed [31:0] px_o1_r; 
  wire signed [31:0] px_o2_r; 
  wire signed [31:0] px_o3_r; 
  wire signed [31:0] px_output;
//Calculate
  //polynomial
  always @(posedge CLK or posedge RST) begin
    if (RST) begin
      px <= 32'd0;
      py <= 32'd0;
    end 
    else if(S_cur == PX_Y)begin
      px <=  (((SW - 1) << 23) / (TW-1) * q_index_h);
      py <=  (((SH - 1) << 23) / (TH-1)  * q_index_v);      
    end
  end

//REVISE   
    always @(*) begin
      p_place = px;
      if(q_index_h == 0 || q_index_h == TW -1)
        p_place = py;
      else if(q_index_v == 0 || q_index_v == TH -1)
        p_place = px;
      else begin
        if(S_cur == CAL || S_cur == CAL_TEMP)
            p_place = py;
        else  
            p_place = px;
      end
    end
    // assign  cal_data;
    always @(*) begin
      cal_data[0] =  int_pol_data_16[count_v][0];  
      cal_data[1] =  int_pol_data_16[count_v][1];
      cal_data[2] =  int_pol_data_16[count_v][2];
      cal_data[3] =  int_pol_data_16[count_v][3];
      if (S_cur == CAL) begin
        cal_data[0] =  int_pol_data[0];  
        cal_data[1] =  int_pol_data[1];
        cal_data[2] =  int_pol_data[2];
        cal_data[3] =  int_pol_data[3];        
      end         
    end
//
    always @(posedge CLK or posedge RST) begin
      if (RST) begin
        a   <=  33'd0;
        b   <=  33'd0;
        c   <=  33'd0;
        d   <=  33'd0;                        
      end 
      else if(S_cur == CAL || S_cur == CAL_2) begin
        a  <=  ($signed(33'h1_ffc0_0000) * $signed({1'b0, cal_data[0]}) 
                + $signed(33'h0_00c0_0000) * $signed({1'b0, cal_data[1]})) 
                + ($signed(33'h1_ff40_0000) * $signed({1'b0, cal_data[2]}) 
                + $signed(33'h0_0040_0000) * $signed({1'b0, cal_data[3]}));
        b  <=  ($signed({2'd0 , cal_data[0] , 23'd0}) 
                + $signed(33'h1_fec0_0000) * $signed({1'b0, cal_data[1]}))
                + ($signed(33'h0_0100_0000) * $signed({1'b0, cal_data[2]})
                + $signed(33'h1_ffc0_0000) * $signed({1'b0, cal_data[3]}));
        c  <=  $signed(33'h1_ffc0_0000) * $signed({1'b0, cal_data[0]}) 
                + $signed(33'h0_0040_0000) * $signed({1'b0, cal_data[2]}) ;
        d  <=  (cal_data[1] << 23);

        px_1 <= p_place[22:0] * p_place[22:0];
      end
    end

    assign  px_1_r = (px_1[22:0] >= 23'h40_0000) ? px_1[54:23] + 1 : px_1[54:23];
    assign  px_2   = px_1_r * p_place[22:0];
    assign  px_2_r = (px_2[22:0] >= 23'h40_0000) ? px_2[54:23] + 1 : px_2[54:23];    
    //* p_place * p_place; 
    assign  px_o1 = $signed({1'b0, px_2_r}) * a; 
    assign  px_o2 = $signed({1'b0, px_1_r}) * b; 
    assign  px_o3 = $signed({1'b0, p_place[22:0]}) * c; 

    assign  px_o1_r = (px_o1[22:0] >= 23'h40_0000) ? px_o1[54:23] + 1 : px_o1[54:23];
    assign  px_o2_r = (px_o2[22:0] >= 23'h40_0000) ? px_o2[54:23] + 1 : px_o2[54:23];
    assign  px_o3_r = (px_o3[22:0] >= 23'h40_0000) ? px_o3[54:23] + 1 : px_o3[54:23];
  //Final value
    assign px_output = px_o1_r + px_o2_r + px_o3_r + d;

  //Control Signal 
    assign ird  = (S_cur == L_D)    ? 1'b1  : 1'b0;
    assign we   = (S_cur == CAL_TEMP)    ? 1'b1  : 1'b0;
    assign DONE = (S_cur == FINISH) ? 1'b1  : 1'b0;

  //Counter 
    always @(posedge CLK or posedge RST) begin
      if (RST)  count <=  4'd0;
      else begin
        case (S_cur)
          L_D: count <= (count == 3'd4) ? 4'd0 : count + 1'd1;
          CAL_TEMP: count <= 5'd0;
          default: count <=  count; 
        endcase
      end
    end
    //counter_v
    always @(posedge CLK or posedge RST) begin
      if (RST)  count_v <=  4'd0;
      else begin
        case (S_cur)
          CAL_TEMP: count_v <= 5'd0;
          CAL_2_TEMP:  count_v <=  count_v + 1'd1;
          default: count_v <=  count_v; 
        endcase
      end
    end

  //q_index_h  
    always @(posedge CLK or posedge RST) begin
      if (RST)  q_index_h <=  7'd0;
      else if (S_cur == CAL_TEMP)begin
        q_index_h <=  (q_index_h == TW-1) ? 7'd0 : q_index_h + 1; 
      end
    end
  
  //q_index_v
    always @(posedge CLK or posedge RST) begin
      if (RST)  q_index_v <=  7'd0;
      else if (S_cur == CAL_TEMP)begin
        q_index_v <=  (q_index_v == TH -1 && q_index_h == TW -1) ? 7'd0 : (q_index_h == TW-1) ? q_index_v + 1 : q_index_v; 
      end
    end

  //FSM
    always @(posedge CLK or posedge RST) begin
      S_cur <=  (RST) ? IDLE :  S_nxt;
    end
    always @(*) begin
      case (S_cur)
        IDLE:     S_nxt = (enable)        ? PX_Y : IDLE;
        PX_Y:     S_nxt = L_D;
        L_D : begin
          if(q_index_h == 0 && q_index_v == 0)
            S_nxt = (count == 5'd1) ? CAL : L_D;
          else if(q_index_h == TW -1  && q_index_v == 0)
            S_nxt = (count == 5'd1) ? CAL : L_D;
          else if(q_index_v == 0)
            S_nxt = (count == 5'd4) ? CAL : L_D;
          else if(q_index_h == 0  && q_index_v == TH -1)
            S_nxt = (count == 5'd1) ? CAL : L_D;
          else if(q_index_h == 0)
            S_nxt = (count == 5'd4) ? CAL : L_D;
          else if(q_index_h == TW-1  && q_index_v == TH -1)
            S_nxt = (count == 5'd1) ? CAL : L_D;
          else if(q_index_h == TW-1)
            S_nxt = (count == 5'd4) ? CAL : L_D;
          else if(q_index_v == TH-1)
            S_nxt = (count == 5'd4) ? CAL : L_D;
          else       
            S_nxt = (count == 3'd4) ? CAL_2 : L_D;
        end     
        CAL :     S_nxt = CAL_TEMP;
        CAL_TEMP: S_nxt = ((q_index_h == (TW -1)) && (q_index_v == (TH -1))) ? FINISH : PX_Y;
        CAL_2:    S_nxt = CAL_2_TEMP;
        CAL_2_TEMP: S_nxt = (count_v == 3'd3) ? CAL : PX_Y;
        FINISH:   S_nxt = IDLE; 
        default:  S_nxt = IDLE; 
      endcase  
    end

  //Data Load
    //assign iaddr  = (H0 - 1 + px[19:8] + count) * 100 + V0;
    always @(*) begin
      if(q_index_h == 0 && q_index_v == 0)
        iaddr  = H0 * 100 + V0;

      else if(q_index_h == TW -1  && q_index_v == 0)
        iaddr  = (H0 + SW -1) * 100 + V0;

      else if(q_index_v == 0)
        iaddr  = (H0 + px[31:23] + count -1) * 100 + V0;

      else if(q_index_h == 0  && q_index_v == TH -1)
        iaddr  = H0  * 100 + (V0 + SH -1);
      
      else if(q_index_h == 0)
        iaddr  = H0  * 100 + (V0 + py[31:23] + count - 1);

      else if(q_index_h == TW-1  && q_index_v == TH -1)
        iaddr  = (H0 +SW -1) * 100 + (V0 + SH -1);        

      else if(q_index_h == TW-1) 
        iaddr  = (H0 + SW -1) * 100 + (V0 + py[31:23] + count - 1);

      else if(q_index_v == TH-1)
        iaddr  = (H0 + px[31:23] + count -1) * 100 + (V0 + SH - 1);
      
      else
        iaddr  = (H0 + px[31:23] + count -1) * 100 + (V0 + py[31:23] + count_v - 1); 
    end

    always @(posedge CLK) begin
      if(S_cur == CAL_2_TEMP)
        int_pol_data[count_v] <=  output_data;
      else if (S_cur == L_D && count >= 1) begin
          if (q_index_h != 0 && q_index_v != 0 && q_index_h != TW - 1 && q_index_v != TH - 1)
            int_pol_data_16[count_v][count -1] <= input_data;
          else        
            int_pol_data[count - 1] <=  input_data;
      end
    end

  //output data
    always @(*) begin
      if(q_index_h == 0 && q_index_v == 0)
        output_data = int_pol_data[0];
      else if(q_index_h == TW -1  && q_index_v == 0)
        output_data = int_pol_data[0];
      else if(q_index_h == 0  && q_index_v == TH -1 )
        output_data = int_pol_data[0];
      else if(q_index_h == TW -1  && q_index_v == TH - 1)
        output_data = int_pol_data[0];
      else
        if(px_output[31])
          output_data = 0;
        else
          output_data =  (px_output[22:0] >= 23'h40_0000) ? px_output[30:23] + 1 : px_output[30:23];     
    end

  //Data Store
    assign waddr  = q_index_v * TW + q_index_h;    
endmodule

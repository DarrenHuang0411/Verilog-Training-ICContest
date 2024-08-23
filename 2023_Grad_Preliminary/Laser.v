`define minus_abs(a,b) ((a>b) ? a-b : b-a)

module Laser (
  input              CLK,
  input              RST,
  input      [3:0]     X,
  input      [3:0]     Y,
  input            valid,
  output reg [3:0]   C1X,
  output reg [3:0]   C1Y,
  output reg [3:0]   C2X,
  output reg [3:0]   C2Y,
  output reg        DONE
);


//Global Parameter
  //integer
    integer i;
  //Counter
    reg [5:0] Count_RD;// 40 times 
  //FSM
    reg [2:0] S_cur, S_nxt;
    parameter   IDLE    = 3'd0,
                READ    = 3'd1,
                CIR1    = 3'd2,
                CIR2    = 3'd3,
                STOP    = 3'd4,
                STOP2   = 3'd5,
                CHANGE  = 3'd6,
                FINISH  = 3'd7;
  //REG 40 data x/y
    reg [3:0] info_x[39:0];
    reg [3:0] info_y[39:0];
  //CIR1_2
    //CAL distance
    // wire tempc1_x, tempc1_y;
    wire  [3:0] dis_x, dis_y, check_c1x, check_c1y;
    wire  cover_check;

    wire check_flag_c0, check_flag_c1, check_flag_c2, check_flag_c3, check_flag_c4, check_flag_c5, check_flag_c6, check_flag_c7, check_flag_c8, check_flag_c9;

    reg [3:0] tempc1_x, tempc1_y;
    reg [2:0] Counter_iteration;
  //cover temp
    reg [7:0] cover_temp;
    reg [5:0] Counter_overlap;
    reg [7:0] R_C, R_C_2,R_C_FINAL, R_C_check;

    wire [7:0] cover_temp_30;


//Counter
    always @(posedge CLK or posedge RST) begin
      if (RST) begin
        Count_RD  <=  6'd0;
      end 
      else begin
        case (S_cur)
          READ: begin
            if(Count_RD == 6'd40) Count_RD  <=  6'd0;
            else begin
              if (valid) Count_RD   <= Count_RD + 6'd1; 
              else Count_RD   <= Count_RD; 
            end  
          end
          CIR1, CIR2: begin
            if (Count_RD == 6'd30) begin
              Count_RD  <=  6'd0;                                   
            end 
            else begin
              Count_RD  <=  Count_RD  + 6'd10;                  
            end
          end 
          default:  begin
            Count_RD  <=  6'd0;
          end             
        endcase  
        // end
      end
    end
//Counter c1_xy c2_xy
    always @(posedge CLK or posedge RST) begin
      if (RST) begin
        tempc1_x  <=  4'd0;
        tempc1_y  <=  4'd0;
      end 
      else begin
        if ((S_cur == CIR1 || S_cur == CIR2) && Count_RD == 6'd30) begin
          if (tempc1_x == 4'd15 && tempc1_y == 4'd15) begin
            tempc1_x  <=  4'd0;
            tempc1_y  <=  4'd0;     
          end
          else if (tempc1_x == 4'd15 && tempc1_y != 4'd15) begin
            tempc1_x  <=  4'd0;
            tempc1_y  <=  tempc1_y  + 4'd1;     
          end           
          else begin
            tempc1_x  <=  tempc1_x  + 4'd1;
            tempc1_y  <=  tempc1_y;              
          end          
        end 
        else begin
          tempc1_x  <=  tempc1_x;
          tempc1_y  <=  tempc1_y;             
        end
      end
    end
//FSM Seq.
    always @(posedge CLK or posedge RST) begin
        if (RST)    S_cur   <=  IDLE;
        else        S_cur   <=  S_nxt;
    end
//FSM Comb.
    always @(*) begin
        if (RST) begin
            S_nxt  = IDLE;
        end 
        else begin
            case (S_cur)
            IDLE:                     S_nxt  = READ;
            READ: begin
              if (Count_RD == 6'd40)  S_nxt  = CIR1;
              else                    S_nxt  = READ;
            end
            // STOP: begin
            //   S_nxt   = CIR1;           
            // end
            CIR1: begin
              if (Count_RD == 6'd30) begin
                if (tempc1_x == 15 && tempc1_y == 15)  S_nxt  = CIR2;
                else  S_nxt   = CIR1;                 
              end
              else begin
                S_nxt   = CIR1;
              end
            end
            // STOP2: begin
            //   S_nxt   = CIR2;               
            // end 
            CIR2: begin
              if (Count_RD == 6'd30) begin
                if (tempc1_x == 15 && tempc1_y == 15)  S_nxt  = CHANGE;
                else  S_nxt   = CIR2;                 
              end
              else begin
                S_nxt   = CIR2;
              end
            end              
            CHANGE: begin
              if (Counter_iteration == 3'd3) S_nxt  = FINISH;              
              else                 S_nxt  = CIR2;              
            end
            FINISH:  S_nxt  = IDLE;
            default: S_nxt  = S_nxt;
            endcase        
        end    
    end
//Data in
    always @(posedge CLK or posedge RST) begin
      if (RST) begin
        for (i = 0; i <= 39; i = i+1) begin
          info_x[i]    <=  4'd0;
          info_y[i]    <=  4'd0;
        end
      end 
      else begin
        if (S_cur == READ && valid) begin
          info_x[Count_RD]  <= X;
          info_y[Count_RD]  <= Y;          
        end 
        else begin
          for (i = 0; i <= 39; i = i+1) begin
            info_x[i]    <=  info_x[i];
            info_y[i]    <=  info_y[i];
          end           
        end
      end
    end
//Cal.
    assign  dis_x = `minus_abs(tempc1_x, info_x[Count_RD]);
    assign  dis_y = `minus_abs(tempc1_y, info_y[Count_RD]);
  ////2nd version
    wire  [3:0] dis_x1, dis_y1;
    wire  [3:0] dis_x2, dis_y2;
    wire  [3:0] dis_x3, dis_y3;
    wire  [3:0] dis_x4, dis_y4; 
    wire  [3:0] dis_x5, dis_y5;
    wire  [3:0] dis_x6, dis_y6; 
    wire  [3:0] dis_x7, dis_y7;
    wire  [3:0] dis_x8, dis_y8; 
    wire  [3:0] dis_x9, dis_y9;

    assign  dis_x1 = `minus_abs(tempc1_x, info_x[Count_RD +1]);
    assign  dis_y1 = `minus_abs(tempc1_y, info_y[Count_RD +1]);
    assign  dis_x2 = `minus_abs(tempc1_x, info_x[Count_RD +2]);
    assign  dis_y2 = `minus_abs(tempc1_y, info_y[Count_RD +2]);
    assign  dis_x3 = `minus_abs(tempc1_x, info_x[Count_RD +3]);
    assign  dis_y3 = `minus_abs(tempc1_y, info_y[Count_RD +3]);
    assign  dis_x4 = `minus_abs(tempc1_x, info_x[Count_RD +4]);
    assign  dis_y4 = `minus_abs(tempc1_y, info_y[Count_RD +4]);
    assign  dis_x5 = `minus_abs(tempc1_x, info_x[Count_RD +5]);
    assign  dis_y5 = `minus_abs(tempc1_y, info_y[Count_RD +5]);
    assign  dis_x6 = `minus_abs(tempc1_x, info_x[Count_RD +6]);
    assign  dis_y6 = `minus_abs(tempc1_y, info_y[Count_RD +6]);
    assign  dis_x7 = `minus_abs(tempc1_x, info_x[Count_RD +7]);
    assign  dis_y7 = `minus_abs(tempc1_y, info_y[Count_RD +7]);
    assign  dis_x8 = `minus_abs(tempc1_x, info_x[Count_RD +8]);
    assign  dis_y8 = `minus_abs(tempc1_y, info_y[Count_RD +8]);
    assign  dis_x9 = `minus_abs(tempc1_x, info_x[Count_RD +9]);
    assign  dis_y9 = `minus_abs(tempc1_y, info_y[Count_RD +9]);

    wire  line_addr0, line_addr1, line_addr2, line_addr3, line_addr4, line_addr5, line_addr6, line_addr7, line_addr8, line_addr9;

    function line_addr;
      input [3:0] x, y;
      input c_f;
      begin
        if (S_cur == CIR1) begin
          case (x)
            4'd0: line_addr  = (y <= 4'd4) ? 1'b1: 1'b0;
            4'd1: line_addr  = (y <= 4'd3) ? 1'b1: 1'b0;
            4'd2: line_addr  = (y <= 4'd3) ? 1'b1: 1'b0;
            4'd3: line_addr  = (y <= 4'd2) ? 1'b1: 1'b0;
            4'd4: line_addr  = (y <= 4'd0) ? 1'b1: 1'b0;
            default: line_addr = 1'b0;
          endcase          
        end 
        else if (S_cur == CIR2 && !c_f) begin
          case (x)
            4'd0: line_addr  = (y <= 4'd4) ? 1'b1: 1'b0;
            4'd1: line_addr  = (y <= 4'd3) ? 1'b1: 1'b0;
            4'd2: line_addr  = (y <= 4'd3) ? 1'b1: 1'b0;
            4'd3: line_addr  = (y <= 4'd2) ? 1'b1: 1'b0;
            4'd4: line_addr  = (y <= 4'd0) ? 1'b1: 1'b0;
            default: line_addr = 1'b0;
          endcase 
        end      
        else begin
          line_addr = 1'b0;
        end
      end      
    endfunction

    assign  line_addr0  =   line_addr(dis_x , dis_y , check_flag_c0);
    assign  line_addr1  =   line_addr(dis_x1, dis_y1, check_flag_c1);
    assign  line_addr2  =   line_addr(dis_x2, dis_y2, check_flag_c2);
    assign  line_addr3  =   line_addr(dis_x3, dis_y3, check_flag_c3);
    assign  line_addr4  =   line_addr(dis_x4, dis_y4, check_flag_c4);
    assign  line_addr5  =   line_addr(dis_x5, dis_y5, check_flag_c5);
    assign  line_addr6  =   line_addr(dis_x6, dis_y6, check_flag_c6);
    assign  line_addr7  =   line_addr(dis_x7, dis_y7, check_flag_c7);
    assign  line_addr8  =   line_addr(dis_x8, dis_y8, check_flag_c8);
    assign  line_addr9  =   line_addr(dis_x9, dis_y9, check_flag_c9);       
  ////2nd version
    assign  check_c1x = `minus_abs(C1X, info_x[Count_RD]);
    assign  check_c1y = `minus_abs(C1Y, info_y[Count_RD]);
  ////3rd version
    wire  [3:0]    check_c1x1 , check_c1y1 ;
    wire  [3:0]    check_c1x2 , check_c1y2 ;
    wire  [3:0]    check_c1x3 , check_c1y3 ;
    wire  [3:0]    check_c1x4 , check_c1y4 ;
    wire  [3:0]    check_c1x5 , check_c1y5 ;
    wire  [3:0]    check_c1x6 , check_c1y6 ;
    wire  [3:0]    check_c1x7 , check_c1y7 ;
    wire  [3:0]    check_c1x8 , check_c1y8;
    wire  [3:0]    check_c1x9 , check_c1y9;    
    assign  check_c1x1 = `minus_abs(C1X, info_x[Count_RD + 1]);
    assign  check_c1y1 = `minus_abs(C1Y, info_y[Count_RD + 1]);
    assign  check_c1x2 = `minus_abs(C1X, info_x[Count_RD + 2]);
    assign  check_c1y2 = `minus_abs(C1Y, info_y[Count_RD + 2]);
    assign  check_c1x3 = `minus_abs(C1X, info_x[Count_RD + 3]);
    assign  check_c1y3 = `minus_abs(C1Y, info_y[Count_RD + 3]);
    assign  check_c1x4 = `minus_abs(C1X, info_x[Count_RD + 4]);
    assign  check_c1y4 = `minus_abs(C1Y, info_y[Count_RD + 4]);
    assign  check_c1x5 = `minus_abs(C1X, info_x[Count_RD + 5]);
    assign  check_c1y5 = `minus_abs(C1Y, info_y[Count_RD + 5]);
    assign  check_c1x6 = `minus_abs(C1X, info_x[Count_RD + 6]);
    assign  check_c1y6 = `minus_abs(C1Y, info_y[Count_RD + 6]);
    assign  check_c1x7 = `minus_abs(C1X, info_x[Count_RD + 7]);
    assign  check_c1y7 = `minus_abs(C1Y, info_y[Count_RD + 7]);    
    assign  check_c1x8 = `minus_abs(C1X, info_x[Count_RD + 8]);
    assign  check_c1y8 = `minus_abs(C1Y, info_y[Count_RD + 8]); 
    assign  check_c1x9 = `minus_abs(C1X, info_x[Count_RD + 9]);
    assign  check_c1y9 = `minus_abs(C1Y, info_y[Count_RD + 9]); 


    assign  cover_check = (S_cur == CIR1 && tempc1_x == 4'd15 && tempc1_y == 4'd15 && Count_RD == 6'd30) ? 1'b1 : 1'b0;

    always @(posedge CLK or posedge RST) begin
      if (RST) begin
        cover_temp  <= 8'd0;
        Counter_overlap <= 6'd0;
      end
      else if (cover_check ==  1'b1) begin
        cover_temp  <= 8'd0;
        Counter_overlap <= Counter_overlap  + 6'd1;
      end
      else begin
        if (S_cur == CIR1 && Count_RD != 6'd30) begin
          cover_temp  <= cover_temp + (line_addr0 + line_addr1)+(line_addr2 + line_addr3)+(line_addr4 + line_addr5)+(line_addr6 + line_addr7)+(line_addr8 + line_addr9);
        end

        else if (S_cur == CIR2 && Count_RD != 6'd30) begin
          cover_temp  <= cover_temp + (line_addr0 + line_addr1)+(line_addr2 + line_addr3)+(line_addr4 + line_addr5)+(line_addr6 + line_addr7)+(line_addr8 + line_addr9);
        end        
        else if ((S_cur == CIR1 || S_cur == CIR2) && Count_RD == 6'd30) begin
          cover_temp <= 8'd0;
        end
      end
    end
  // Check overlap 
    function check_overlap;
      input [3:0] c_x, c_y;
      begin
        case (c_x)
          4'd0: check_overlap  = (c_y <= 4'd4) ? 1'd1: 1'd0;
          4'd1: check_overlap  = (c_y <= 4'd3) ? 1'd1: 1'd0;
          4'd2: check_overlap  = (c_y <= 4'd3) ? 1'd1: 1'd0;
          4'd3: check_overlap  = (c_y <= 4'd2) ? 1'd1: 1'd0;
          4'd4: check_overlap  = (c_y <= 4'd0) ? 1'd1: 1'd0;
          default: check_overlap  = 1'b0;
        endcase        
      end
    endfunction
    assign  check_flag_c0  =   check_overlap(check_c1x , check_c1y);
    assign  check_flag_c1  =   check_overlap(check_c1x1, check_c1y1);
    assign  check_flag_c2  =   check_overlap(check_c1x2, check_c1y2);
    assign  check_flag_c3  =   check_overlap(check_c1x3, check_c1y3);
    assign  check_flag_c4  =   check_overlap(check_c1x4, check_c1y4);
    assign  check_flag_c5  =   check_overlap(check_c1x5, check_c1y5);
    assign  check_flag_c6  =   check_overlap(check_c1x6, check_c1y6);
    assign  check_flag_c7  =   check_overlap(check_c1x7, check_c1y7);
    assign  check_flag_c8  =   check_overlap(check_c1x8, check_c1y8);
    assign  check_flag_c9  =   check_overlap(check_c1x9, check_c1y9);


  ////3rd version
//Out Result
    always @(posedge CLK or posedge RST) begin
      if (RST) begin
        C1X <=  4'd0;
        C1Y <=  4'd0;
        C2X <=  4'd0;
        C2Y <=  4'd0; 
      end
      else if (cover_check ==  1'b1) begin
        C2X <=  4'd0;
        C2Y <=  4'd0;
      end 
      else begin
        if (S_cur == CIR1  && Count_RD == 6'd30) begin
          if (cover_temp_30 >= R_C) begin
            C1X <=  tempc1_x;
            C1Y <=  tempc1_y;
          end
        end
        else if (S_cur == CIR2  && Count_RD == 6'd30) begin
          if (R_C + cover_temp_30 >= R_C_FINAL) begin
            C2X <=  tempc1_x;
            C2Y <=  tempc1_y;
          end          
        end 
        else if (S_cur == CHANGE) begin
          if (Counter_iteration == 3'd3) begin
            C1X <=  C1X;
            C1Y <=  C1Y;  
            C2X <=  C2X;
            C2Y <=  C2Y;            
          end 
          else begin
            C1X <=  C2X;
            C1Y <=  C2Y;  
            C2X <=  4'd0;
            C2Y <=  4'd0;           
          end        
        end    
      end 
    end
// R_C refresh
    always @(posedge CLK or posedge RST) begin
      if(RST) begin
        R_C       <=  8'd0;       
        R_C_FINAL <=  8'd0;
      end
      else begin
        if ((S_cur == CIR1 && Count_RD == 6'd30) && cover_temp_30 >= R_C) begin
          R_C      <=  cover_temp_30;
          R_C_FINAL <=  cover_temp_30;
        end
        else if (S_cur == CIR2 && Count_RD == 6'd30) begin
          // if (tempc1_x == 4'd15 && tempc1_y == 4'd15) begin
          //   R_C_FINAL  <=  8'd0;
          // end 
          // else begin          
            R_C_FINAL  <= (R_C + cover_temp_30 >= R_C_FINAL) ? (R_C + cover_temp_30) : R_C_FINAL;          
          // end
        end          
        else if (S_cur  ==  CHANGE) begin
          R_C <=  R_C_2;
          R_C_FINAL <=  8'd0;
        end        
      end         
    end
//R_c_2 refresh
    always @(posedge CLK or posedge RST) begin
      if(RST) begin
        R_C_2       <=  8'd0;       
      end
      else begin
        if (S_cur == CIR2 && Count_RD == 6'd30) begin
          // if (tempc1_x == 4'd15 && tempc1_y == 4'd15) begin
          //   R_C_2  <=  8'd0;
          // end 
          // else begin          
            R_C_2  <= (cover_temp_30 + Counter_overlap >= R_C_2) ? (cover_temp_30 + Counter_overlap) : R_C_2;          
          // end
        end
        else if(S_cur == CHANGE) begin
          R_C_2       <=  8'd0;
        end
      end        
    end
//Cover_result//Counter iteration
    always @(posedge CLK or posedge RST) begin
      if(RST) begin
        R_C_check     <=  8'd0;
        Counter_iteration  <=  2'd0;
      end        
      else begin
        if (S_cur == CHANGE)  begin
          if (R_C_FINAL <= R_C_check) begin
            R_C_check     <=  R_C_check;
            Counter_iteration  <= Counter_iteration + 2'd1;            
          end 
          else begin
            R_C_check     <=  R_C_FINAL;
            Counter_iteration  <= 2'd1;              
          end 
        end
        else  begin
          R_C_check     <=  R_C_check;
          Counter_iteration  <=  Counter_iteration;
        end
      end         
    end
  
  assign  cover_temp_30 = cover_temp + (line_addr0 + line_addr1)+(line_addr2 + line_addr3)+(line_addr4 + line_addr5)+(line_addr6 + line_addr7)+(line_addr8 + line_addr9);

//Control Signal
    always @(posedge CLK or posedge RST) begin
      if(RST)                   DONE     <=  1'b0;
      else begin
          if (S_cur == FINISH)  DONE     <=  1'b1;  
          else                  DONE     <=  1'b0; 
      end    
    end

endmodule

`default_nettype none

module i_read_control(
    input wire          clk,                     // clk \BD\C5ȣ
    input wire          reset,                   // reset \BD\C5ȣ
    input wire          sudo_reset,                   // reset \BD\C5ȣ    

    input wire   [9:0]  in_row_size,             // \C0Է\C2 \B5\A5\C0\CC\C5\CD \B0\A1\B7\CE \B1\E6\C0\CC
    input wire   [9:0]  in_column_size,          // \C0Է\C2 \B5\A5\C0\CC\C5\CD \BC\BC\B7\CE \B1\E6\C0\CC
    input wire   [2:0]  kernel,                  // kernel \BB\E7\C0\CC\C1\EE
    input wire          i_valid,                 // \B8\F0\B5\E2 \BD\C3\C0\DB \BD\C5ȣ
    input wire          i_start,                 // \C1߰\A3\C0\C7 \BD\C3\C0۽\C5ȣ
    //input wire          i_pause,                 //i_read_control \C1\DF\C1\F6 \BD\C5ȣ
    input wire   [1:0]  padding,                 // padding \B0\AA
    input wire   [1:0]  stride,                  // stride \B0\AA
    input wire   [1:0]  case_N,                  // BRAM\BF\A1 \C0\FA\C0\E5\B5\C8 input\C0\CC \B8\EE\B9\F8° slice\C0\CE\C1\F6 \BE˷\C1\C1ִ\C2 \BD\C5ȣ
    input wire   [11:0]  channel,                 // input \B0\AA\C0\C7 channel \BC\F6\B8\A6 \BE˷\C1\C1ִ\C2 \BD\C5ȣ
    input wire           clear,                   //
   
    output reg          o_final,
    output reg   [3:0]  o_stage,                 // padding\C0\C7 \C0\AF\B9\AB    
    output reg          o_valid,                 // output address \C0\AFȿ \BD\C5ȣ
    output reg   [14:0] o_addr                   // output address
);

localparam     IDLE       = 0,
               case_1     = 1,
               case_2     = 2,
               case_3     = 3,
               done       = 10;


    reg [9:0]  channel_cnt;                     // 현재 읽고 있는 주소의 channel을 의미한다                      
    reg [9:0]  row_cnt;                         // 현재 읽고 있는 주소의 row를 의미한다
    reg [12:0] column_cnt;                      // 현재 읽고 있는 주소의 column을 의미한다    
    reg [9:0]  B_row_cnt;                       // 현재 읽고 있는 주소의 B_row를 의미한다
    reg [12:0] B_column_cnt;                    // 현재 읽고 있는 주소의 B_column을 의미한다  
    reg [9:0]  s_row_cnt;                       // 현재 읽고 있는 주소의 S_row를 의미한다
    reg [12:0] s_column_cnt;                    // 현재 읽고 있는 주소의 S_column을 의미한다  
    reg [19:0] next_input;                      // 현재 몇개의 주소 묶음을 출력하였는지를 의미한다.
    reg [1:0] state, n_state;                   // 현재 상태와 다음 상태를 나타내기 위한 레지스터이다.
    reg [2:0] padding_consider_cnt_r;           // 각 case마다 가로 패딩을 고려해주기 위한 레지스터이다.
    reg [2:0] padding_consider_cnt_c;           // 각 case마다 세로 패딩을 고려해주기 위한 레지스터이다.
    reg finish;                                 // case가 끝났음을 알리는 신호      
    reg valid;


    always @(posedge clk or negedge reset) begin                                                              
        if (!reset) begin                                                                                      
            state  <= IDLE;                                              
        end 
        else if (sudo_reset) begin                                                                                      
            state  <= IDLE;                                              
        end 
        else begin                                                                                      
            state <= n_state;                                                                                
        end                                                                                                  
    end  
   
    always@(*)begin
        n_state = state;  
        case(state)
            IDLE: begin
                if(i_valid==1)begin               //i_pause값이 1이 되었을때 작업을 중단한다
                    n_state = case_N;
                end
            end
            case_1: begin                                       //case_1인 경우 시작
                if(finish==1) begin
                n_state=done;
                end
            end
            case_2: begin                                       //case_1인 경우 시작
                if(finish==1) begin
                n_state=done;
                end
            end
            case_3: begin                                       //case_1인 경우 시작
                if(finish==1) begin
                n_state=done;
                end
            end
            done: begin
               // n_state = IDLE;            
            end
                                                            //case_1인 경우 끝
        endcase
    end
    always@(posedge clk or negedge reset)begin
        if(!reset)begin
            channel_cnt            <= 0;
            row_cnt                <= 0;
            column_cnt             <= 0;    
            next_input             <= 0;      
            padding_consider_cnt_c <= 0;  
            padding_consider_cnt_r <= 0;
            B_row_cnt              <= 0;
            B_column_cnt           <= 0;      
            finish                 <= 0;  
            s_row_cnt              <= 1;
            s_column_cnt           <= 0;
            valid                  <= 0;
            o_final                <= 0;
            o_addr                 <= 0;
            o_valid                <= 0;
            o_stage                <= 0;
        end
        else if(clear||sudo_reset)begin
            state                  <= state;  
            channel_cnt            <= 0;
            row_cnt                <= 0;
            column_cnt             <= 0;    
            next_input             <= 0;      
            padding_consider_cnt_c <= 0;  
            padding_consider_cnt_r <= 0;
            B_row_cnt              <= 0;
            B_column_cnt           <= 0;      
            finish                 <= 0;  
            s_row_cnt              <= 1;
            s_column_cnt           <= 0;
            valid                  <= 0;
            o_final                <= 0;
            o_addr                 <= 0;
        end
      
       
        else if(state == case_1)begin
            if(padding==2) begin
              if (valid == 0)begin
                o_valid <= 0;
              end
              if(i_start)begin
                valid <= 1;
           
              end
              if(valid == 1)begin                                                               //padding이 2인 경우 시작
                o_valid<=1;                                                                     //o_addr이 유효함을 의미
                o_addr<=(channel_cnt*in_row_size/4*(in_column_size))     //channel이 넘어가는 경우 주소값 계산
                + ((B_row_cnt*5)-1%(B_row_cnt+1))                                               //B_row_cnt가 넘어가는 경우 주소값 계산
                + ((B_column_cnt-padding_consider_cnt_r)*in_row_size/4*stride)                  //B_column_cnt가 넘어가는 경우 주소값 계산
                + (s_row_cnt/2-padding_consider_cnt_c)                                          //s_row_cnt가 넘어가는 경우 주소 값 계산
                + (in_row_size*column_cnt/4)                                                    //column이 넘어가는 경우 주소값 계산
                + (row_cnt)                                                                     //row가 넘어가는 경우 주소값 계산
                ;
               if(B_row_cnt==in_row_size/(10*stride)-1&&B_column_cnt==(in_column_size-kernel+padding)/stride&&channel_cnt==channel-1&&s_row_cnt==10&&column_cnt==kernel-padding*(1-padding_consider_cnt_r)-1&&row_cnt==0) begin                                              //case_1인 경우 끝&& 초기화 시작
                  finish<=1;
                  o_final <= 1;
                  B_column_cnt<=0;
                  padding_consider_cnt_r<=0;
                  B_row_cnt<=0;
                  s_row_cnt<=1;
                  column_cnt<=0;
                  row_cnt<=0;
                  channel_cnt<=0;
                  padding_consider_cnt_c<=0;
                  valid <= 0;
               end  // 초기화 끝  
               else if (B_column_cnt<(in_column_size-kernel+padding)/stride&&B_row_cnt==in_row_size/(10*stride)-1&&channel_cnt==channel-1&&s_row_cnt==10&&column_cnt==kernel-padding*(1-padding_consider_cnt_r)-1&&row_cnt==0) begin             //B_column_cnt를 끝까지 실행 시작
                     padding_consider_cnt_r<=1;
                     B_column_cnt<=B_column_cnt+1;
                     valid      <= 0;
                     B_row_cnt<=0;
                     s_row_cnt<=1;
                     column_cnt<=0;
                     row_cnt<=0;
                     channel_cnt<=0;
                     padding_consider_cnt_c<=0;
               end                                                      //B_column_cnt를 끝까지 실행 끝
               else if (B_row_cnt<in_row_size/(10*stride)-1&&B_row_cnt!=0) begin                 //B_row_cnt가 한줄이 진행중
                    row_cnt<=row_cnt+1;
                    o_stage <=(padding_consider_cnt_r==0)? 2 : 5;
                        if(channel_cnt==channel-1&&s_row_cnt==10&&column_cnt==kernel-padding*(1-padding_consider_cnt_r)-1&&row_cnt==1)begin
                            B_row_cnt<=B_row_cnt+1;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=0;
                            channel_cnt<=0;
                            padding_consider_cnt_c<=0;
                            valid      <= 0;
                        end
                        else if(s_row_cnt==10&&column_cnt==kernel-padding*(1-padding_consider_cnt_r)-1&&row_cnt==1)begin
                            channel_cnt<=channel_cnt+1;
                            valid      <= 0;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=0;
                            padding_consider_cnt_c<=0;
                         end
                        else if(column_cnt==kernel-padding*(1-padding_consider_cnt_r)-1&&row_cnt==1)begin
                             row_cnt<=0;
                             column_cnt<=0;  
                             s_row_cnt<=s_row_cnt+1;
                             padding_consider_cnt_c<=0;
                         end
                         else if (row_cnt==1)begin
                            column_cnt<=column_cnt+1;
                            row_cnt<=0;
                        end
               end                                                      //B_row_cnt 한줄이 끝남
               
               else if(B_row_cnt==0) begin                                  //B_row_cnt가 0인 경우 시작
                    if(s_row_cnt==1)begin                              //s_row_cnt가 0인 경우 시작
                         column_cnt<=column_cnt+1;
                         o_stage <=(padding_consider_cnt_r==0)? 1 : 4;
                         if(column_cnt==kernel-padding*(1-padding_consider_cnt_r)-1)begin
                             column_cnt<=0;  
                             s_row_cnt<=s_row_cnt+1;
                             if(B_column_cnt==0)begin
                                padding_consider_cnt_c<=1;
                             end
                         end
                    end                                                 //s_row_cnt가 0인 경우 끝
                    else if (s_row_cnt!=1) begin                       //s_row_cnt가 0이 아닌 경우 시작
                        o_stage <=(padding_consider_cnt_r==0)? 2 : 5;
                        row_cnt<=row_cnt+1;
                        //o_stage <=(r==0)? 1 : 4;
                        if(channel_cnt==channel-1&&s_row_cnt==10&&column_cnt==kernel-padding*(1-padding_consider_cnt_r)-1&&row_cnt==1)begin
                            B_row_cnt<=B_row_cnt+1;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=0;
                            channel_cnt<=0;
                            padding_consider_cnt_c<=0;
                            valid      <= 0;
                        end
                        else if(s_row_cnt==10&&column_cnt==kernel-padding*(1-padding_consider_cnt_r)-1&&row_cnt==1)begin
                            channel_cnt<=channel_cnt+1;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=0;
                            padding_consider_cnt_c<=0;
                            valid    <= 0;
                         end
                        else if(column_cnt==kernel-padding*(1-padding_consider_cnt_r)-1&&row_cnt==1)begin
                             row_cnt<=0;
                             column_cnt<=0;  
                             s_row_cnt<=s_row_cnt+1;
                         end
                         else if (row_cnt==1)begin
                            column_cnt<=column_cnt+1;
                            row_cnt<=0;
                        end
                    end                                                 //s_row_cnt가 0이 아닌 경우 끝    
               end                                                      //B_row_cnt가 0인 경우 끝
                else if(B_row_cnt==in_row_size/(10*stride)-1) begin                                  //B_row_cnt가 0 or 마지막 값인 경우 시작
                    if(s_row_cnt==10)begin                              //s_row_cnt가 0인 경우 시작
                         column_cnt<=column_cnt+1;
                         o_stage <=(padding_consider_cnt_r==0)? 3 : 6;
                          if(column_cnt==kernel-padding*(1-padding_consider_cnt_r)-1)begin
                            channel_cnt<=channel_cnt+1;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=0;
                            padding_consider_cnt_c<=0;
                            valid  <= 0;
                         end
                    end                                                 //s_row_cnt가 0인 경우 끝
                    else if (s_row_cnt!=10) begin                       //s_row_cnt가 0이 아닌 경우 시작
                        o_stage <=(padding_consider_cnt_r==0)? 2 : 5;
                        row_cnt<=row_cnt+1;
                        if(channel_cnt==channel-1&&s_row_cnt==10&&column_cnt==kernel-padding*(1-padding_consider_cnt_r)-1&&row_cnt==1)begin
                            B_row_cnt<=B_row_cnt+1;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=0;
                            channel_cnt<=0;
                            padding_consider_cnt_c<=0;
                            valid      <= 0;
                        end
                        else if(s_row_cnt==10&&column_cnt==kernel-padding*(1-padding_consider_cnt_r)-1&&row_cnt==1)begin
                            channel_cnt<=channel_cnt+1;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=0;
                            padding_consider_cnt_c<=0;
                            valid <= 0;
             
                         end
                        else if(column_cnt==kernel-padding*(1-padding_consider_cnt_r)-1&&row_cnt==1)begin
                             row_cnt<=0;
                             column_cnt<=0;  
                             s_row_cnt<=s_row_cnt+1;
                         end
                         else if (row_cnt==1)begin
                            column_cnt<=column_cnt+1;
                            row_cnt<=0;
                        end
                    end                                                 //s_row_cnt가 0이 아닌 경우 끝    
               end                                                      //B_row_cnt가 0인 경우 끝
               end                                                      //valid end
            end                                                         //padding이 2인 경우 끝
           
           
           
           
           
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// case 1 padding 1 stride 2 시작                                                    
           
            else if (padding==1) begin                                                                                                                                                                                              //case 1 padding이 1인 경우 시작
             if(stride==2)begin                                                                                                                                                                                                  //case 1 stried가 2인 경우 시작
               if (valid == 0)begin
                 o_valid <= 0;
               end
              if(i_start)begin
                 valid <= 1;
               
              end
              if(valid == 1)begin
                o_valid<=1;                                              //o_addr이 유효함을 의미
                o_addr<=(channel_cnt*in_row_size/4*(in_column_size))     //channel이 넘어가는 경우 주소값 계산
                + (B_row_cnt*5)                                          //B_row_cnt가 넘어가는 경우 주소값 계산
                + ((B_column_cnt)*in_row_size/4)                         //B_column_cnt가 넘어가는 경우 주소값 계산
                + ((s_row_cnt-1)/2)                                      //s_row_cnt가 넘어가는 경우 주소 값 계산
                + (in_row_size*column_cnt/4)                             //column이 넘어가는 경우 주소값 계산
                - (row_cnt)                                              //row가 넘어가는 경우 주소값 계산
                ;
               
               if(B_row_cnt==in_row_size/(10*stride)-1&&B_column_cnt==(in_column_size-kernel+padding)/stride&&channel_cnt==channel-1&&s_row_cnt==10&&column_cnt==kernel-padding*(1-padding_consider_cnt_r)-1&&row_cnt==0) begin      //case_1인 경우 끝 && 초기화 시작
                  finish<=1;
                  o_final <= 0;
                  B_column_cnt<=0;
                  padding_consider_cnt_r<=0;
                  B_row_cnt<=0;
                  s_row_cnt<=1;
                  column_cnt<=0;
                  row_cnt<=0;
                  channel_cnt<=0;
                  valid      <= 0;
               end // 초기화 끝                                                    
                 
               else if (B_column_cnt<(in_column_size-kernel+padding)/stride&&B_row_cnt==in_row_size/(10*stride)-1&&channel_cnt==channel-1&&s_row_cnt==10&&column_cnt==kernel-padding*(1-padding_consider_cnt_r)-1&&row_cnt==0) begin     //B_column_cnt를 끝까지 실행 시작
                     padding_consider_cnt_r<=1;
                     B_column_cnt<=B_column_cnt+1;
                     B_row_cnt<=0;
                     s_row_cnt<=1;
                     column_cnt<=0;
                     row_cnt<=0;
                     channel_cnt<=0;
                     valid      <= 0;
               end //B_column_cnt를 끝까지 실행 끝
               
               
               else if (B_row_cnt<in_row_size/(10*stride)&&B_row_cnt!=0) begin                 //B_row_cnt가 한줄이 진행중
                    o_stage <=(padding_consider_cnt_r==0)? 2 : 5;
                    if (s_row_cnt%2==1) begin                                                 //s_row_cnt가 홀수인 경우 시작
                        row_cnt<=row_cnt-1;
                        if(column_cnt==kernel-padding*(1-padding_consider_cnt_r)-1&&row_cnt==0)begin
                             row_cnt<=0;
                             column_cnt<=0;  
                             s_row_cnt<=s_row_cnt+1;
                         end
                         else if (row_cnt==0)begin
                            column_cnt<=column_cnt+1;
                            row_cnt<=1;
                        end
                    end                                                 //s_row_cnt가 홀수인 경우 끝
                   
                    else if (s_row_cnt%2==0) begin                       //s_row_cnt가 짝수인 경우 시작
                        column_cnt<=column_cnt+1;
                        if(channel_cnt==channel-1&&s_row_cnt==10&&column_cnt==kernel-padding*(1-padding_consider_cnt_r)-1)begin
                            B_row_cnt<=B_row_cnt+1;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=1;
                            channel_cnt<=0;
                            valid      <= 0;

                        end
                        else if(s_row_cnt==10&&column_cnt==kernel-padding*(1-padding_consider_cnt_r)-1)begin
                            channel_cnt<=channel_cnt+1;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=1;
                            valid      <= 0;
   
                         end
                        else if(column_cnt==kernel-padding*(1-padding_consider_cnt_r)-1)begin
                             row_cnt<=1;
                             column_cnt<=0;  
                             s_row_cnt<=s_row_cnt+1;
                         end
                    end                                                 //s_row_cnt가 짝수인 경우 끝
               end                                                      //B_row_cnt 한줄이 끝남
               
               
               
               else if(B_row_cnt==0) begin                                  //B_row_cnt가 0인 경우 시작
                    if(s_row_cnt==1)begin                              //s_row_cnt가 0인 경우 시작
                        o_stage <=(padding_consider_cnt_r==0)? 1 : 4;
                         column_cnt<=column_cnt+1;
                         if(column_cnt==kernel-padding*(1-padding_consider_cnt_r)-1)begin
                             column_cnt<=0;  
                             s_row_cnt<=s_row_cnt+1;
                         end
                    end                                                 //s_row_cnt가 0인 경우 끝
                    else if (s_row_cnt%2==1) begin                       //s_row_cnt가 홀수인 경우 시작
                        o_stage <=(padding_consider_cnt_r==0)? 2 : 5;
                        row_cnt<=row_cnt-1;
                         if(column_cnt==kernel-padding*(1-padding_consider_cnt_r)-1&&row_cnt==0)begin
                             row_cnt<=0;
                             column_cnt<=0;  
                             s_row_cnt<=s_row_cnt+1;
                         end
                         else if (row_cnt==0)begin
                            column_cnt<=column_cnt+1;
                            row_cnt<=1;
                        end
                    end                                                 //s_row_cnt가 홀수인 경우 끝
                    else if (s_row_cnt%2==0) begin                       //s_row_cnt가 짝수인 경우 시작
                        column_cnt<=column_cnt+1;
                        if(channel_cnt==channel-1&&s_row_cnt==10&&column_cnt==kernel-padding*(1-padding_consider_cnt_r)-1)begin
                            B_row_cnt<=B_row_cnt+1;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=1;
                            channel_cnt<=0;
                            valid      <= 0;

                        end
                        else if(s_row_cnt==10&&column_cnt==kernel-padding*(1-padding_consider_cnt_r)-1)begin
                            channel_cnt<=channel_cnt+1;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=0;
                            valid      <= 0;

                         end
                        else if(column_cnt==kernel-padding*(1-padding_consider_cnt_r)-1)begin
                             row_cnt<=1;
                             column_cnt<=0;  
                             s_row_cnt<=s_row_cnt+1;
                         end
                    end                                                 //s_row_cnt가 짝수인 경우 끝      
               end                                                      //B_row_cnt가 0인 경우 끝
               end                                                      //valid 끝
                end                                                     //stride가 2인 경우 끝
               
               
               
               
               
               
               
  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    case1 padding 1 stride 1인 경우 시작          
                else if (stride==1) begin                                                         // stride가 1인 경우 시작
                 if (valid == 0)begin
                   o_valid <= 0;
                 end
                 if(i_start)begin
                   valid <= 1;
                 
                end
                if(valid == 1)begin  
                o_valid<=1;                                              //o_addr이 유효함을 의미
                o_addr<=(channel_cnt*in_row_size/4*(in_column_size))     //channel이 넘어가는 경우 주소값 계산
                + (B_row_cnt*2)+(B_row_cnt-1*(1%(B_row_cnt+1)))/2        //B_row_cnt가 넘어가는 경우 주소값 계산
                + ((B_column_cnt-padding_consider_cnt_r)*in_row_size/4)  //B_column_cnt가 넘어가는 경우 주소값 계산
                + (s_row_cnt/4)                                          //s_row_cnt가 넘어가는 경우 주소 값 계산
                + (in_row_size*column_cnt/4)                             //column이 넘어가는 경우 주소값 계산
                + (B_row_cnt[0] ? (1-row_cnt) : -row_cnt)                //row가 넘어가는 경우 주소값 계산    
                + ((B_row_cnt != 0) && (B_row_cnt[0] == 0) ? 1 : 0)
                ;
               if(B_row_cnt==in_row_size/10-1&&B_column_cnt==in_column_size-kernel+padding &&channel_cnt==channel-1&&s_row_cnt==10&&column_cnt==kernel-padding*(1-padding_consider_cnt_r)-1&&row_cnt==1) begin                                              //case_1인 경우 끝&& 초기화 시작
                  finish<=1;
                  o_final <= 0;
                  o_valid <= 0;
                  B_column_cnt<=0;
                  padding_consider_cnt_r<=0;
                  B_row_cnt<=0;
                  s_row_cnt<=1;
                  column_cnt<=0;
                  row_cnt<=0;
                  channel_cnt<=0;
                  valid <= 0;
               end                                                      // 초기화 끝                        
               
               else if (B_column_cnt< in_column_size-kernel+padding && B_row_cnt==in_row_size/(10)-1&&channel_cnt==channel-1&&s_row_cnt==10&&column_cnt==kernel-padding*(1-padding_consider_cnt_r)-1&&row_cnt==1) begin             //B_column_cnt를 끝까지 실행 시작
                     padding_consider_cnt_r<=1;
                     B_column_cnt<=B_column_cnt+1;
                     B_row_cnt<=0;
                     s_row_cnt<=1;
                     column_cnt<=0;
                     row_cnt<=0;
                     channel_cnt<=0;
                     valid <= 0;
               end                                                      //B_column_cnt를 끝까지 실행 끝
               
               else if (B_row_cnt<in_row_size/10&-1&B_row_cnt!=0&&B_row_cnt%2==1&&B_row_cnt!=in_row_size/10-1) begin                 //B_row_cnt가 홀수일때 진행중
                    if (s_row_cnt==2||s_row_cnt==3||s_row_cnt==6||s_row_cnt==7||s_row_cnt==10) begin                       //s_row_cnt가 홀수인 경우 시작
                        row_cnt<=row_cnt-1;
                        if(channel_cnt==channel-1&&s_row_cnt==10&&column_cnt==kernel-padding*(1-padding_consider_cnt_r)-1&&row_cnt==0)begin
                            B_row_cnt<=B_row_cnt+1;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=1;
                            channel_cnt<=0;
                            valid <= 0;

                        end
                        else if(s_row_cnt==10&&column_cnt==kernel-padding*(1-padding_consider_cnt_r)-1&&row_cnt==0)begin
                            channel_cnt<=channel_cnt+1;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=1;
                            valid <= 0;

                         end
                        else if(column_cnt==kernel-padding*(1-padding_consider_cnt_r)-1&&row_cnt==0)begin
                            if(s_row_cnt==3||s_row_cnt==7||s_row_cnt==10)begin
                                row_cnt<=1;
                             end
                             else begin
                                row_cnt<=1;
                             end
                             column_cnt<=0;  
                             s_row_cnt<=s_row_cnt+1;
                         end
                         else if (row_cnt==0)begin
                            column_cnt<=column_cnt+1;
                            row_cnt<=1;
                        end
                    end                                                 //s_row_cnt가 홀수인 경우 끝
                    else if (s_row_cnt==1||s_row_cnt==4||s_row_cnt==5||s_row_cnt==8||s_row_cnt==9) begin                       //s_row_cnt가 짝수인 경우 시작
                        column_cnt<=column_cnt+1;
                         if(column_cnt==kernel-padding*(1-padding_consider_cnt_r)-1)begin
                            if(s_row_cnt==1||s_row_cnt==5||s_row_cnt==9)begin
                                row_cnt<=1;
                             end
                             column_cnt<=0;  
                             s_row_cnt<=s_row_cnt+1;
                         end
                    end                                                 //s_row_cnt가 짝수인 경우 끝
               end                                                      //B_row_cnt가 홀수인 경우 끝남
                else if (B_row_cnt<in_row_size/(10)-1&&B_row_cnt!=0&&B_row_cnt%2==0&&B_row_cnt!=in_row_size/10-1) begin                 //B_row_cnt가 짝수일때 진행중
                    if (s_row_cnt==1||s_row_cnt==4||s_row_cnt==5||s_row_cnt==8||s_row_cnt==9) begin                       //s_row_cnt가 홀수인 경우 시작
                        row_cnt<=row_cnt-1;
                         if(column_cnt==kernel-padding*(1-padding_consider_cnt_r)-1&&row_cnt==0)begin
                            if(s_row_cnt==1||s_row_cnt==9||s_row_cnt==5)begin
                                row_cnt<=0;
                             end
                             else begin
                                row_cnt<=1;
                             end
                             column_cnt<=0;  
                             s_row_cnt<=s_row_cnt+1;
                         end
                         else if (row_cnt==0)begin
                            column_cnt<=column_cnt+1;
                            row_cnt<=1;
                        end
                    end                                                 //s_row_cnt가 홀수인 경우 끝
                    else if (s_row_cnt==2||s_row_cnt==3||s_row_cnt==6||s_row_cnt==7||s_row_cnt==10) begin                       //s_row_cnt가 짝수인 경우 시작
                        column_cnt<=column_cnt+1;
                        if(channel_cnt==channel-1&&s_row_cnt==10&&column_cnt==kernel-padding*(1-padding_consider_cnt_r)-1)begin
                            B_row_cnt<=B_row_cnt+1;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=1;
                            channel_cnt<=0;
                            valid <= 0;

                        end
                        else if(s_row_cnt==10&&column_cnt==kernel-padding*(1-padding_consider_cnt_r)-1)begin
                            channel_cnt<=channel_cnt+1;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=1;
                            valid <= 0;

                         end
                        else if(column_cnt==kernel-padding*(1-padding_consider_cnt_r)-1)begin
                            if(s_row_cnt==3||s_row_cnt==7||s_row_cnt==10)begin
                                row_cnt<=1;
                             end
                             column_cnt<=0;  
                             s_row_cnt<=s_row_cnt+1;
                         end
                    end                                                                                                                     //s_row_cnt가 짝수인 경우 끝
               end                                                                                                                          //B_row_cnt가 짝수인 경우 끝남
               
               else if(B_row_cnt==0) begin                                                                                                  //B_row_cnt가 0인 경우 시작
                        if (s_row_cnt==4||s_row_cnt==5||s_row_cnt==8||s_row_cnt==9) begin                                                   //s_row_cnt가 홀수인 경우 시작
                        row_cnt<=row_cnt-1;
                         if(column_cnt==kernel-padding*(1-padding_consider_cnt_r)-1&&row_cnt==0)begin
                            if(s_row_cnt==5||s_row_cnt==9)begin
                                row_cnt<=0;
                             end
                             else begin
                                row_cnt<=1;
                             end
                             column_cnt<=0;  
                             s_row_cnt<=s_row_cnt+1;
                         end
                         else if (row_cnt==0)begin
                            column_cnt<=column_cnt+1;
                            row_cnt<=1;
                        end
                    end                                                                                                                       //s_row_cnt가 홀수인 경우 끝
                    else if (s_row_cnt==1||s_row_cnt==2||s_row_cnt==3||s_row_cnt==6||s_row_cnt==7||s_row_cnt==10) begin                       //s_row_cnt가 짝수인 경우 시작
                        column_cnt<=column_cnt+1;
                        if(channel_cnt==channel-1&&s_row_cnt==10&&column_cnt==kernel-padding*(1-padding_consider_cnt_r)-1)begin
                            B_row_cnt<=B_row_cnt+1;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=1;
                            channel_cnt<=0;
                            valid <= 0;

                        end
                        else if(s_row_cnt==10&&column_cnt==kernel-padding*(1-padding_consider_cnt_r)-1)begin
                            channel_cnt<=channel_cnt+1;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=0;
                            valid <= 0;

                         end
                        else if(column_cnt==kernel-padding*(1-padding_consider_cnt_r)-1)begin
                            if(s_row_cnt==3||s_row_cnt==7)begin
                                row_cnt<=1;
                             end
                             column_cnt<=0;  
                             s_row_cnt<=s_row_cnt+1;
                         end
                    end                                                                                                                             //s_row_cnt가 짝수인 경우 끝      
               end                                                                                                                                  //B_row_cnt가 0인 경우 끝
                else if(B_row_cnt==in_row_size/10-1) begin                                                                                          //B_row_cnt가 마지막인 경우 시작
                        if (s_row_cnt==2||s_row_cnt==3||s_row_cnt==6||s_row_cnt==7) begin                                                           //s_row_cnt가 홀수인 경우 시작
                        row_cnt<=row_cnt-1;
                         if(column_cnt==kernel-padding*(1-padding_consider_cnt_r)-1&&row_cnt==0)begin
                            if(s_row_cnt==3||s_row_cnt==7)begin
                                row_cnt<=1;
                             end
                             else begin
                                row_cnt<=1;
                             end
                             column_cnt<=0;  
                             s_row_cnt<=s_row_cnt+1;
                         end
                         else if (row_cnt==0)begin
                            column_cnt<=column_cnt+1;
                            row_cnt<=1;
                        end
                    end                                                                                                                        //s_row_cnt가 홀수인 경우 끝
                    else if (s_row_cnt==1||s_row_cnt==4||s_row_cnt==5||s_row_cnt==8||s_row_cnt==9||s_row_cnt==10) begin                       //s_row_cnt가 짝수인 경우 시작
                        column_cnt<=column_cnt+1;
                        if(channel_cnt==channel-1&&s_row_cnt==10&&column_cnt==kernel-padding*(1-padding_consider_cnt_r)-1)begin
                            B_row_cnt<=B_row_cnt+1;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=1;
                            channel_cnt<=0;
                            valid <= 0;

                        end
                        else if(s_row_cnt==10&&column_cnt==kernel-padding*(1-padding_consider_cnt_r)-1)begin
                            channel_cnt<=channel_cnt+1;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=1;
                            valid <= 0;

                         end
                        else if(column_cnt==kernel-padding*(1-padding_consider_cnt_r)-1)begin
                            if(s_row_cnt==1||s_row_cnt==5||s_row_cnt==10)begin
                                row_cnt<=1;
                             end
                             column_cnt<=0;  
                             s_row_cnt<=s_row_cnt+1;
                         end
                    end                                                 //s_row_cnt가 짝수인 경우 끝      
               end                                                      //B_row_cnt가 마지막인 경우 끝    
                end                                                     // stride가 1인 경우 끝
                end                                                     // valid 끝
            end                                                         //padding이 1인 경우 끝
        end                                                             //case_1인 경우 끝        
       
       
       
       
       
       
       
       
       
       
       
        /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////case 2 padding이 2인 경우 시작
        else if(state == case_2)begin
           
            if(padding==2) begin                                          //case 2 padding이 2인 경우 시작
             if (valid == 0)begin
                o_valid <= 0;
             end
             if(i_start)begin
                valid <= 1;
               
             end
             if(valid == 1)begin
                o_valid<=1;                                              //o_addr이 유효함을 의미
                o_addr<=(channel_cnt*in_row_size/4*(in_column_size))     //channel이 넘어가는 경우 주소값 계산
                + ((B_row_cnt*5)-1%(B_row_cnt+1))                        //B_row_cnt가 넘어가는 경우 주소값 계산
                + (B_column_cnt*in_row_size/4*stride)                    //B_column_cnt가 넘어가는 경우 주소값 계산
                + (s_row_cnt/2-padding_consider_cnt_c)                   //s_row_cnt가 넘어가는 경우 주소 값 계산
                + (in_row_size*column_cnt/4)                             //column이 넘어가는 경우 주소값 계산
                + (row_cnt)                                              //row가 넘어가는 경우 주소값 계산
                ;
               
               
               if(B_row_cnt==in_row_size/(10*stride)-1&&B_column_cnt==(in_column_size-kernel+padding)/stride-1 && channel_cnt==channel-1&&s_row_cnt==10&&column_cnt==kernel-padding*padding_consider_cnt_r-1&&row_cnt==0) begin                                              //case_1인 경우 끝&& 초기화 시작
                  finish<=1;
                  o_final <= 1;
                  B_column_cnt<=0;
                  padding_consider_cnt_r<=0;
                  B_row_cnt<=0;
                  s_row_cnt<=1;
                  column_cnt<=0;
                  row_cnt<=0;
                  channel_cnt<=0;
                  padding_consider_cnt_c<=0;
                  valid <= 0;
               end // 초기화 끝  
               
               
               else if (B_column_cnt<(in_column_size-kernel+padding)/stride-1&&B_row_cnt==in_row_size/(10*stride)-1&&channel_cnt==channel-1&&s_row_cnt==10&&column_cnt==kernel-padding*padding_consider_cnt_r-1&&row_cnt==0) begin             //B_column_cnt를 끝까지 실행 시작
                     padding_consider_cnt_r<=0;
                     B_column_cnt<=B_column_cnt+1;
                     B_row_cnt<=0;
                     s_row_cnt<=1;
                     column_cnt<=0;
                     row_cnt<=0;
                     channel_cnt<=0;
                     padding_consider_cnt_c<=0;
                     valid <= 0;
               end                                                                                                                              //B_column_cnt를 끝까지 실행 끝                    
               
               
                                           
               else if (B_row_cnt<in_row_size/(10*stride)-1&&B_row_cnt!=0) begin                                                                //B_row_cnt가 한줄이 진행중
                    row_cnt<=row_cnt+1;
                    o_stage <= 5;
                        if(channel_cnt==channel-1&&s_row_cnt==10&&column_cnt==kernel-padding*padding_consider_cnt_r-1&&row_cnt==1)begin
                            B_row_cnt<=B_row_cnt+1;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=0;
                            channel_cnt<=0;
                            padding_consider_cnt_c<=0;
                            valid <= 0;
                        end
                        else if(s_row_cnt==10&&column_cnt==kernel-padding*padding_consider_cnt_r-1&&row_cnt==1)begin
                            channel_cnt<=channel_cnt+1;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=0;
                            padding_consider_cnt_c<=0;
                            valid <= 0;
                         end
                        else if(column_cnt==kernel-padding*padding_consider_cnt_r-1&&row_cnt==1)begin
                             row_cnt<=0;
                             column_cnt<=0;  
                             s_row_cnt<=s_row_cnt+1;
                             padding_consider_cnt_c<=0;
                         end
                         else if (row_cnt==1)begin
                            column_cnt<=column_cnt+1;
                            row_cnt<=0;
                        end
               end                                                                                                                         //B_row_cnt 한줄이 끝남
             
               else if(B_row_cnt==0) begin                                                                                                 //B_row_cnt가 0인 경우 시작
                    if(s_row_cnt==1)begin                                                                                                  //s_row_cnt가 0인 경우 시작
                        o_stage <= 4;
                         column_cnt<=column_cnt+1;
                         if(column_cnt==kernel-padding*padding_consider_cnt_r-1)begin
                             column_cnt<=0;  
                             s_row_cnt<=s_row_cnt+1;
                                padding_consider_cnt_c<=1;
                         end
                    end                                                                                                                     //s_row_cnt가 0인 경우 끝
                    else if (s_row_cnt!=1) begin                                                                                            //s_row_cnt가 0이 아닌 경우 시작
                        o_stage <= 5;
                        row_cnt<=row_cnt+1;
                        if(channel_cnt==channel-1&&s_row_cnt==10&&column_cnt==kernel-padding*padding_consider_cnt_r-1&&row_cnt==1)begin
                            B_row_cnt<=B_row_cnt+1;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=0;
                            channel_cnt<=0;
                            padding_consider_cnt_c<=0;
                            valid <= 0;
                        end
                        else if(s_row_cnt==10&&column_cnt==kernel-padding*padding_consider_cnt_r-1&&row_cnt==1)begin
                            channel_cnt<=channel_cnt+1;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=0;
                            padding_consider_cnt_c<=0;
                            valid <= 0;
                         end
                        else if(column_cnt==kernel-padding*padding_consider_cnt_r-1&&row_cnt==1)begin
                             row_cnt<=0;
                             column_cnt<=0;  
                             s_row_cnt<=s_row_cnt+1;
                         end
                         else if (row_cnt==1)begin
                            column_cnt<=column_cnt+1;
                            row_cnt<=0;
                        end
                    end                                                                                                                             //s_row_cnt가 0이 아닌 경우 끝    
               end                                                                                                                                  //B_row_cnt가 0인 경우 끝
               
               

                else if(B_row_cnt==in_row_size/(10*stride)-1) begin                                                                                 //B_row_cnt가 0 or 마지막 값인 경우 시작
                    if(s_row_cnt==10)begin                                                                                                          //s_row_cnt가 0인 경우 시작
                        o_stage <= 6;
                         column_cnt<=column_cnt+1;
                          if(column_cnt==kernel-padding*padding_consider_cnt_r-1)begin
                            channel_cnt<=channel_cnt+1;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=0;
                            padding_consider_cnt_c<=0;
                            valid <= 0;
                         end
                    end                                                                                                                                 //s_row_cnt가 0인 경우 끝
                    else if (s_row_cnt!=10) begin                                                                                                       //s_row_cnt가 0이 아닌 경우 시작
                        o_stage <= 5;
                        row_cnt<=row_cnt+1;
                        if(channel_cnt==channel-1&&s_row_cnt==10&&column_cnt==kernel-padding*padding_consider_cnt_r-1&&row_cnt==1)begin
                            B_row_cnt<=B_row_cnt+1;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=0;
                            channel_cnt<=0;
                            padding_consider_cnt_c<=0;
                            valid <= 0;
                        end
                        else if(s_row_cnt==10&&column_cnt==kernel-padding*padding_consider_cnt_r-1&&row_cnt==1)begin
                            channel_cnt<=channel_cnt+1;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=0;
                            padding_consider_cnt_c<=0;
                            valid <= 0;
             
                         end
                        else if(column_cnt==kernel-padding*padding_consider_cnt_r-1&&row_cnt==1)begin
                             row_cnt<=0;
                             column_cnt<=0;  
                             s_row_cnt<=s_row_cnt+1;
                         end
                         else if (row_cnt==1)begin
                            column_cnt<=column_cnt+1;
                            row_cnt<=0;
                        end
                    end                                                 //s_row_cnt가 0이 아닌 경우 끝    
                   end                                                  //B_row_cnt가 0인 경우 끝
               end                                                      //valid 끝    
            end                                                         //padding이 2인 경우 끝
           
           
           
           
           
           
           
           
           
           
           
           
            ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////case 2  padding 1 stride 2
             else if (padding==1) begin                                 //padding이 1인 경우 시작
                if(stride==2)begin                                      // stried가 2인 경우 시작
                  if (valid == 0)begin
                    o_valid <= 0;
                end
                if(i_start)begin
                   valid <= 1;
                 
                end
                if(valid == 1)begin
                o_valid<=1;                                              //o_addr이 유효함을 의미
                o_addr<=(channel_cnt*in_row_size/4*(in_column_size))     //channel이 넘어가는 경우 주소값 계산
                + (B_row_cnt*5)                                          //B_row_cnt가 넘어가는 경우 주소값 계산
                + ((B_column_cnt)*in_row_size/4*stride)                  //B_column_cnt가 넘어가는 경우 주소값 계산
                + ((s_row_cnt-1)/2)                                      //s_row_cnt가 넘어가는 경우 주소 값 계산
                + (in_row_size*column_cnt/4)                             //column이 넘어가는 경우 주소값 계산
                - (row_cnt)                                              //row가 넘어가는 경우 주소값 계산
                ;
               if(B_row_cnt==in_row_size/(10*stride)-1&&B_column_cnt==(in_column_size-kernel+padding)/stride&&channel_cnt==channel-1&&s_row_cnt==10&&column_cnt==kernel-1&&row_cnt==0) begin                                              //case_1인 경우 끝&& 초기화 시작
                  finish<=1;
                  o_final <= 0;
                  B_column_cnt<=0;
                  padding_consider_cnt_r<=0;
                  B_row_cnt<=0;
                  s_row_cnt<=1;
                  column_cnt<=0;
                  row_cnt<=0;
                  channel_cnt<=0;
                  valid <= 0;
               end                                                      // 초기화 끝            
                 
               else if (B_column_cnt<(in_column_size-kernel+padding)/stride&&B_row_cnt==in_row_size/(10*stride)-1&&channel_cnt==channel-1&&s_row_cnt==10&&column_cnt==kernel-1&&row_cnt==0) begin  //B_column_cnt를 끝까지 실행 시작
                     padding_consider_cnt_r<=1;
                     B_column_cnt<=B_column_cnt+1;
                     B_row_cnt<=0;
                     s_row_cnt<=1;
                     column_cnt<=0;
                     row_cnt<=0;
                     channel_cnt<=0;
                     valid <= 0;
               end //B_column_cnt를 끝까지 실행 끝
                                                                   
               else if (B_row_cnt<in_row_size/(10*stride)&&B_row_cnt!=0) begin                 //B_row_cnt가 한줄이 진행중
                    if (s_row_cnt%2==1) begin                                                 //s_row_cnt가 홀수인 경우 시작
                        row_cnt<=row_cnt-1;
                        if(column_cnt==kernel-1&&row_cnt==0)begin
                             row_cnt<=0;
                             column_cnt<=0;  
                             s_row_cnt<=s_row_cnt+1;
                         end
                         else if (row_cnt==0)begin
                            column_cnt<=column_cnt+1;
                            row_cnt<=1;
                        end
                    end                                                                          //s_row_cnt가 홀수인 경우 끝
                    else if (s_row_cnt%2==0) begin                                               //s_row_cnt가 짝수인 경우 시작
                        column_cnt<=column_cnt+1;
                        if(channel_cnt==channel-1&&s_row_cnt==10&&column_cnt==kernel-1)begin
                            B_row_cnt<=B_row_cnt+1;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=1;
                            channel_cnt<=0;
                            valid <= 0;

                        end
                        else if(s_row_cnt==10&&column_cnt==kernel-1)begin
                            channel_cnt<=channel_cnt+1;
                            valid <= 0;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=1;
   
                         end
                        else if(column_cnt==kernel-1)begin
                             row_cnt<=1;
                             column_cnt<=0;  
                             s_row_cnt<=s_row_cnt+1;
                         end
                    end                                                 //s_row_cnt가 짝수인 경우 끝
               end                                                      //B_row_cnt 한줄이 끝남
               
               else if(B_row_cnt==0) begin                             //B_row_cnt가 0인 경우 시작
                    if(s_row_cnt==1)begin                              //s_row_cnt가 0인 경우 시작
                         column_cnt<=column_cnt+1;
                         if(column_cnt==kernel-1)begin
                             column_cnt<=0;  
                             s_row_cnt<=s_row_cnt+1;
                         end
                    end                                                 //s_row_cnt가 0인 경우 끝
                    else if (s_row_cnt%2==1) begin                      //s_row_cnt가 홀수인 경우 시작
                        row_cnt<=row_cnt-1;
                         if(column_cnt==kernel-1&&row_cnt==0)begin
                             row_cnt<=0;
                             column_cnt<=0;  
                             s_row_cnt<=s_row_cnt+1;
                         end
                         else if (row_cnt==0)begin
                            column_cnt<=column_cnt+1;
                            row_cnt<=1;
                        end
                    end                                                 //s_row_cnt가 홀수인 경우 끝
                    else if (s_row_cnt%2==0) begin                      //s_row_cnt가 짝수인 경우 시작
                        column_cnt<=column_cnt+1;
                        if(channel_cnt==channel-1&&s_row_cnt==10&&column_cnt==kernel-1)begin
                            B_row_cnt<=B_row_cnt+1;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=1;
                            channel_cnt<=0;
                            valid <= 0;

                        end
                        else if(s_row_cnt==10&&column_cnt==kernel-1)begin
                            channel_cnt<=channel_cnt+1;
                            valid <= 0;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=0;

                         end
                        else if(column_cnt==kernel-1)begin
                             row_cnt<=1;
                             column_cnt<=0;  
                             s_row_cnt<=s_row_cnt+1;
                         end
                    end                                                 //s_row_cnt가 짝수인 경우 끝      
               end                                                      //B_row_cnt가 0인 경우 끝
              end                                                       // valid 끝    
            end                                                         //stride가 2인 경우 끝
           
           
           
           
            ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////case 2 padding 1 stride 1
                else if (stride==1) begin                                                        
                  if (valid == 0)begin
                    o_valid <= 0;
                end
                if(i_start)begin
                   valid <= 1;
                 
                end
                if(valid == 1)begin
                o_valid<=1;                                             //o_addr이 유효함을 의미
                o_addr<=(channel_cnt*in_row_size/4*(in_column_size))    //channel이 넘어가는 경우 주소값 계산
                + (B_row_cnt*2)+(B_row_cnt-1*(1%(B_row_cnt+1)))/2       //B_row_cnt가 넘어가는 경우 주소값 계산
                + ((B_column_cnt)*in_row_size/4)                        //B_column_cnt가 넘어가는 경우 주소값 계산
                + (s_row_cnt/4)                                         //s_row_cnt가 넘어가는 경우 주소 값 계산
                + (in_row_size*column_cnt/4)                            //column이 넘어가는 경우 주소값 계산
                + (B_row_cnt[0] ? (1-row_cnt) : -row_cnt)               //row가 넘어가는 경우 주소값 계산    
                + ((B_row_cnt != 0) && (B_row_cnt[0] == 0) ? 1 : 0)
                ;
               
               if(B_row_cnt==in_row_size/10-1&&B_column_cnt==in_column_size-kernel+padding-1 &&channel_cnt==channel-1&&s_row_cnt==10&&column_cnt==kernel-1&&row_cnt==1) begin                                              //case_1인 경우 끝&& 초기화 시작
                  finish<=1;
                  o_final <= 0;
                  o_valid <= 0;
                  B_column_cnt<=0;
                  padding_consider_cnt_r<=0;
                  B_row_cnt<=0;
                  s_row_cnt<=1;
                  column_cnt<=0;
                  row_cnt<=0;
                  channel_cnt<=0;
                  valid <= 0;
               end                                                      // 초기화 끝
                 
               else if (B_column_cnt< in_column_size-kernel+padding-1 && B_row_cnt==in_row_size/(10)-1&&channel_cnt==channel-1&&s_row_cnt==10&&column_cnt==kernel-1&&row_cnt==1) begin //B_column_cnt를 끝까지 실행 시작
                     padding_consider_cnt_r<=1;
                     B_column_cnt<=B_column_cnt+1;
                     B_row_cnt<=0;
                     s_row_cnt<=1;
                     column_cnt<=0;
                     row_cnt<=0;
                     channel_cnt<=0;
                     valid <= 0;
               end                                                      //B_column_cnt를 끝까지 실행 끝
               
               else if (B_row_cnt<in_row_size/10&-1&B_row_cnt!=0&&B_row_cnt%2==1&&B_row_cnt!=in_row_size/10-1) begin        //B_row_cnt가 홀수일때 진행중
                    if (s_row_cnt==2||s_row_cnt==3||s_row_cnt==6||s_row_cnt==7||s_row_cnt==10) begin                       //s_row_cnt가 홀수인 경우 시작
                        row_cnt<=row_cnt-1;
                        if(channel_cnt==channel-1&&s_row_cnt==10&&column_cnt==kernel-1&&row_cnt==0)begin
                            B_row_cnt<=B_row_cnt+1;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=1;
                            channel_cnt<=0;
                            valid <= 0;

                        end
                        else if(s_row_cnt==10&&column_cnt==kernel-1&&row_cnt==0)begin
                            channel_cnt<=channel_cnt+1;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=1;
                            valid <= 0;

                         end
                        else if(column_cnt==kernel-1&&row_cnt==0)begin
                            if(s_row_cnt==3||s_row_cnt==7||s_row_cnt==10)begin
                                row_cnt<=1;
                             end
                             else begin
                                row_cnt<=1;
                             end
                             column_cnt<=0;  
                             s_row_cnt<=s_row_cnt+1;
                         end
                         else if (row_cnt==0)begin
                            column_cnt<=column_cnt+1;
                            row_cnt<=1;
                        end
                    end                                                                                                        //s_row_cnt가 홀수인 경우 끝
                   
                    else if (s_row_cnt==1||s_row_cnt==4||s_row_cnt==5||s_row_cnt==8||s_row_cnt==9) begin                       //s_row_cnt가 짝수인 경우 시작
                        column_cnt<=column_cnt+1;
                         if(column_cnt==kernel-padding*(1-padding_consider_cnt_r)-1)begin
                            if(s_row_cnt==1||s_row_cnt==5||s_row_cnt==9)begin
                                row_cnt<=1;
                             end
                             column_cnt<=0;  
                             s_row_cnt<=s_row_cnt+1;
                         end
                    end                                                                                                           //s_row_cnt가 짝수인 경우 끝
               end                                                                                                                //B_row_cnt가 홀수인 경우 끝남
                else if (B_row_cnt<in_row_size/(10)-1&&B_row_cnt!=0&&B_row_cnt%2==0&&B_row_cnt!=in_row_size/10-1) begin                 //B_row_cnt가 짝수일때 진행중
                    if (s_row_cnt==1||s_row_cnt==4||s_row_cnt==5||s_row_cnt==8||s_row_cnt==9) begin                                     //s_row_cnt가 홀수인 경우 시작
                        row_cnt<=row_cnt-1;
                         if(column_cnt==kernel-1&&row_cnt==0)begin
                            if(s_row_cnt==1||s_row_cnt==9||s_row_cnt==5)begin
                                row_cnt<=0;
                             end
                             else begin
                                row_cnt<=1;
                             end
                             column_cnt<=0;  
                             s_row_cnt<=s_row_cnt+1;
                         end
                         else if (row_cnt==0)begin
                            column_cnt<=column_cnt+1;
                            row_cnt<=1;
                        end
                    end                                                                                                         //s_row_cnt가 홀수인 경우 끝
                    else if (s_row_cnt==2||s_row_cnt==3||s_row_cnt==6||s_row_cnt==7||s_row_cnt==10) begin                       //s_row_cnt가 짝수인 경우 시작
                        column_cnt<=column_cnt+1;
                        if(channel_cnt==channel-1&&s_row_cnt==10&&column_cnt==kernel-1)begin
                            B_row_cnt<=B_row_cnt+1;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=1;
                            channel_cnt<=0;
                            valid <= 0;

                        end
                        else if(s_row_cnt==10&&column_cnt==kernel-1)begin
                            channel_cnt<=channel_cnt+1;
                            valid <= 0;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=1;

                         end
                        else if(column_cnt==kernel-1)begin
                            if(s_row_cnt==3||s_row_cnt==7||s_row_cnt==10)begin
                                row_cnt<=1;
                             end
                             column_cnt<=0;  
                             s_row_cnt<=s_row_cnt+1;
                         end
                    end                                                                                         //s_row_cnt가 짝수인 경우 끝
               end                                                                                              //B_row_cnt가 짝수인 경우 끝남
               
               else if(B_row_cnt==0) begin                                                                      //B_row_cnt가 0인 경우 시작
                        if (s_row_cnt==4||s_row_cnt==5||s_row_cnt==8||s_row_cnt==9) begin                       //s_row_cnt가 홀수인 경우 시작
                        row_cnt<=row_cnt-1;
                         if(column_cnt==kernel-1&&row_cnt==0)begin
                            if(s_row_cnt==5||s_row_cnt==9)begin
                                row_cnt<=0;
                             end
                             else begin
                                row_cnt<=1;
                             end
                             column_cnt<=0;  
                             s_row_cnt<=s_row_cnt+1;
                         end
                         else if (row_cnt==0)begin
                            column_cnt<=column_cnt+1;
                            row_cnt<=1;
                        end
                    end                                                                                                     //s_row_cnt가 홀수인 경우 끝
                    else if (s_row_cnt==1||s_row_cnt==2||s_row_cnt==3||s_row_cnt==6||s_row_cnt==7||s_row_cnt==10) begin     //s_row_cnt가 짝수인 경우 시작
                        column_cnt<=column_cnt+1;
                        if(channel_cnt==channel-1&&s_row_cnt==10&&column_cnt==kernel-1)begin
                            B_row_cnt<=B_row_cnt+1;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=1;
                            channel_cnt<=0;
                            valid <= 0;

                        end
                        else if(s_row_cnt==10&&column_cnt==kernel-1)begin
                            channel_cnt<=channel_cnt+1;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=0;
                            valid <= 0;

                         end
                        else if(column_cnt==kernel-1)begin
                            if(s_row_cnt==3||s_row_cnt==7)begin
                                row_cnt<=1;
                             end
                             column_cnt<=0;  
                             s_row_cnt<=s_row_cnt+1;
                         end
                    end                                                                     //s_row_cnt가 짝수인 경우 끝      
               end                                                                          //B_row_cnt가 0인 경우 끝
               
                else if(B_row_cnt==in_row_size/10-1) begin                                  //B_row_cnt가 마지막인 경우 시작
                        if (s_row_cnt==2||s_row_cnt==3||s_row_cnt==6||s_row_cnt==7) begin   //s_row_cnt가 홀수인 경우 시작
                        row_cnt<=row_cnt-1;
                         if(column_cnt==kernel-1&&row_cnt==0)begin
                            if(s_row_cnt==3||s_row_cnt==7)begin
                                row_cnt<=1;
                             end
                             else begin
                                row_cnt<=1;
                             end
                             column_cnt<=0;  
                             s_row_cnt<=s_row_cnt+1;
                         end
                         else if (row_cnt==0)begin
                            column_cnt<=column_cnt+1;
                            row_cnt<=1;
                        end
                    end                                                                                                                         //s_row_cnt가 홀수인 경우 끝
                    else if (s_row_cnt==1||s_row_cnt==4||s_row_cnt==5||s_row_cnt==8||s_row_cnt==9||s_row_cnt==10) begin                       //s_row_cnt가 짝수인 경우 시작
                        column_cnt<=column_cnt+1;
                        if(channel_cnt==channel-1&&s_row_cnt==10&&column_cnt==kernel-1)begin
                            B_row_cnt<=B_row_cnt+1;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=1;
                            channel_cnt<=0;
                            valid <= 0;

                        end
                        else if(s_row_cnt==10&&column_cnt==kernel-1)begin
                            channel_cnt<=channel_cnt+1;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=1;
                            valid <= 0;

                         end
                        else if(column_cnt==kernel-1)begin
                            if(s_row_cnt==1||s_row_cnt==5||s_row_cnt==10)begin
                                row_cnt<=1;
                             end
                             column_cnt<=0;  
                             s_row_cnt<=s_row_cnt+1;
                         end
                    end                                                 //s_row_cnt가 짝수인 경우 끝      
               end                                                      //B_row_cnt가 마지막인 경우 끝
               end                                                      //valid 끝      
                end                                                     // stride가 1인 경우 끝
            end                                                         //padding이 1인 경우 끝
         end                                                            //case_2인 경우 끝
           
           
           
           
           
           
           
               
               
       
       
       
       
       
       
       
       
       
       
       
       
       
       
       
       
       
       
       
       
       
       
       
       
       
       
       
       
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// case3 padding 2
        else if(state == case_3)begin
            if(padding==2) begin                                                               //padding이 2인 경우 시작
                if (valid == 0)begin
                    o_valid <= 0;
                end
                if(i_start)begin
                    valid <= 1;
                   
                end
                if(valid == 1)begin
                o_valid<=1;                                              //o_addr이 유효함을 의미
                o_addr<=(channel_cnt*in_row_size/4*(in_column_size))     //channel이 넘어가는 경우 주소값 계산
                + ((B_row_cnt*5)-1%(B_row_cnt+1))                        //B_row_cnt가 넘어가는 경우 주소값 계산
                + (B_column_cnt*in_row_size/4*stride)                    //B_column_cnt가 넘어가는 경우 주소값 계산
                + (s_row_cnt/2-padding_consider_cnt_c)                   //s_row_cnt가 넘어가는 경우 주소 값 계산
                + (in_row_size*column_cnt/4)                             //column이 넘어가는 경우 주소값 계산
                + (row_cnt)                                              //row가 넘어가는 경우 주소값 계산
                ;
               
               if(B_row_cnt==in_row_size/(10*stride)-1&&B_column_cnt==(in_column_size-kernel+padding)/stride && channel_cnt==channel-1&&s_row_cnt==10&&column_cnt==kernel-padding*padding_consider_cnt_r-1&&row_cnt==0) begin                                              //case_1인 경우 끝&& 초기화 시작
                  finish<=1;
                  o_final <= 1;
                  B_column_cnt<=0;
                  padding_consider_cnt_r<=0;
                  B_row_cnt<=0;
                  s_row_cnt<=1;
                  column_cnt<=0;
                  row_cnt<=0;
                  channel_cnt<=0;
                  padding_consider_cnt_c<=0;
                  valid                  <=0;
               end// 초기화 끝
               
               
                 
               else if (B_column_cnt<(in_column_size-kernel+padding)/stride-1&&B_row_cnt==in_row_size/(10*stride)-1&&channel_cnt==channel-1&&s_row_cnt==10&&column_cnt==kernel-padding*padding_consider_cnt_r-1&&row_cnt==0) begin             //B_column_cnt를 끝까지 실행 시작
                     padding_consider_cnt_r<=0;
                     B_column_cnt<=B_column_cnt+1;
                     B_row_cnt<=0;
                     s_row_cnt<=1;
                     column_cnt<=0;
                     row_cnt<=0;
                     channel_cnt<=0;
                     padding_consider_cnt_c<=0;
                     valid <=0;
               end //B_column_cnt를 끝까지 실행 끝
               
               
               else if (B_column_cnt == (in_column_size-kernel+padding)/stride-1&&B_row_cnt==in_row_size/(10*stride)-1&&channel_cnt==channel-1&&s_row_cnt==10&&column_cnt==kernel-padding*padding_consider_cnt_r-1&&row_cnt==0) begin             //B_column_cnt를 끝까지 실행 시작
                     padding_consider_cnt_r<=1;
                     B_column_cnt<=B_column_cnt+1;
                     B_row_cnt<=0;
                     s_row_cnt<=1;
                     column_cnt<=0;
                     row_cnt<=0;
                     channel_cnt<=0;
                     padding_consider_cnt_c<=0;
                     valid <=0;
               end //B_column_cnt를 끝까지 실행 끝
               
                                                                     
               else if (B_row_cnt<in_row_size/(10*stride)-1&&B_row_cnt!=0) begin                 //B_row_cnt가 한줄이 진행중
                    row_cnt<=row_cnt+1;
                    o_stage <=(padding_consider_cnt_r==0)? 5 : 8;
                        if(channel_cnt==channel-1&&s_row_cnt==10&&column_cnt==kernel-padding*padding_consider_cnt_r-1&&row_cnt==1)begin
                            B_row_cnt<=B_row_cnt+1;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=0;
                            channel_cnt<=0;
                            padding_consider_cnt_c<=0;
                            valid <=0;
                        end
                        else if(s_row_cnt==10&&column_cnt==kernel-padding*padding_consider_cnt_r-1&&row_cnt==1)begin
                            channel_cnt<=channel_cnt+1;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=0;
                            padding_consider_cnt_c<=0;
                            valid <=0;
                         end
                        else if(column_cnt==kernel-padding*padding_consider_cnt_r-1&&row_cnt==1)begin
                             row_cnt<=0;
                             column_cnt<=0;  
                             s_row_cnt<=s_row_cnt+1;
                             padding_consider_cnt_c<=0;
                         end
                         else if (row_cnt==1)begin
                            column_cnt<=column_cnt+1;
                            row_cnt<=0;
                        end
               end                                                      //B_row_cnt 한줄이 끝남
             
               else if(B_row_cnt==0) begin                              //B_row_cnt가 0인 경우 시작
                    if(s_row_cnt==1)begin                               //s_row_cnt가 0인 경우 시작
                        o_stage <=(padding_consider_cnt_r==0)? 4 : 7;
                         column_cnt<=column_cnt+1;
                         if(column_cnt==kernel-padding*padding_consider_cnt_r-1)begin
                             column_cnt<=0;  
                             s_row_cnt<=s_row_cnt+1;
                             padding_consider_cnt_c<=1;
                         end
                    end                                                 //s_row_cnt가 0인 경우 끝
                    else if (s_row_cnt!=1) begin                        //s_row_cnt가 0이 아닌 경우 시작
                        o_stage <=(padding_consider_cnt_r==0)? 5 : 8;
                        row_cnt<=row_cnt+1;
                        if(channel_cnt==channel-1&&s_row_cnt==10&&column_cnt==kernel-padding*padding_consider_cnt_r-1&&row_cnt==1)begin
                            B_row_cnt<=B_row_cnt+1;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=0;
                            channel_cnt<=0;
                            padding_consider_cnt_c<=0;
                            valid <=0;
                        end
                        else if(s_row_cnt==10&&column_cnt==kernel-padding*padding_consider_cnt_r-1&&row_cnt==1)begin
                            o_stage <=(padding_consider_cnt_r==0)? 5 : 8;
                            channel_cnt<=channel_cnt+1;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=0;
                            padding_consider_cnt_c<=0;
                            valid <=0;
                         end
                        else if(column_cnt==kernel-padding*padding_consider_cnt_r-1&&row_cnt==1)begin
                             row_cnt<=0;
                             column_cnt<=0;  
                             s_row_cnt<=s_row_cnt+1;
                         end
                         else if (row_cnt==1)begin
                            column_cnt<=column_cnt+1;
                            row_cnt<=0;
                        end
                    end                                                 //s_row_cnt가 0이 아닌 경우 끝    
               end                                                      //B_row_cnt가 0인 경우 끝
               
               
               
                else if(B_row_cnt==in_row_size/(10*stride)-1) begin                                  //B_row_cnt가 0 or 마지막 값인 경우 시작
                    if(s_row_cnt==10)begin                              //s_row_cnt가 0인 경우 시작
                        o_stage <=(padding_consider_cnt_r==0)? 6 : 9;
                         column_cnt<=column_cnt+1;
                          if(column_cnt==kernel-padding*padding_consider_cnt_r-1)begin
                            channel_cnt<=channel_cnt+1;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=0;
                            padding_consider_cnt_c<=0;
                            valid <=0;
                         end
                    end                                                 //s_row_cnt가 0인 경우 끝
                    else if (s_row_cnt!=10) begin                       //s_row_cnt가 0이 아닌 경우 시작
                        o_stage <=(padding_consider_cnt_r==0)? 5 : 8;
                        row_cnt<=row_cnt+1;
                        if(channel_cnt==channel-1&&s_row_cnt==10&&column_cnt==kernel-padding*padding_consider_cnt_r-1&&row_cnt==1)begin
                            B_row_cnt<=B_row_cnt+1;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=0;
                            channel_cnt<=0;
                            padding_consider_cnt_c<=0;
                            valid <=0;
                        end
                        else if(s_row_cnt==10&&column_cnt==kernel-padding*padding_consider_cnt_r-1&&row_cnt==1)begin
                            channel_cnt<=channel_cnt+1;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=0;
                            padding_consider_cnt_c<=0;
                            valid <=0;
             
                         end
                        else if(column_cnt==kernel-padding*padding_consider_cnt_r-1&&row_cnt==1)begin
                             row_cnt<=0;
                             column_cnt<=0;  
                             s_row_cnt<=s_row_cnt+1;
                         end
                         else if (row_cnt==1)begin
                            column_cnt<=column_cnt+1;
                            row_cnt<=0;
                        end
                    end                                                 //s_row_cnt가 0이 아닌 경우 끝    
               end                                                      //B_row_cnt가 0인 경우 끝
               end                                                      // valid 끝
            end                                                         //padding이 2인 경우 끝
           
           
           
           
           
           
           
           
           
           
            //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////case 3  padding 1 stride 2 시작
             else if (padding==1) begin                                                                                                                                                                                                  //case 3 padding이 1인 경우 시작
                if(stride==2)begin
                if (valid == 0)begin
                    o_valid <= 0;
                end
                if(i_start)begin
                    valid <= 1;
                   
                end
                if(valid == 1)begin                                                                                                                                                                                                       //case 3  stried가 2인 경우 시작
                o_valid<=1;                                              //o_addr이 유효함을 의미
                o_addr<=(channel_cnt*in_row_size/4*(in_column_size))     //channel이 넘어가는 경우 주소값 계산
                + (B_row_cnt*5)                                          //B_row_cnt가 넘어가는 경우 주소값 계산
                + ((B_column_cnt)*in_row_size/4*stride)                  //B_column_cnt가 넘어가는 경우 주소값 계산
                + ((s_row_cnt-1)/2)                                      //s_row_cnt가 넘어가는 경우 주소 값 계산
                + (in_row_size*column_cnt/4)                             //column이 넘어가는 경우 주소값 계산
                - (row_cnt)                                              //row가 넘어가는 경우 주소값 계산
                ;
               if(B_row_cnt==in_row_size/(10*stride)-1&&B_column_cnt==(in_column_size-kernel+padding)/stride&&channel_cnt==channel-1&&s_row_cnt==10&&column_cnt==kernel-1&&row_cnt==0) begin                                              //case_1인 경우 끝&& 초기화 시작
                  finish<=1;
                  o_final <= 1;
                  B_column_cnt<=0;
                  padding_consider_cnt_r<=0;
                  B_row_cnt<=0;
                  s_row_cnt<=1;
                  column_cnt<=0;
                  row_cnt<=0;
                  channel_cnt<=0;
                  valid <= 0;
                           
               end                                                      // 초기화 끝  
               else if (B_column_cnt<(in_column_size-kernel+padding)/stride&&B_row_cnt==in_row_size/(10*stride)-1&&channel_cnt==channel-1&&s_row_cnt==10&&column_cnt==kernel-1&&row_cnt==0) begin             //B_column_cnt를 끝까지 실행 시작
                     padding_consider_cnt_r<=1;
                     B_column_cnt<=B_column_cnt+1;
                     B_row_cnt<=0;
                     s_row_cnt<=1;
                     column_cnt<=0;
                     row_cnt<=0;
                     channel_cnt<=0;
                     valid <= 0;
               end                                                                //B_column_cnt를 끝까지 실행 끝
               
               
               else if (B_row_cnt<in_row_size/(10*stride)&&B_row_cnt!=0) begin    //B_row_cnt가 한줄이 진행중
                    if (s_row_cnt%2==1) begin                                     //s_row_cnt가 홀수인 경우 시작
                        row_cnt<=row_cnt-1;
                        if(column_cnt==kernel-1&&row_cnt==0)begin
                             row_cnt<=0;
                             column_cnt<=0;  
                             s_row_cnt<=s_row_cnt+1;
                         end
                         else if (row_cnt==0)begin
                            column_cnt<=column_cnt+1;
                            row_cnt<=1;
                        end
                    end                                                 //s_row_cnt가 홀수인 경우 끝
                    else if (s_row_cnt%2==0) begin                       //s_row_cnt가 짝수인 경우 시작
                        column_cnt<=column_cnt+1;
                        if(channel_cnt==channel-1&&s_row_cnt==10&&column_cnt==kernel-1)begin
                            B_row_cnt<=B_row_cnt+1;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=1;
                            channel_cnt<=0;
                            valid <= 0;

                        end
                        else if(s_row_cnt==10&&column_cnt==kernel-1)begin
                            channel_cnt<=channel_cnt+1;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=1;
                            valid <= 0;
                         end
                        else if(column_cnt==kernel-1)begin
                             row_cnt<=1;
                             column_cnt<=0;  
                             s_row_cnt<=s_row_cnt+1;
                         end
                    end                                                 //s_row_cnt가 짝수인 경우 끝
               end                                                      //B_row_cnt 한줄이 끝남
               
               else if(B_row_cnt==0) begin                             //B_row_cnt가 0인 경우 시작
                    if(s_row_cnt==1)begin                              //s_row_cnt가 0인 경우 시작
                         column_cnt<=column_cnt+1;
                         if(column_cnt==kernel-1)begin
                             column_cnt<=0;  
                             s_row_cnt<=s_row_cnt+1;
                         end
                    end                                                 //s_row_cnt가 0인 경우 끝
                    else if (s_row_cnt%2==1) begin                      //s_row_cnt가 홀수인 경우 시작
                        row_cnt<=row_cnt-1;
                         if(column_cnt==kernel-1&&row_cnt==0)begin
                             row_cnt<=0;
                             column_cnt<=0;  
                             s_row_cnt<=s_row_cnt+1;
                         end
                         else if (row_cnt==0)begin
                            column_cnt<=column_cnt+1;
                            row_cnt<=1;
                        end
                    end                                                 //s_row_cnt가 홀수인 경우 끝
                    else if (s_row_cnt%2==0) begin                      //s_row_cnt가 짝수인 경우 시작
                        column_cnt<=column_cnt+1;
                        if(channel_cnt==channel-1&&s_row_cnt==10&&column_cnt==kernel-1)begin
                            B_row_cnt<=B_row_cnt+1;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=1;
                            channel_cnt<=0;
                            valid <= 0;

                        end
                        else if(s_row_cnt==10&&column_cnt==kernel-1)begin
                            channel_cnt<=channel_cnt+1;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=0;
                            valid <= 0;

                         end
                        else if(column_cnt==kernel-1)begin
                             row_cnt<=1;
                             column_cnt<=0;  
                             s_row_cnt<=s_row_cnt+1;
                         end
                    end                                                 //s_row_cnt가 짝수인 경우 끝      
               end                                                      //B_row_cnt가 0인 경우 끝
               end                                                      //valid 끝
                end                                                     //stride가 2인 경우 끝
               
               
               
               
               
                ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////   case3 padding =1  stride == 1
                else if (stride==1) begin                                                         // stride가 1인 경우 시작
                if (valid == 0)begin
                    o_valid <= 0;
                end
                if(i_start)begin
                    valid <= 1;
                end
                if(valid == 1)begin
                o_valid<=1;                                              //o_addr이 유효함을 의미
                o_addr<=(channel_cnt*in_row_size/4*(in_column_size))    //channel이 넘어가는 경우 주소값 계산
                + (B_row_cnt*2)+(B_row_cnt-1*(1%(B_row_cnt+1)))/2       //B_row_cnt가 넘어가는 경우 주소값 계산
                + ((B_column_cnt)*in_row_size/4)                        //B_column_cnt가 넘어가는 경우 주소값 계산
                + (s_row_cnt/4)                                         //s_row_cnt가 넘어가는 경우 주소 값 계산
                + (in_row_size*column_cnt/4)                            //column이 넘어가는 경우 주소값 계산
                + (B_row_cnt[0] ? (1-row_cnt) : -row_cnt)               //row가 넘어가는 경우 주소값 계산    
                + ((B_row_cnt != 0) && (B_row_cnt[0] == 0) ? 1 : 0)
                ;
               
               if(B_row_cnt==in_row_size/10-1&&B_column_cnt==in_column_size-kernel+padding &&channel_cnt==channel-1&&s_row_cnt==10&&column_cnt==kernel-padding*padding_consider_cnt_r-1&&row_cnt==1) begin                                              //case_1인 경우 끝&& 초기화 시작
                  o_final <= 1;
                  finish<=1;
                  o_valid <= 0;
                  B_column_cnt<=0;
                  padding_consider_cnt_r<=0;
                  B_row_cnt<=0;
                  s_row_cnt<=1;
                  column_cnt<=0;
                  row_cnt<=0;
                  channel_cnt<=0;
                  valid <= 0;
               end                                                      // 초기화 끝  
               
               else if (B_column_cnt< in_column_size-kernel+padding && B_row_cnt==in_row_size/(10)-1&&channel_cnt==channel-1&&s_row_cnt==10&&column_cnt==kernel-padding*padding_consider_cnt_r-1&&row_cnt==1) begin             //B_column_cnt를 끝까지 실행 시작                    
                     B_column_cnt<=B_column_cnt+1;
                     if(B_column_cnt==in_column_size-kernel+padding-1)begin
                     padding_consider_cnt_r <= 1;
                     end
                     B_row_cnt<=0;
                     s_row_cnt<=1;
                     column_cnt<=0;
                     row_cnt<=0;
                     channel_cnt<=0;
                     valid <= 0;
               end                                                                                                          //B_column_cnt를 끝까지 실행 끝
               
             
               
               else if (B_row_cnt<in_row_size/10&-1&B_row_cnt!=0&&B_row_cnt%2==1&&B_row_cnt!=in_row_size/10-1) begin        //B_row_cnt가 홀수일때 진행중
                    if (s_row_cnt==2||s_row_cnt==3||s_row_cnt==6||s_row_cnt==7||s_row_cnt==10) begin                       //s_row_cnt가 홀수인 경우 시작
                        row_cnt<=row_cnt-1;
                        if(channel_cnt==channel-1&&s_row_cnt==10&&column_cnt==kernel-padding*padding_consider_cnt_r-1&&row_cnt==0)begin
                            B_row_cnt<=B_row_cnt+1;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=1;
                            channel_cnt<=0;
                            valid <= 0;

                        end
                        else if(s_row_cnt==10&&column_cnt==kernel-padding*padding_consider_cnt_r-1&&row_cnt==0)begin
                            channel_cnt<=channel_cnt+1;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=1;
                            valid <= 0;

                         end
                        else if(column_cnt==kernel-padding*padding_consider_cnt_r-1&&row_cnt==0)begin
                            if(s_row_cnt==3||s_row_cnt==7||s_row_cnt==10)begin
                                row_cnt<=1;
                             end
                             else begin
                                row_cnt<=1;
                             end
                             column_cnt<=0;  
                             s_row_cnt<=s_row_cnt+1;
                         end
                         else if (row_cnt==0)begin
                            column_cnt<=column_cnt+1;
                            row_cnt<=1;
                        end
                    end                                                                                                        //s_row_cnt가 홀수인 경우 끝
                    else if (s_row_cnt==1||s_row_cnt==4||s_row_cnt==5||s_row_cnt==8||s_row_cnt==9) begin                       //s_row_cnt가 짝수인 경우 시작
                        column_cnt<=column_cnt+1;
                         if(column_cnt==kernel-padding*padding_consider_cnt_r-1)begin
                            if(s_row_cnt==1||s_row_cnt==5||s_row_cnt==9)begin
                                row_cnt<=1;
                             end
                             column_cnt<=0;  
                             s_row_cnt<=s_row_cnt+1;
                         end
                    end                                                                                                          //s_row_cnt가 짝수인 경우 끝
               end                                                                                                               //B_row_cnt가 홀수인 경우 끝남
                else if (B_row_cnt<in_row_size/(10)-1&&B_row_cnt!=0&&B_row_cnt%2==0&&B_row_cnt!=in_row_size/10-1) begin          //B_row_cnt가 짝수일때 진행중
                    if (s_row_cnt==1||s_row_cnt==4||s_row_cnt==5||s_row_cnt==8||s_row_cnt==9) begin                              //s_row_cnt가 홀수인 경우 시작
                        row_cnt<=row_cnt-1;
                         if(column_cnt==kernel-padding*padding_consider_cnt_r-1&&row_cnt==0)begin
                            if(s_row_cnt==1||s_row_cnt==9||s_row_cnt==5)begin
                                row_cnt<=0;
                             end
                             else begin
                                row_cnt<=1;
                             end
                             column_cnt<=0;  
                             s_row_cnt<=s_row_cnt+1;
                         end
                         else if (row_cnt==0)begin
                            column_cnt<=column_cnt+1;
                            row_cnt<=1;
                        end
                    end                                                                                                         //s_row_cnt가 홀수인 경우 끝
                    else if (s_row_cnt==2||s_row_cnt==3||s_row_cnt==6||s_row_cnt==7||s_row_cnt==10) begin                       //s_row_cnt가 짝수인 경우 시작
                        column_cnt<=column_cnt+1;
                        if(channel_cnt==channel-1&&s_row_cnt==10&&column_cnt==kernel-padding*padding_consider_cnt_r-1)begin
                            B_row_cnt<=B_row_cnt+1;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=1;
                            channel_cnt<=0;
                            valid <= 0;

                        end
                        else if(s_row_cnt==10&&column_cnt==kernel-padding*padding_consider_cnt_r-1)begin
                            channel_cnt<=channel_cnt+1;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=1;
                            valid <= 0;

                         end
                        else if(column_cnt==kernel-padding*padding_consider_cnt_r-1)begin
                            if(s_row_cnt==3||s_row_cnt==7||s_row_cnt==10)begin
                                row_cnt<=1;
                             end
                             column_cnt<=0;  
                             s_row_cnt<=s_row_cnt+1;
                         end
                    end                                                                                          //s_row_cnt가 짝수인 경우 끝
               end                                                                                               //B_row_cnt가 짝수인 경우 끝남
               
               else if(B_row_cnt==0) begin                                                                      //B_row_cnt가 0인 경우 시작
                        if (s_row_cnt==4||s_row_cnt==5||s_row_cnt==8||s_row_cnt==9) begin                       //s_row_cnt가 홀수인 경우 시작
                        row_cnt<=row_cnt-1;
                         if(column_cnt==kernel-padding*padding_consider_cnt_r-1&&row_cnt==0)begin
                            if(s_row_cnt==5||s_row_cnt==9)begin
                                row_cnt<=0;
                             end
                             else begin
                                row_cnt<=1;
                             end
                             column_cnt<=0;  
                             s_row_cnt<=s_row_cnt+1;
                         end
                         else if (row_cnt==0)begin
                            column_cnt<=column_cnt+1;
                            row_cnt<=1;
                        end
                    end                                                                                                        //s_row_cnt가 홀수인 경우 끝
                    else if (s_row_cnt==1||s_row_cnt==2||s_row_cnt==3||s_row_cnt==6||s_row_cnt==7||s_row_cnt==10) begin        //s_row_cnt가 짝수인 경우 시작
                        column_cnt<=column_cnt+1;
                        if(channel_cnt==channel-1&&s_row_cnt==10&&column_cnt==kernel-padding*padding_consider_cnt_r-1)begin
                            B_row_cnt<=B_row_cnt+1;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=1;
                            channel_cnt<=0;
                            valid <= 0;

                        end
                        else if(s_row_cnt==10&&column_cnt==kernel-padding*padding_consider_cnt_r-1)begin
                            channel_cnt<=channel_cnt+1;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=0;
                            valid <= 0;

                         end
                        else if(column_cnt==kernel-padding*padding_consider_cnt_r-1)begin
                            if(s_row_cnt==3||s_row_cnt==7)begin
                                row_cnt<=1;
                             end
                             column_cnt<=0;  
                             s_row_cnt<=s_row_cnt+1;
                         end
                    end                                                                      //s_row_cnt가 짝수인 경우 끝      
               end                                                                           //B_row_cnt가 0인 경우 끝
                else if(B_row_cnt==in_row_size/10-1) begin                                   //B_row_cnt가 마지막인 경우 시작
                        if (s_row_cnt==2||s_row_cnt==3||s_row_cnt==6||s_row_cnt==7) begin    //s_row_cnt가 홀수인 경우 시작
                        row_cnt<=row_cnt-1;
                         if(column_cnt==kernel-padding*padding_consider_cnt_r-1&&row_cnt==0)begin
                            if(s_row_cnt==3||s_row_cnt==7)begin
                                row_cnt<=1;
                             end
                             else begin
                                row_cnt<=1;
                             end
                             column_cnt<=0;  
                             s_row_cnt<=s_row_cnt+1;
                         end
                         else if (row_cnt==0)begin
                            column_cnt<=column_cnt+1;
                            row_cnt<=1;
                        end
                    end                                                                                                   //s_row_cnt가 홀수인 경우 끝
                    else if (s_row_cnt==1||s_row_cnt==4||s_row_cnt==5||s_row_cnt==8||s_row_cnt==9||s_row_cnt==10) begin   //s_row_cnt가 짝수인 경우 시작
                        column_cnt<=column_cnt+1;
                        if(channel_cnt==channel-1&&s_row_cnt==10&&column_cnt==kernel-padding*padding_consider_cnt_r-1)begin
                            B_row_cnt<=B_row_cnt+1;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=1;
                            channel_cnt<=0;
                            valid <= 0;

                        end
                        else if(s_row_cnt==10&&column_cnt==kernel-padding*padding_consider_cnt_r-1)begin
                            channel_cnt<=channel_cnt+1;
                            s_row_cnt<=1;
                            column_cnt<=0;
                            row_cnt<=1;
                            valid <= 0;

                         end
                        else if(column_cnt==kernel-padding*padding_consider_cnt_r-1)begin
                            if(s_row_cnt==1||s_row_cnt==5||s_row_cnt==10)begin
                                row_cnt<=1;
                             end
                             column_cnt<=0;  
                             s_row_cnt<=s_row_cnt+1;
                         end
                    end                                                 //s_row_cnt가 짝수인 경우 끝      
               end                                                      //B_row_cnt가 마지막인 경우 끝
               end                                                      //valid      끝
                end                                                     // stride가 1인 경우 끝
            end                                                         //padding이 1인 경우 끝
        end                                                             //case_3인 경우 끝
     end                                                                //always문 끝

endmodule

`include "iter_mult.v"

module fixed_point_iterative_Multiplier_sva #(
  parameter int n = 32,  // bit width
  parameter int d = 16,  // number of decimal bits
  parameter bit sign = 0  // 1 if signed, 0 otherwise.
) (
  input logic clk,
  input logic reset,

  output logic recv_rdy,
  input logic recv_val,
  input logic [n - 1:0] a,
  input logic [n - 1:0] b,

  input logic send_rdy,
  output logic send_val,
  output logic [n - 1:0] c
);

  fixed_point_iterative_Multiplier #(n, d) tb (
    .clk(clk),
    .reset(reset),
    .recv_rdy(recv_rdy),
    .recv_val(recv_val),
    .a(a),
    .b(b),
    .send_rdy(send_rdy),
    .send_val(send_val),
    .c(c)
  );

  assign state = fixed_point_iterative_Multiplier.control.state;
  assign next_state = fixed_point_iterative_Multiplier.control.next_state;

  initial begin
    assume(clk == 0);
    assume(reset == 1);
  end

  sequence NEXT_STATE;
    @(posedge clk) state == $past(next_state);
  endsequence

  sequence IDLE_TO_CALC;
    @(posedge clk) state == 2'd0 ##1 state == 2'd1;
  endsequence

  sequence CALC_TO_DONE;
    @(posedge clk) state == 2'd01 ##n state == 2'd2;
  endsequence

  sequence CYCLE_TEST;
    @(posedge clk) (recv_rdy && recv_val) ##(n+1) (send_val);
  endsequence

  sequence FAST_SEND_VAL;
    @(posedge clk) (recv_rdy && recv_val) ##[0:n] (send_val);
  endsequence

  sequence SLOW_SEND_VAL;
    @(posedge clk) $rose(recv_rdy && recv_val) ##[(n+2):2*n] ($rose(send_val));
  endsequence

  property IDLE_TO_CALC_PROP;
    if (state == 2'd0 && recv_val && recv_rdy) @(posedge clk) IDLE_TO_CALC;
  endproperty

  property CALC_TO_DONE_PROP;
    if (state == 2'd1) @(posedge clk) CALC_TO_DONE;
  endproperty

  CYCLE : cover property(@(posedge clk) CYCLE_TEST);
  CYCLE_TIME : assert property(@(posedge clk) not (FAST_SEND_VAL or SLOW_SEND_VAL));
  NEXT_STATE_TEST : assert property(@(posedge clk) NEXT_STATE or state == 0);
  CALC : assert property(@(posedge clk) IDLE_TO_CALC_PROP);
  DONE : assert property(CALC_TO_DONE_PROP);
endmodule


// For Demonstration purposes only
// Code has not been fully verified or tested 
// User assumes risk
`timescale 1ns / 1ps
module axil_slave
(
    input  wire         s_axi_aclk,
    input  wire         s_axi_aresetn,

    input  wire         s_axi_awvalid,
    output reg          s_axi_awready,
    input  wire [23: 0] s_axi_awaddr,
    input  wire [1: 0]  s_axi_awprot,

    input  wire         s_axi_wvalid,
    output reg          s_axi_wready,
    input  wire [31: 0] s_axi_wdata,
    input  wire [3: 0]  s_axi_wstrb,

    output reg          s_axi_bvalid,
    input  wire         s_axi_bready,
    output reg  [1: 0]  s_axi_bresp,

    input  wire         s_axi_arvalid,
    output reg          s_axi_arready,
    input  wire [23: 0] s_axi_araddr,
    input  wire [1: 0]  s_axi_arprot,

    output reg          s_axi_rvalid,
    input  wire         s_axi_rready,
    output reg [31: 0]  s_axi_rdata,
    output reg  [1: 0]  s_axi_rresp
);

reg [23:0] read_address;
reg [23:0] write_address;
reg [31:0] write_data;
wire write_address_inrange;
wire read_address_inrange;
localparam OKAY = 2'b00;
localparam DECERR = 2'b11;
reg [3:0] timer;
localparam TIMEOUT = 4'd15;

localparam WRITE_BASE_ADDRESS = 24'h000000;
localparam WRITE_LAST_ADDRESS = 24'h000200;
localparam READ_BASE_ADDRESS  = 24'h000000;
localparam READ_LAST_ADDRESS  = 24'h000200;
localparam INIT = 0,WRR_READY = 1,WADDR_ACCEPT = 2,WADDR_INRANGE = 3,
           WADDR_ERROR = 4,WRITE_READY = 5,WRITE_OK = 6,WRITE_ERROR = 7,
           BRESP_VALID = 8,BRESP_ACCEPT = 9,BRESP_ERROR = 10,
           RADDR_ACCEPT = 11,RADDR_INRANGE = 12,RADDR_ERROR = 13,
           RDATA_VALID = 14,RDATA_OK = 15,RDATA_ERROR = 16;
reg [4:0] state,next_state;

reg [31:0] control_register;
reg [31:0] status_register;
reg [6:0]  memory_address;
reg [31:0] data_memory [0:127];
reg s_axis_aresetn_reg;

assign write_address_inrange = ((write_address >= WRITE_BASE_ADDRESS)
                              && (write_address <= WRITE_LAST_ADDRESS)) ? 1 : 0;
assign read_address_inrange = ((read_address >= READ_BASE_ADDRESS)
                              && (read_address <= READ_LAST_ADDRESS)) ? 1 : 0;

always @(*) begin
  next_state = state;
  case (state)
    INIT:
      next_state = WRR_READY;
    WRR_READY: begin
      if (s_axi_awvalid == 1)
        next_state = WADDR_ACCEPT;
      else if (s_axi_arvalid == 1)
        next_state = RADDR_ACCEPT;
    end
    WADDR_ACCEPT: begin
      if (write_address_inrange == 1)
        next_state = WADDR_INRANGE;
      else
        next_state = WADDR_ERROR;
    end
    WADDR_INRANGE:
      next_state = WRITE_READY;
    WADDR_ERROR:
      next_state = BRESP_VALID;
    WRITE_READY: begin
      if (s_axi_wvalid == 1)
        next_state = WRITE_OK;
      else if (timer == TIMEOUT)
        next_state = INIT;
     end
     WRITE_OK:
        next_state = BRESP_VALID;
    WRITE_ERROR:
      next_state = BRESP_VALID;
    BRESP_VALID: begin
      if (s_axi_bready == 1)
        next_state = BRESP_ACCEPT;
      else if (timer == TIMEOUT)
        next_state = INIT;
    end
    BRESP_ACCEPT:
      next_state = INIT;
    BRESP_ERROR:
      next_state = INIT;
    RADDR_ACCEPT: begin
      if (read_address_inrange == 1)
        next_state = RADDR_INRANGE;
      else
        next_state = RADDR_ERROR;
    end
    RADDR_INRANGE: begin
       if (s_axi_rready == 1)
        next_state = RDATA_VALID;
      else if (timer == TIMEOUT)
        next_state = INIT;
    end
    RADDR_ERROR:
      next_state = INIT;
    RDATA_VALID:
      next_state = RDATA_OK;
    RDATA_OK:
      next_state = INIT;
    RDATA_ERROR:
      next_state = INIT;
    default:
      next_state = INIT;
    endcase
end

always @(posedge s_axi_aclk)
begin
  s_axis_aresetn_reg <= s_axi_aresetn;
  if (s_axi_aresetn == 0)
    state <= INIT;
  else
    state <= next_state;
end

always @(posedge s_axi_aclk)
begin
  if (s_axi_aresetn == 0) begin
      s_axi_awready <= 1'b0;
      s_axi_wready  <= 1'b0;
      s_axi_bvalid  <= 1'b0;
      s_axi_bresp   <= 2'b00;
      s_axi_arready <= 1'b0;
      s_axi_rvalid  <= 1'b0;
      s_axi_rresp   <= 2'b00;
 end else
  case (next_state)
    INIT : begin
      s_axi_awready <= 1'b0;
      s_axi_wready  <= 1'b0;
      s_axi_bvalid  <= 1'b0;
      s_axi_bresp   <= 2'b00;
      s_axi_arready <= 1'b0;
      s_axi_rvalid  <= 1'b0;
      s_axi_rresp   <= 2'b00;
    end
    WRR_READY : begin
      s_axi_wready  <= 1'b0;
      s_axi_bvalid  <= 1'b0;
      s_axi_bresp   <= 2'b00;
      s_axi_awready <= 1'b1;
      s_axi_arready <= 1'b1;
      s_axi_rvalid  <= 1'b0;
      s_axi_rresp   <= 2'b00;
      write_address <= s_axi_awaddr;
      read_address  <= s_axi_araddr;
     end
   WADDR_ACCEPT : begin
      s_axi_awready <= 1'b0;
      s_axi_arready <= 1'b0;
      write_address <= s_axi_awaddr;
     end
    WRITE_READY : begin
      s_axi_wready  <= 1'b1;
      write_data <= s_axi_wdata;
      timer <= timer+1;
    end
    WRITE_OK : begin
      timer <= 0;
      s_axi_bresp   <= OKAY;
      s_axi_wready  <= 1'b0;
     end
   WRITE_ERROR : begin
      s_axi_bresp   <= DECERR;
      s_axi_wready  <= 1'b0;
     end
   BRESP_VALID : begin
      s_axi_bvalid  <= 1'b1;
      timer <= timer+1;
     end
   BRESP_ACCEPT : begin
      s_axi_bvalid  <= 1'b0;
      s_axi_bresp   <= OKAY;
      timer <= 0;
     end
    RADDR_ACCEPT : begin
      read_address  <= s_axi_araddr;
      s_axi_awready <= 1'b0;
      s_axi_arready <= 1'b0;
     end
   RADDR_INRANGE : begin
     s_axi_rresp   <= OKAY;
     timer <= timer+1;
    end
    RADDR_ERROR :
     s_axi_rresp   <= DECERR;
    RDATA_VALID : begin
      s_axi_rvalid  <= 1'b1;
      s_axi_rresp   <= 2'b00;
      timer <= 0;
    end
    RDATA_OK :
      s_axi_rvalid  <= 1'b0;
    RDATA_ERROR :
      s_axi_rvalid  <= 1'b0;
    
    endcase
end

always @(posedge s_axi_aclk)
begin
  if (state == WRITE_OK)
  case (write_address)
    24'h4 : control_register <= write_data;
  endcase
end


always @(posedge s_axi_aclk)
begin
  case (read_address[23 : 8])
      16'h0000:
        case (read_address[7 : 0])
          8'h4: s_axi_rdata <= control_register;
        endcase
      16'h0001: s_axi_rdata <= data_memory[read_address[7:2]];
    endcase
end

always @(posedge s_axi_aclk)
begin
  if ((state == WRITE_OK) && (write_address[23: 8] == 24'h0001))
     data_memory[write_address[7:2]] <= write_data;
end

endmodule

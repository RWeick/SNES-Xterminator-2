`default_nettype none

// Standalone behavioral replacement for the AMI PEEL18CV8PC-35 in the X-Terminator 2.
//
// Original PEEL DIP-20 pin map:
//   1  WRITE_N       11 CIC               16 EEPROM_OE_N
//   2  SW1           12 SRAM_WE_N         17 high-Z / buried state
//   3  SW2           13 high-Z / state    18 CART_CONTROL
//   4  O19           14 high-Z / state    19 READ_TOP_N
//   5  A0            15 high-Z / state    20 VCC
//   6  PWR_SENSE     10 GND
//   7  BA1
//   8  READ_BOTTOM_N
//   9  BA2
//
// The four high-Z PEEL macrocells are consistent with the four recovered
// states.  Their physical pins remain tri-stated in this replacement.
module ami_18cv8pc_replacement (
    input  wire write_n,             // PEEL pin 1
    input  wire switch1,             // PEEL pin 2
    input  wire switch2,             // PEEL pin 3
    input  wire o19,                 // PEEL pin 4
    input  wire a0,                  // PEEL pin 5
    input  wire pwr_sense,           // PEEL pin 6
    input  wire ba1,                 // PEEL pin 7
    input  wire read_bottom_n,       // PEEL pin 8
    input  wire ba2,                 // PEEL pin 9
    input  wire cic_in_p7,           // PEEL pin 11

    output wire sram_we_n,           // PEEL pin 12
    output wire pin13_hiz,           // PEEL pin 13
    output wire pin14_hiz,           // PEEL pin 14
    output wire pin15_hiz,           // PEEL pin 15
    output wire eeprom_oe_n,         // PEEL pin 16
    output wire pin17_hiz,           // PEEL pin 17
    output wire cart_control,        // PEEL pin 18
    output wire read_top_n           // PEEL pin 19
);

    // Q: SCAN/command mapper state.  CIC loads the physical SCAN condition.
    reg mapper_q;
    initial mapper_q = 1'b0;

    wire mapper_q_next =
        (cic_in_p7 & ~switch2) |
        (switch1 & ~switch2 & ~o19 & ~a0 & ~ba1 & ~ba2) |
        (mapper_q & ~cic_in_p7 & (o19 | ba1 | ba2 | ~a0));

    always @(posedge write_n or posedge cic_in_p7) begin
        if (cic_in_p7)
            mapper_q <= switch1 & ~switch2;
        else
            mapper_q <= mapper_q_next;
    end

    // S: SRAM-write mode.  CIC asynchronously presets it.  A selected even
    // command clears it; a powered selected odd command sets it.
    reg sram_mode_q;
    initial sram_mode_q = 1'b0;

    wire sram_mode_q_next =
        cic_in_p7 |
        (sram_mode_q & (o19 | a0 | ba1 | ba2)) |
        (~o19 & a0 & pwr_sense & ~ba1 & ~ba2);

    always @(posedge write_n or posedge cic_in_p7) begin
        if (cic_in_p7)
            sram_mode_q <= 1'b1;
        else
            sram_mode_q <= sram_mode_q_next;
    end

    // E: sticky ACTION enable for the powered session.
    // A: transient ACTION state sampled on every rising /WRITE edge.
    reg action_enable_q;
    reg action_q;

    initial action_enable_q = 1'b0;
    initial action_q = 1'b0;

    wire action_enable_set =
        ~switch2 & ~o19 & a0 & ~ba1 & ~ba2;

    always @(posedge write_n or negedge pwr_sense) begin
        if (!pwr_sense)
            action_enable_q <= 1'b0;
        else if (action_enable_set)
            action_enable_q <= 1'b1;
    end

    always @(posedge write_n) begin
        action_q <= action_enable_q & ~switch1 & switch2;
    end

    // PEEL pin 12: SRAM /WE, with distinct power-on and handler equations.
    wire sram_we_reset_n =
        (~o19 & a0 & pwr_sense & ~ba1 & ~ba2) |
        cic_in_p7 |
        write_n;
    wire sram_we_handler_n =
        o19 | a0 | ba1 | ba2 | cic_in_p7 | write_n;
    assign sram_we_n = sram_mode_q ? sram_we_handler_n : sram_we_reset_n;

    // PEEL pin 16: BIOS EEPROM /OE in the original even-jumper routing.
    assign eeprom_oe_n =
        ba1 |
        ba2 |
        (~action_q & read_bottom_n) |
        (o19 & read_bottom_n) |
        (~mapper_q & ~action_q & ~switch1) |
        (~mapper_q & ~action_q & switch2) |
        (~action_q & ~switch1 & cic_in_p7) |
        (~action_q & switch2 & cic_in_p7) |
        (~switch1 & o19 & cic_in_p7) |
        (switch2 & o19 & cic_in_p7) |
        (~mapper_q & o19 & ~cic_in_p7) |
        (~mapper_q & ~action_q & ~cic_in_p7 & write_n) |
        (~action_q & ~o19 & a0 & ~cic_in_p7 & ~write_n);

    // PEEL pin 18: Famicom/cartridge control.
    assign cart_control =
        (~ba1 & ~ba2) |
        (~switch1 & cic_in_p7) |
        (switch2 & cic_in_p7) |
        (~mapper_q & ~cic_in_p7) |
        (read_bottom_n & write_n);

    // PEEL pin 19: read gate to the cartridge.
    assign read_top_n =
        read_bottom_n |
        (switch1 & ~switch2 & cic_in_p7) |
        (mapper_q & o19 & ~cic_in_p7) |
        (mapper_q & ~a0 & ~cic_in_p7) |
        (mapper_q & ba1 & ~cic_in_p7) |
        (mapper_q & ba2 & ~cic_in_p7) |
        (mapper_q & ~cic_in_p7 & write_n) |
        (action_q & ~o19 & ~ba1 & ~ba2) |
        (switch1 & ~switch2 & ~o19 & ~a0 & ~ba1 & ~ba2 & ~write_n);

    assign pin13_hiz = 1'bz;
    assign pin14_hiz = 1'bz;
    assign pin15_hiz = 1'bz;
    assign pin17_hiz = 1'bz;

endmodule

`default_nettype wire

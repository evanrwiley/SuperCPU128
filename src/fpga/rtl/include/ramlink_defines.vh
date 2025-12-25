// RAMLink Register Definitions
// Based on CMD RAMLink User's Manual
// Base Address: $DE00 (IO1)

`ifndef RAMLINK_DEFINES_VH
`define RAMLINK_DEFINES_VH

// Register Offsets from Base ($DE00)
`define RL_REG_STATUS       4'h0
`define RL_REG_COMMAND      4'h1
`define RL_REG_C_ADDR_L     4'h2
`define RL_REG_C_ADDR_H     4'h3
`define RL_REG_M_ADDR_L     4'h4
`define RL_REG_M_ADDR_M     4'h5
`define RL_REG_M_ADDR_H     4'h6
`define RL_REG_LEN_L        4'h7
`define RL_REG_LEN_H        4'h8
// $DE09 Unused
`define RL_REG_ADDR_CTRL    4'hA
// $DE0B-$DE0D Unused
`define RL_REG_ERROR        4'hE
// $DE0F Unused

// Sector/Job Interface ($DE20 range - mapped to $DE00 + offset in some modes, 
// but manual says $DE20. Since IO1 is only 256 bytes ($DE00-$DEFF), 
// these are likely at offset $20)
`define RL_REG_JOB          8'h20
`define RL_REG_TRACK        8'h21
`define RL_REG_SECTOR       8'h22
`define RL_REG_S_C_ADDR_L   8'h23
`define RL_REG_S_C_ADDR_H   8'h24
`define RL_REG_PARTITION    8'h25
`define RL_REG_BANK_128     8'h26

// Command Register ($DE01) Bits
`define RL_CMD_EXECUTE      8'h80
`define RL_CMD_AUTOLOAD     8'h20
`define RL_CMD_TRANSFER_MASK 8'h03
`define RL_CMD_TO_RL        8'h00
`define RL_CMD_FROM_RL      8'h01
`define RL_CMD_SWAP         8'h02
`define RL_CMD_VERIFY       8'h03

// Job Codes ($DE20)
`define RL_JOB_READ         8'h80
`define RL_JOB_WRITE        8'h90
`define RL_JOB_VERIFY       8'hA0
`define RL_JOB_SWAP         8'hB0

`endif // RAMLINK_DEFINES_VH

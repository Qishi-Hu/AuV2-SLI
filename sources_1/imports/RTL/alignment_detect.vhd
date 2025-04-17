-- Engineer: Qihsi Hu 
-- Create Date: 12/05/2024 08:04:50 PM
-- Design Name: 
-- Description: Manage the dealy and bitslipping of the SERDES based on invald words

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity alignment_detect is
    Port ( clk            : in  STD_LOGIC;
           invalid_symbol : in  STD_LOGIC;
           delay_count    : out std_logic_vector(4 downto 0);
           delay_ce       : out STD_LOGIC;
           bitslip        : out STD_LOGIC;
           symbol_sync    : out STD_LOGIC);
end alignment_detect;

architecture Behavioral of alignment_detect is
    --------------------------------------
    -- Signals for controlling the bitslip 
    -- and delay so we can sync symbols
    --------------------------------------
    signal count          : unsigned(19 downto 0) := (others => '0');
    signal signal_quality : unsigned(27 downto 0) := (others => '0');
    signal holdoff        : unsigned(9 downto 0)  := (others => '0');
    signal error_seen     : std_logic := '0';
    signal idelay_ce      : std_logic                    := '0';
    signal idelay_count   : std_logic_vector(4 downto 0) := (others => '0');
    signal symbol_sync_i  : std_logic                    := '0';

begin

    delay_count <= idelay_count;
    delay_ce    <= idelay_ce;
 
detect_alignment_proc: process(clk)
    begin
        -------------------------------------------------------------
        -- If there are a dozen or so symbol errors in at a rate of 
        -- greater than 1 in a million then advance the delay and
        -- if that wraps then assert the bitslip signal
        -------------------------------------------------------------
        if rising_edge(clk) then
            -----------------------------------
            -- See if an error has been seen
            --
            -- Holdoff gives a few cycles for 
            -- bitslips and delay changes to 
            -- take effect.
            -----------------------------------
            error_seen <= '0';
            if holdoff = 0 then
                if invalid_symbol = '1' then
                    error_seen <= '1';
                end if;
            else 
                holdoff <= holdoff-1;
            end if;
            ---------------------------------------------
            -- Keep track of valid symbol count vs errors
            -- 
            -- Each error increase the count by a million, 
            -- each valid sysmbol decreases the count by 
            -- one. So after 12 errors it will cause us to
            -- change bitslip or delay settings, but it will
            -- take 7 million cycles until the high four 
            -- bits are zeros (and the link considered OK)
            -----------------------------------------------
            bitslip <= '0';
            idelay_ce <= '0';
            if error_seen = '1' then
                if signal_quality(27 downto 24) = x"F" then
                    ------------------------------------------
                    -- Enough errors to cause us to loose sync 
                    -- (if we had it!) 
                    ------------------------------------------
                    symbol_sync_i         <= '0';
                    --------------------------------------                    
                    -- Hold off acting on any more errors
                    -- while we adjust the delay or bitslip
                    --------------------------------------                    
                    holdoff <= (others => '1');                    
                    -----------------------
                    -- Bitslip if required
                    -----------------------
                    if unsigned(idelay_count) = 31 then   
                        bitslip <= '1';
                    end if;
                    -------------------------------------------------------------------
                    -- And adjust the delay setting (will wrap to 0 when bitslipping)
                    -------------------------------------------------------------------
                    idelay_count  <= std_logic_vector(unsigned(idelay_count)+1);
                    idelay_ce <= '1';   
                    -------------------------------------------------------------------
                    -- It will need 4M good symbols to avoid adjusting the timing again 
                    -------------------------------------------------------------------
                    signal_quality(27 downto 24) <= x"4";
                else
                    signal_quality <= signal_quality + x"000100";   -- add a million if there is a symbol error
                end if;
            else 
                -----------------------------------------------
                -- Count down by one, as we are one symbol 
                -- closer to having a valid stream
                -----------------------------------------------
                if signal_quality(27 downto 24) > 0 then
                    signal_quality <= signal_quality - 1;   -- add a million if there is a symvole error;
                end if;        
            end if;
            ------------------------------------
            -- if we have counted down about 3M
            -- symbols without any symbol errors
            -- being seen then we are in sync
            ------------------------------------
            if signal_quality(27 downto 24) = "0000" then 
                symbol_sync <= '1';
            end if;
        end if;        
    end process;

end Behavioral;

--
--# Explanation of `signal_quality` Signal in the Alignment Detection Logic

--The `signal_quality` signal is a 28-bit unsigned counter that serves as a quality metric for the incoming data stream in the SERDES alignment detection system. Here's how it works:

--## Purpose
--It tracks the balance between valid and invalid symbols to determine when to adjust the delay/bitslip settings and when the link is properly synchronized.

--## Operation

--1. **Error Handling (invalid symbols)**:
--   - When an invalid symbol is detected (`invalid_symbol = '1'`), `signal_quality` is increased by 1,000,000 (hex `x"100000"`)
--   - This large increment means even a few errors will quickly raise the counter value

--2. **Valid Symbol Counting**:
--   - For each valid symbol (when no error is detected), `signal_quality` is decremented by 1
--   - This creates a very slow recovery rate - it takes 1 million valid symbols to offset one error

--3. **Threshold Detection**:
--   - The system monitors bits 27-24 (the top 4 bits) of the counter
--   - When these bits reach `xF` (15 in decimal), it triggers alignment correction:
--     * Adjusts the delay setting (or does a bitslip if delay wraps around)
--     * Resets the quality metric to `x"400000"` (4 in the top nibble)
--     * Drops the sync signal (`symbol_sync_i <= '0'`)

--4. **Sync Determination**:
--   - When the top 4 bits return to `0000` (after about 4 million valid symbols without errors), the system considers the link synchronized
--   - This is indicated by asserting `symbol_sync`

--## Key Characteristics
--- Asymmetric response: Errors have immediate impact (large increments) while recovery is gradual (small decrements)
--- Hysteresis: The system requires sustained good performance (millions of valid symbols) before declaring sync
--- The large counter size (28 bits) allows for tracking over long periods

--This design ensures that the system:
--1. Quickly responds to alignment problems (many errors)
--2. Doesn't overreact to occasional errors
--3. Only declares synchronization when the link has demonstrated sustained reliability


--No, the wrapping of `delay_count` from 31 back to 0 is actually an intentional and important part of the design - it's not an issue but rather a key feature of the alignment mechanism. Here's why it works correctly:

--## How Delay Count Wrapping is Handled

--1. **Normal Delay Increment**:
--   - When errors accumulate (top 4 bits of `signal_quality` reach xF), the system:
--     * Increments `delay_count` by 1
--     * Asserts `delay_ce` (delay change enable)
--     * If not at maximum delay (31), this just moves the sampling point slightly

--2. **At Maximum Delay (31)**:
--   - When `delay_count` reaches 31 and needs to increment again:
--     * The count wraps to 0 (via `std_logic_vector(unsigned(idelay_count)+1)`)
--     * **AND** the system asserts `bitslip` (this is the critical part)
--     * The holdoff timer is activated to allow time for the bitslip to take effect

--3. **Why This Works**:
--   - The bitslip operation changes how the SERDES interprets the bit boundaries
--   - After exhausting all 32 possible delay settings (0-31) without success, a bitslip gives an entirely new set of 32 possible delay positions to try
--   - This creates a complete search of all possible phase alignments

--## The Complete Alignment Process

--1. The system tries all 32 delay settings (0-31) for the current bit alignment
--2. If none work (delay wraps from 31→0), it performs a bitslip and starts over with new delay settings
--3. This continues until either:
--   - A stable alignment is found (top 4 bits of `signal_quality` return to 0)
--   - Or it keeps cycling indefinitely (if no valid alignment exists)

--## Robustness Features

--1. **Holdoff Period**:
--   - After any adjustment (delay change or bitslip), a holdoff period prevents immediate re-evaluation
--   - This gives time for the new settings to stabilize

--2. **Progressive Threshold**:
--   - After a bitslip, the system sets `signal_quality` to x400000 (not all the way to 0)
--   - This means it requires ~4 million good symbols to fully sync, preventing premature declaration

--So rather than being an issue, this wrapping behavior combined with bitslip is exactly what enables the system to methodically search through all possible alignment combinations until it finds a stable one.
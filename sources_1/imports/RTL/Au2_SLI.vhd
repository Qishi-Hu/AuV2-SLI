-- Company: 
-- Engineer: Qihsi Hu 
-- Create Date: 12/05/2024 08:04:50 PM
-- Design Name: 
-- Module Name: hdmi_design
-- Description: top moudle

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VComponents.all;
use IEEE.STD_LOGIC_ARITH.ALL;  -- optional, for older VHDL versions
use IEEE.STD_LOGIC_UNSIGNED.ALL; -- optional, for older VHDL versions
use IEEE.NUMERIC_STD.ALL;      -- Required for unsigned arithmetic

entity Au2_SLI is
    Port ( 
        clk100    : in STD_LOGIC;
        led           : out   std_logic_vector(7 downto 0) :=(others => '0');
        newSW            : in    std_logic_vector(3 downto 0) :=(others => '0');
        -- four-line handsake signals for two camera interfaces
        C1_out : out    std_logic_vector(1 downto 0);
        C1_in : in    std_logic_vector(1 downto 0);
        C2_out : out    std_logic_vector(1 downto 0);
        C2_in : in    std_logic_vector(1 downto 0);
       -- VS    : out STD_LOGIC;
       -- fg : out STD_LOGIC;
       
     
        --HDMI input signals
        hdmi_rx_cec   : inout std_logic;
        hdmi_rx_hpa   : out   std_logic;
        hdmi_rx_scl   : in    std_logic;
        hdmi_rx_sda   : inout std_logic;
        hdmi_rx_clk_n : in    std_logic;
        hdmi_rx_clk_p : in    std_logic;
        hdmi_rx_n     : in    std_logic_vector(2 downto 0);
        hdmi_rx_p     : in    std_logic_vector(2 downto 0);

        --- HDMI out
--        hdmi_tx_cec   : inout std_logic;
        hdmi_tx_clk_n : out   std_logic;
        hdmi_tx_clk_p : out   std_logic;
--        hdmi_tx_hpd   : in    std_logic;
--        hdmi_tx_rscl  : inout std_logic;
--        hdmi_tx_rsda  : inout std_logic;
        hdmi_tx_p     : out   std_logic_vector(2 downto 0);
        hdmi_tx_n     : out   std_logic_vector(2 downto 0)     
    );
end Au2_SLI;

architecture Behavioral of Au2_SLI is
    component ref_clk is
    Port (
        clk_in    : in STD_LOGIC;    
        clk_out : out STD_LOGIC;
        clk10 : out STD_LOGIC;
        clk125 : out STD_LOGIC;
        clk625 : out STD_LOGIC
    );
    end component;
    component hdmi_io is
    Port ( 
        clk100    : in STD_LOGIC;
        clk200    : in STD_LOGIC;
        clk125 : in STD_LOGIC;
        clk625 : in STD_LOGIC;
        clk10 : in STD_LOGIC;
        -------------------------------
        -- Control signals
        -------------------------------
        clock_locked  : out std_logic;
        data_synced   : out std_logic;
        debug         : out std_logic_vector(7 downto 0);  
        sel : out std_logic; 
        -------------------------------
        --HDMI input signals
        -------------------------------
        hdmi_rx_cec   : inout std_logic;
        hdmi_rx_hpa   : out   std_logic;
        hdmi_rx_scl   : in    std_logic;
        hdmi_rx_sda   : inout std_logic;
        hdmi_rx_clk_n : in    std_logic;
        hdmi_rx_clk_p : in    std_logic;
        hdmi_rx_n     : in    std_logic_vector(2 downto 0);
        hdmi_rx_p     : in    std_logic_vector(2 downto 0);

        -------------
        -- HDMI out
        -------------
       -- hdmi_tx_cec   : inout std_logic;
        hdmi_tx_clk_n : out   std_logic;
        hdmi_tx_clk_p : out   std_logic;
       -- hdmi_tx_hpd   : in    std_logic;
       -- hdmi_tx_rscl  : inout std_logic;
       -- hdmi_tx_rsda  : inout std_logic;
        hdmi_tx_p     : out   std_logic_vector(2 downto 0);
        hdmi_tx_n     : out   std_logic_vector(2 downto 0);

        pixel_clk     : out std_logic;
        -------------------------------
        -- VGA data recovered from HDMI
        -------------------------------
        in_hdmi_detected : out std_logic;
        in_blank        : out std_logic;
        in_hsync        : out std_logic;
        in_vsync        : out std_logic;
        in_red          : out std_logic_vector(7 downto 0);
        in_green        : out std_logic_vector(7 downto 0);
        in_blue         : out std_logic_vector(7 downto 0);
        is_interlaced   : out std_logic;
        is_second_field : out std_logic;
            
        -------------------------------------
        -- Audio Levels
        -------------------------------------
        audio_channel : out std_logic_vector(2 downto 0);
        audio_de      : out std_logic;
        audio_sample  : out std_logic_vector(23 downto 0);
        
        -----------------------------------
        -- VGA data to be converted to HDMI
        -----------------------------------
        out_blank     : in  std_logic;
        out_hsync     : in  std_logic;
        out_vsync     : in  std_logic;
        out_red       : in  std_logic_vector(7 downto 0);
        out_green     : in  std_logic_vector(7 downto 0);
        out_blue      : in  std_logic_vector(7 downto 0);
        -----------------------------------
        -- For symbol dump or retransmit
        -----------------------------------
        symbol_sync  : out std_logic; -- indicates a fixed reference point in the frame.
        symbol_ch0   : out std_logic_vector(9 downto 0);
        symbol_ch1   : out std_logic_vector(9 downto 0);
        symbol_ch2   : out std_logic_vector(9 downto 0)
    );
    end component;
    signal clk200  : std_logic;
    signal clk10  : std_logic;
    signal clk125  : std_logic;
    signal clk625  : std_logic;
    signal pclk  : std_logic;
    signal VPolarity  : std_logic;
    signal symbol_sync  : std_logic;
    signal symbol_ch0   : std_logic_vector(9 downto 0);
    signal symbol_ch1   : std_logic_vector(9 downto 0);
    signal symbol_ch2   : std_logic_vector(9 downto 0);
    signal debug_pmod    :   std_logic_vector(7 downto 0) :=(others => '0');    
    signal sel: std_logic;
    
    component vga is
    Port ( pixelClock : in  STD_LOGIC;
           Red        : out STD_LOGIC_VECTOR (7 downto 0);
           Green      : out STD_LOGIC_VECTOR (7 downto 0);
           Blue       : out STD_LOGIC_VECTOR (7 downto 0);
           hSync      : out STD_LOGIC;
           vSync      : out STD_LOGIC;
           blank      : out STD_LOGIC);
    end component;
    
    component pixel_pipe is
        Port ( clk : in STD_LOGIC;  clk10 : in STD_LOGIC; 
        sw : in std_logic_vector(3 downto 0); -- switches
        trig    : out STD_LOGIC;  f_frm   : out STD_LOGIC; 
        mode    : in STD_LOGIC;  rdy   : in STD_LOGIC;  
            ------------------
            in_blank  : in std_logic;
            in_hsync  : in std_logic;
            in_vsync  : in std_logic;
            vsync  : in std_logic;
            in_red    : in std_logic_vector(7 downto 0);
            in_green  : in std_logic_vector(7 downto 0);
            in_blue   : in std_logic_vector(7 downto 0);

            -------------------
            out_blank : out std_logic;
            out_hsync : out std_logic;
            out_vsync : out std_logic;
            out_red   : out std_logic_vector(7 downto 0);
            out_green : out std_logic_vector(7 downto 0);
            out_blue  : out std_logic_vector(7 downto 0)
            
    );
    end component;

    signal not_C1in1 : std_logic;
    signal pixel_clk : std_logic;
    signal sel_buf  : std_logic;
    signal in_blank  : std_logic;
    signal in_blank_reg  : std_logic;
    signal in_hsync  : std_logic;
    signal in_vsync  : std_logic;
    signal in_vsync_reg  : std_logic;
    signal in_red    : std_logic_vector(7 downto 0);
    signal in_green  : std_logic_vector(7 downto 0);
    signal in_blue   : std_logic_vector(7 downto 0);
    signal local_blank  : std_logic;
    signal local_hsync  : std_logic;
    signal local_vsync  : std_logic;
    signal local_red    : std_logic_vector(7 downto 0);
    signal local_green  : std_logic_vector(7 downto 0);
    signal local_blue   : std_logic_vector(7 downto 0);
    signal blank  : std_logic;
    signal hsync  : std_logic;
    signal vsync  : std_logic;
    signal vsync_Pos  : std_logic;
    signal vsync_reg  : std_logic;
    signal vsync_dur  : std_logic_vector(7 downto 0);
    signal red    : std_logic_vector(7 downto 0);
    signal green  : std_logic_vector(7 downto 0);
    signal blue   : std_logic_vector(7 downto 0);
    signal is_interlaced   : std_logic;
    signal is_second_field : std_logic;
    signal out_blank : std_logic;
    signal out_hsync : std_logic;
    signal out_vsync : std_logic;
    signal out_red   : std_logic_vector(7 downto 0);
    signal out_green : std_logic_vector(7 downto 0);
    signal out_blue  : std_logic_vector(7 downto 0);
    signal rdy_buf : std_logic;
    signal mode_buf : std_logic;
    signal audio_channel : std_logic_vector(2 downto 0);
    signal audio_de      : std_logic;
    signal audio_sample  : std_logic_vector(23 downto 0);
    signal trig : std_logic;
    signal f_frm : std_logic;
    signal debug : std_logic_vector(7 downto 0);
begin
    debug_pmod <= debug;    
    led (7) <= vsync;
    led (6) <= hsync;
    -- for test GPIO input pins
    --led (5)   <= C1_in(1);    led (4)   <= C1_in(0);     led (3)   <= C2_in(1);    led (2)   <= C2_in(0);
    
    
    led (5) <= VPolarity;
    -- for SD debugging
    -- verify clock selector
    --led (4)   <= sel;    
    led(4) <= sel; --selector
    
        
    -- 4-line protocl pins
    led(3) <= C1_in(1); --mode;
    led(2) <= C1_in(0); --rdy;    
    led (1)   <= f_frm;
    led (0)   <= trig;

    C1_out(0)  <= trig; 
    C1_out(1)  <= f_frm;

    
    C2_out(0)  <= trig; C2_out(1)  <= f_frm;
    
 

    
i_hdmi_io: hdmi_io port map ( 
        clk100        => clk100,
         clk200        => clk200,
         clk10 => clk10,
         clk125        => clk125,
         clk625        => clk625,
        ---------------------
        -- Control signals
        ---------------------
        clock_locked     => open,
        data_synced      => open,
        debug            => debug,
        sel => sel, 
        ---------------------
        -- HDMI input signals
        ---------------------
        hdmi_rx_cec   => hdmi_rx_cec,
        hdmi_rx_hpa   => hdmi_rx_hpa,
        hdmi_rx_scl   => hdmi_rx_scl,
        hdmi_rx_sda   => hdmi_rx_sda,
        hdmi_rx_clk_n => hdmi_rx_clk_n,
        hdmi_rx_clk_p => hdmi_rx_clk_p,
        hdmi_rx_p     => hdmi_rx_p,
        hdmi_rx_n     => hdmi_rx_n,

        ----------------------
        -- HDMI output signals
        ----------------------
     --   hdmi_tx_cec   => hdmi_tx_cec,
        hdmi_tx_clk_n => hdmi_tx_clk_n,
        hdmi_tx_clk_p => hdmi_tx_clk_p,
--        hdmi_tx_hpd   => hdmi_tx_hpd,
--        hdmi_tx_rscl  => hdmi_tx_rscl,
--        hdmi_tx_rsda  => hdmi_tx_rsda,
        hdmi_tx_p     => hdmi_tx_p,
        hdmi_tx_n     => hdmi_tx_n,     

        
        pixel_clk => pixel_clk,
        -------------------------------
        -- VGA data recovered from HDMI
        -------------------------------
        in_blank        => in_blank,
        in_hsync        => in_hsync,
        in_vsync        => in_vsync,
        in_red          => in_red,
        in_green        => in_green,
        in_blue         => in_blue,
        is_interlaced   => is_interlaced,
        is_second_field => is_second_field,

        -----------------------------------
        -- For symbol dump or retransmit
        -----------------------------------
        audio_channel => audio_channel,
        audio_de      => audio_de,
        audio_sample  => audio_sample,
        
        -----------------------------------
        -- VGA data to be converted to HDMI
        -----------------------------------
        out_blank => out_blank,
        out_hsync => out_hsync,
        out_vsync => out_vsync,
        out_red   => out_red,
        out_green => out_green,
        out_blue  => out_blue,
        
        symbol_sync  => symbol_sync, 
        symbol_ch0   => symbol_ch0,
        symbol_ch1   => symbol_ch1,
        symbol_ch2   => symbol_ch2
    );
 --------------------------------------------
  --   a 200MHz clock for the IDELAY reference
 --------------------------------------------
ref_clk_pll : ref_clk
    port map (
        clk_in  => clk100,    
        clk_out => clk200,
        clk125 => clk125, clk625 => clk625,
        clk10 => clk10
    );

 --------------------------------------------
  --   Cretae the output VGA pattern  with on-board clock
 --------------------------------------------
i_DVID_input: vga port map(
     pixelClock => pixel_clk,
           Red       =>local_red,
           Green     =>local_green,
           Blue     =>local_blue,
           hSync    =>local_hsync,
           vSync     =>local_vsync,
           blank     =>local_blank
);

 --------------------------------------------
  --   Pixel-wise alteration
 --------------------------------------------
blank<= in_blank when sel_buf='1' else local_blank;
vsync<= in_vsync when sel_buf='1' else local_vsync;
hsync<= in_hsync when sel_buf='1' else local_hsync;
red<= in_red when sel_buf='1' else local_red;
green<= in_green when sel_buf='1' else local_green;
blue<= in_blue when sel_buf='1' else local_blue;
vsync_Pos <= vsync when VPolarity='1' else (not vsync when blank = '1' else '0');
-- Tricky part is in_vysnc can be uncertain during visible time when V polarity is neg
process(pixel_clk)
begin
    if rising_edge(pixel_clk) then
        rdy_buf    <= C1_in(0);
        mode_buf   <= C1_in(1); 
        sel_buf<=sel;
        in_vsync_reg  <= in_vsync; 
        in_blank_reg  <= in_blank;
        -- decide VSYNC polarity
        if (sel_buf = '0') then
            VPolarity <= '1';
        elsif (in_blank ='1' and in_blank_reg='0') then --when just enter blanking
            VPolarity <= not in_vsync;
        else VPolarity <=VPolarity;    
        end if;
    end if;
end process;

i_processing: pixel_pipe Port map ( 
        clk => pixel_clk, clk10 => clk10,
        sw =>newSW,
        trig =>trig, f_frm=> f_frm, 
        mode=>C1_in(1), rdy=> rdy_buf ,
          
        --
        in_blank        => blank,
        in_hsync        => hsync,
        in_vsync        => vsync_Pos, -- for postion tracking and camera control
        vsync => vsync,
        in_red          => red,
        in_green        => green,
        in_blue         => blue,    
        out_blank => out_blank,
        out_hsync => out_hsync,
        out_vsync => out_vsync,
        out_red   => out_red,
        out_green => out_green,
        out_blue  => out_blue
    );
--Vs  <= out_vsync; 
    -- Swap to this if you want to capture the HDMI symbols
    -- and send them up the RS232 port
    --rs232_tx <= '1';   
    
end Behavioral;
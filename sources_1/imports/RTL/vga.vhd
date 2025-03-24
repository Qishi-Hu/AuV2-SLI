--From Numato Official Repo
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity vga is
   generic (
      hRez       : natural := 1280;	
      hStartSync : natural := 1390;
      hEndSync   : natural := 1430;
      hMaxCount  : natural := 1650;
      hsyncActive : std_logic := '1';
		
      vRez       : natural := 720;
      vStartSync : natural := 725;
      vEndSync   : natural := 730;
      vMaxCount  : natural := 750;
      vsyncActive : std_logic := '1'
   );

    Port ( pixelClock : in  STD_LOGIC;
           Red        : out STD_LOGIC_VECTOR (7 downto 0);
           Green      : out STD_LOGIC_VECTOR (7 downto 0);
           Blue       : out STD_LOGIC_VECTOR (7 downto 0);
           hSync      : out STD_LOGIC;
           vSync      : out STD_LOGIC;
           blank      : out STD_LOGIC);
end vga;

architecture Behavioral of vga is
   type reg is record
      hCounter : std_logic_vector(11 downto 0);
      vCounter : std_logic_vector(11 downto 0);

      red      : std_logic_vector(7 downto 0);
      green    : std_logic_vector(7 downto 0);
      blue     : std_logic_vector(7 downto 0);

      hSync    : std_logic;
      vSync    : std_logic;
      blank    : std_logic;		
   end record;

   signal r : reg := ((others=>'0'), (others=>'0'),
                      (others=>'0'), (others=>'0'), (others=>'0'), 
                      '0', '0', '0');
   signal n : reg;   
begin
   -- Assign the outputs
   hSync <= r.hSync;
   vSync <= r.vSync;
   Red   <= r.red;
   Green <= r.green;
   Blue  <= r.blue;
   blank <= r.blank;
   
   process(r,n)
   begin
      n <= r;
      n.hSync <= not hSyncActive;      
      n.vSync <= not vSyncActive;      

      -- Count the lines and rows      
      if r.hCounter = hMaxCount-1 then
         n.hCounter <= (others => '0');
         if r.vCounter = vMaxCount-1 then
            n.vCounter <= (others => '0');
         else
            n.vCounter <= r.vCounter+1;
         end if;
      else
         n.hCounter <= r.hCounter+1;
      end if;

      if r.hCounter  < hRez and r.vCounter  < vRez then
         n.red   <= (others => '0');
         n.green <= (others => '0');
         n.blue  <= (others => '0');
         n.blank <= '0';
      else
         n.red   <= (others => '0');
         n.green <= (others => '0');
         n.blue  <= (others => '0');
         n.blank <= '1';
      end if;
      
      -- Are we in the hSync pulse?
      if r.hCounter >= hStartSync and r.hCounter < hEndSync then
         n.hSync <= hSyncActive;
      end if;

      -- Are we in the vSync pulse?
      if r.vCounter >= vStartSync and r.vCounter < vEndSync then
         n.vSync <= vSyncActive; 
      end if;
   end process;

   process(pixelClock,n)
   begin
      if rising_edge(pixelClock)
      then
         r <= n;
      end if;
   end process;
end Behavioral;

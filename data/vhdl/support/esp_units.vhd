-- =============================================================
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.customTypes.all;
-- ==============================================================

-----------------------------------------------------------------------
-- systolic_tile_wrapper, version 0.0
-----------------------------------------------------------------------
entity systolic_unit is generic( INPUTS: integer; SIZE : integer; DATA_SIZE_IN : Integer; DATA_SIZE_OUT : Integer);
port(
    clk, rst : in std_logic;
    start: in std_logic_vector(31 downto 0);
    tile_op_mode: in std_logic_vector(31 downto 0); 
    tile_fpsa_config: in std_logic_vector(31 downto 0);
    dataInArray : in data_array (1 downto 0)(63 downto 0); 
    dataOutArray : out data_array (0 downto 0)(63 downto 0);      
    pValidArray : in std_logic_vector(4 downto 0);
    nReadyArray : in std_logic_vector(0 downto 0);
    validArray : out std_logic_vector(0 downto 0);
    readyArray : out std_logic_vector(4 downto 0)
    );
end entity;


architecture arch of systolic_unit is

  component systolic_tile_wrapper is
  port (
    clk : in std_logic;
    rst : in std_logic;
    in_north : in std_logic_vector(63 downto 0);
    in_west : in std_logic_vector(63 downto 0);
    start : in std_logic;
    tile_op_mode : in std_logic_vector(2 downto 0);
    tile_config : in std_logic_vector(18 downto 0);
    in_valid : in std_logic;
    in_ready : out std_logic;
    out_ready : in std_logic;
    out_valid : out std_logic;
    out_data : out std_logic_vector(63 downto 0));
  end component;

  signal tile_config : std_logic_vector(18 downto 0);
  signal tile_op_mode_inter : std_logic_vector(2 downto 0);
  signal joinValid: std_logic;
  signal sysIsReady: std_logic;
  signal systolic_rst : std_logic;

begin 

   systolic_rst <= not rst;
    sys_unit: systolic_tile_wrapper
        port map (
            clk => clk,
            rst => systolic_rst,
            in_west => dataInArray(0),
            in_north => dataInArray(1),
            start => start(0),
            tile_op_mode => tile_op_mode_inter,
            tile_config => tile_config,
            in_valid => joinValid,
            in_ready => sysIsReady,
            out_ready => nReadyArray(0),
            out_valid => validArray(0),
            out_data => dataOutArray(0)
            );

    tile_config <= tile_fpsa_config(18 downto 0);
    tile_op_mode_inter <= tile_op_mode(2 downto 0);

    
    --readyArray(0) <= sysIsReady;
    --readyArray(1) <= sysIsReady;
    
    j : entity work.join(arch) generic map(5)
        port map(   (pValidArray(4), pValidArray(3), pValidArray(2), pValidArray(1), pValidArray(0)),
                     sysIsReady,
                        joinValid,
                        readyArray);


end architecture;

-- =============================================================
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.customTypes.all;
-- ==============================================================

-----------------------------------------------------------------------
-- systolic_tile_ctrl, version 0.0
-----------------------------------------------------------------------

entity systolic_ctrl_unit is generic( INPUTS: integer; SIZE : integer; DATA_SIZE_IN : Integer; DATA_SIZE_OUT : Integer);
port(
    clk, rst : in std_logic;
    condition : in data_array (0 downto 0)(31 downto 0); 
    dataInArray : in data_array (0 downto 0)(63 downto 0); 
    dataOutArray : out data_array (0 downto 0)(63 downto 0);      
    ctrl_out : out std_logic_vector(31 downto 0);      
    pValidArray : in std_logic_vector(1 downto 0);
    nReadyArray : in std_logic_vector(1 downto 0);
    validArray : out std_logic_vector(1 downto 0);
    readyArray : out std_logic_vector(1 downto 0)
    );
end entity;


architecture arch of systolic_ctrl_unit is

signal cnt :  std_logic_vector (5 downto 0);

begin 

  start_signal_sys : process(clk, rst, pValidArray, nReadyArray)
  begin
      if (clk'event and clk =  '1') then
          if (rst = '1') then
              cnt <= "000000";
              ctrl_out <= std_logic_vector(to_unsigned(0, ctrl_out'length));
              validArray(1) <= '0';                 
          elsif ((unsigned (cnt)) > (unsigned (condition(0)) - 1) and pValidArray(0) = '1') then  -- check if the condition is still valid
              cnt <= "000000";
              ctrl_out <= std_logic_vector(to_unsigned(1, ctrl_out'length));
              validArray(1) <= '1';                 
          elsif (pValidArray(1) = '1' and nReadyArray(0) = '1') then
            cnt <= std_logic_vector (unsigned (cnt) + 1); --cnt <= cnt + 1;
            validArray(1) <= '1';                   
          end if;
      end if;
  end process;

  -- propagate the information from the data in array to data out array
  dataOutArray(0) <= dataInArray(0);
  validArray(0) <= pValidArray(1);
  readyArray(1) <= nReadyArray(0);

  -- connect condition and ctrl out
  readyArray(0) <= nReadyArray(1);


end architecture;



library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.customTypes.all;

entity dyn_decoder is generic( INPUTS: integer; SIZE : integer; DATA_SIZE_IN : Integer; DATA_SIZE_OUT : Integer; COND_SIZE : Integer);
port(   clk, rst    : in std_logic; -- the eager implementation uses registers
        dataInArray : in data_array (0 downto 0)(DATA_SIZE_IN-1 downto 0);
        pValidArray : in std_logic_vector(SIZE - 1 downto 0);
        readyArray : out std_logic_vector(1 downto 0);
        dataOutArray : out data_array (SIZE-1 downto 0)(DATA_SIZE_OUT-1 downto 0); 
        nReadyArray : in std_logic_vector(SIZE-1 downto 0);
        validArray  : out std_logic_vector(SIZE-1 downto 0);
        condition     : in  data_array(0 downto 0)(COND_SIZE - 1 downto 0)
        );
        
end dyn_decoder;


------------------------------------------------------------------------
-- generic eager implementation
------------------------------------------------------------------------
architecture arch of dyn_decoder is
    signal allReady : std_logic;
    signal joinValid: std_logic;
begin
    
    
    process(dataInArray, pValidArray, nReadyArray, condition)
    begin
        for I in SIZE - 1 downto 0 loop
            if (to_integer(unsigned(condition(0))) = I and pValidArray(0) = '1' and pValidArray(1) = '1' and nReadyArray(I) = '1') then
                validArray(I) <= '1';
                --dataOutArray(I) <= std_logic_vector(to_unsigned(dataInArray(0),DATA_SIZE_OUT'length)); 
                dataOutArray(I) <= dataInArray(0); 
	    else
                validArray(I) <= '0';
            end if;
        end loop;
    end process;   

    --ready_out: entity work.andN(vanilla) generic map (SIZE)
    --        port map (nReadyArray, allReady);

    j : entity work.join(arch) generic map(2)
        port map(   (pValidArray(1), pValidArray(0)),
                     nReadyArray(0),
                        joinValid,
                        readyArray);

    --readyArray(0) <= allReady; 

end arch;


------------------------------------------------------------------------
-- alternated decoder DecoderAlt
------------------------------------------------------------------------


library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.customTypes.all;

entity DecoderAlt is generic( INPUTS: integer; SIZE : integer; DATA_SIZE_IN : Integer; DATA_SIZE_OUT : Integer);
port(   clk, rst    : in std_logic; -- the eager implementation uses registers
        dataInArray : in data_array (0 downto 0)(DATA_SIZE_IN-1 downto 0);
        pValidArray : in std_logic_vector(0 downto 0);
        readyArray : out std_logic_vector(0 downto 0);
        dataOutArray : out data_array (SIZE-1 downto 0)(DATA_SIZE_OUT-1 downto 0); 
        nReadyArray : in std_logic_vector(SIZE-1 downto 0);
        validArray  : out std_logic_vector(SIZE-1 downto 0)
        );
        
end DecoderAlt;


------------------------------------------------------------------------
-- generic eager implementation
------------------------------------------------------------------------
architecture arch of DecoderAlt is
    signal decoder_dir :  std_logic;
    signal condition   :  std_logic_vector(0 downto 0);
    signal condition_valid   :  std_logic;
    signal condition_ready   :  std_logic;
begin
    
    decoder0: entity work.dyn_decoder(arch) generic map (INPUTS, SIZE, DATA_SIZE_IN ,DATA_SIZE_OUT ,1 )
    port map (
        clk => clk,
        rst => rst,
        dataInArray(0) => dataInArray(0),
        condition(0) => condition,
        pValidArray(0) => pValidArray(0),
        pValidArray(1) => condition_valid,
        readyArray(0) => readyArray(0),
        readyArray(1) => condition_ready,
        nReadyArray(0) => nReadyArray(0),
        nReadyArray(1) => nReadyArray(1),
        validArray(0) => validArray(0),
        validArray(1) => validArray(1),
        dataOutArray(0) => dataOutArray(0),
        dataOutArray(1) => dataOutArray(1)
    );


    control_decoder : process(clk, pValidArray(0))
    begin
        if (clk'event and clk =  '1') then
            if (rst = '1') then
                    decoder_dir <= '0';
            elsif (pValidArray(0) = '1' and nReadyArray(1) = '1' and decoder_dir = '0') then
                        condition <= std_logic_vector(to_unsigned(0, condition'length)); --0';
                        condition_valid <= '1';
                        decoder_dir <= '1';
            elsif (pValidArray(0) = '1' and nReadyArray(0) = '1' and decoder_dir = '1') then
                        condition <= std_logic_vector(to_unsigned(1, condition'length)); --'1';
                        condition_valid <= '1';
                        decoder_dir <= '0';
            else
            condition_valid <= '0';                    
            end if;
        end if;
    end process;

end arch;



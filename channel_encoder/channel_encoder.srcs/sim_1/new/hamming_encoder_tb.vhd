-- Testbench created online at:
--   https://www.doulos.com/knowhow/perl/vhdl-testbench-creation-using-perl/
-- Copyright Doulos Ltd

library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

entity hamming_encoder_tb is
end;

architecture bench of hamming_encoder_tb is

  component hamming_encoder
    port (
      valid_in : in std_logic;
      data_in  : in  STD_LOGIC_VECTOR(3 downto 0);
      data_out : out STD_LOGIC_VECTOR(6 downto 0);
      ready_out : out std_logic
    );
  end component;

  signal data_in: STD_LOGIC_VECTOR(3 downto 0);
  signal data_out: STD_LOGIC_VECTOR(6 downto 0) ;
    signal valid_in : STD_LOGIC ;
      signal ready_out: STD_LOGIC ;

begin

  uut: hamming_encoder port map ( data_in  => data_in,
                                  data_out => data_out,
                                   valid_in => valid_in,
                                   ready_out => ready_out);

  stimulus: process
  begin
  valid_in <= '0';
  ready_out <= '0';
  wait for 1ns;
  
  valid_in <='1';
  wait for 1ns;
  data_in <= "1010";  
  wait for 1 ns; 
  ready_out <= '1';
  wait for 1ns;
  
  data_in <= "0001";  
  wait for 1 ns; 
  
  data_in <= "1100";  
  wait for 1 ns; 
  
  data_in <= "0000";  
  wait for 1 ns; 
  
    -- Put initialisation code here


    -- Put test bench stimulus code here

    wait;
  end process;


end;
  
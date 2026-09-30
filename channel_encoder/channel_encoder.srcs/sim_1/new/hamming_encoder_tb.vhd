library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity hamming_encoder_tb is
end entity;

architecture bench of hamming_encoder_tb is

  signal clk       : STD_LOGIC := '0';
  signal valid_in  : STD_LOGIC := '0';
  signal data_in   : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
  signal data_out  : STD_LOGIC_VECTOR(11 downto 0);
  signal ready_out : STD_LOGIC;

begin

  uut : entity work.hamming_encoder
    port map (
      clk       => clk,
      valid_in  => valid_in,
      data_in   => data_in,
      data_out  => data_out,
      ready_out => ready_out
    );

  -- PYNQ-Z2 system clock: 125 MHz (8 ns period)
  clk <= not clk after 4 ns;

  -- Everything below changes or is checked on the FALLING edge.
  -- The DUT samples on the RISING edge in between.
  stimulus : process

    procedure tick(n : positive := 1) is
    begin
      for i in 1 to n loop
        wait until falling_edge(clk);
      end loop;
    end procedure;

  begin
    tick(3);  -- idle a few clocks

    ----------------------------------------------------------------
    -- Test 1: 0x6D -> expected codeword 0110_0110_0111
    ----------------------------------------------------------------
    data_in  <= "01101101";
    valid_in <= '1';
    tick(2);      -- rising edge sampled the data; output now registered
    assert ready_out = '1'            report "Test 1: ready_out not high"  severity error;
    assert data_out = "011001100111"  report "Test 1: wrong codeword"      severity error;
    valid_in <= '0';                  -- clear after the one-clock ready pulse
    data_in  <= (others => '0');
    tick;      -- rising edge sampled valid_in = 0; output cleared
    assert ready_out = '0'            report "Test 1: ready_out did not drop" severity error;
    assert data_out = "000000000000"  report "Test 1: data_out not cleared"   severity error;

    tick(2);

    ----------------------------------------------------------------
    -- Test 2: 0xA1 -> expected codeword 1010_0000_1101
    ----------------------------------------------------------------
    data_in  <= "10100001";
    valid_in <= '1';
    tick;
    assert ready_out = '1'            report "Test 2: ready_out not high"  severity error;
    assert data_out = "101000001101"  report "Test 2: wrong codeword"      severity error;
    valid_in <= '0';
    data_in  <= (others => '0');
    tick;
    assert ready_out = '0'            report "Test 2: ready_out did not drop" severity error;
    assert data_out = "000000000000"  report "Test 2: data_out not cleared"   severity error;

    tick(2);
    report "hamming_encoder_tb finished" severity note;
    wait;
  end process;

end architecture;

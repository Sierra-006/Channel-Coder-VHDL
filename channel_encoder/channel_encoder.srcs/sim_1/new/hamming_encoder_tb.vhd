-- Self-checking testbench for the clocked Hamming(12,8) encoder.
-- Exhaustively checks all 256 inputs against an independent reference
-- (XOR of the positions of the set data bits gives the parity bits).

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity hamming_encoder_tb is
end entity;

architecture bench of hamming_encoder_tb is

  constant CLK_PERIOD : time := 10 ns;

  signal clk       : STD_LOGIC := '0';
  signal valid_in  : STD_LOGIC := '0';
  signal data_in   : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
  signal data_out  : STD_LOGIC_VECTOR(11 downto 0);
  signal ready_out : STD_LOGIC;
  signal done      : boolean := false;

  -- Reference model: independent of the DUT's implementation
  function ref_encode(d : STD_LOGIC_VECTOR(7 downto 0)) return STD_LOGIC_VECTOR is
    type int_arr is array (0 to 7) of integer;
    constant POS : int_arr := (3, 5, 6, 7, 9, 10, 11, 12);
    variable f : STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
    variable s : unsigned(3 downto 0) := (others => '0');
  begin
    for i in 0 to 7 loop
      f(POS(i) - 1) := d(i);
      if d(i) = '1' then
        s := s xor to_unsigned(POS(i), 4);
      end if;
    end loop;
    f(0) := s(0);  -- position 1
    f(1) := s(1);  -- position 2
    f(3) := s(2);  -- position 4
    f(7) := s(3);  -- position 8
    return f;
  end function;

begin

  uut : entity work.hamming_encoder
    port map (
      clk       => clk,
      valid_in  => valid_in,
      data_in   => data_in,
      data_out  => data_out,
      ready_out => ready_out
    );

  clk_gen : process
  begin
    while not done loop
      clk <= '0'; wait for CLK_PERIOD / 2;
      clk <= '1'; wait for CLK_PERIOD / 2;
    end loop;
    wait;
  end process;

  stimulus : process
    variable errors : integer := 0;
    variable held   : STD_LOGIC_VECTOR(11 downto 0);
  begin
    wait for 2 * CLK_PERIOD;

    -- Every input value, valid_in high
    for v in 0 to 255 loop
      data_in  <= std_logic_vector(to_unsigned(v, 8));
      valid_in <= '1';
      wait until rising_edge(clk);
      wait for 1 ns;
      if ready_out /= '1' then
        report "data=" & integer'image(v) & ": ready_out not high" severity error;
        errors := errors + 1;
      end if;
      if data_out /= ref_encode(data_in) then
        report "data=" & integer'image(v) & ": codeword mismatch" severity error;
        errors := errors + 1;
      end if;
    end loop;

    -- valid_in low: ready_out drops, data_out holds, data_in ignored
    held := data_out;
    valid_in <= '0';
    data_in  <= "10101010";
    wait until rising_edge(clk);
    wait for 1 ns;
    if ready_out /= '0' then
      report "ready_out did not drop when valid_in low" severity error;
      errors := errors + 1;
    end if;
    if data_out /= held then
      report "data_out changed while valid_in low" severity error;
      errors := errors + 1;
    end if;

    if errors = 0 then
      report "hamming_encoder_tb: ALL TESTS PASSED (256 vectors)" severity note;
    else
      report "hamming_encoder_tb: " & integer'image(errors) & " ERRORS" severity failure;
    end if;
    done <= true;
    wait;
  end process;

end architecture;

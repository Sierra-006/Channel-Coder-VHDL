----------------------------------------------------------------------------------
-- Create Date: 15.12.2024 18:06:06
-- Module Name: hamming_encoder - Behavioral
-- Description: Clocked Hamming(12,8) encoder. 8 data bits in, 12-bit codeword out.
--              Codeword index i holds position i+1. Parity bits sit at positions
--              1, 2, 4, 8 (indices 0, 1, 3, 7); data bits at positions
--              3, 5, 6, 7, 9, 10, 11, 12 (indices 2, 4, 5, 6, 8, 9, 10, 11).
--              Output is registered: data_out/ready_out update one clock after
--              valid_in is sampled high.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity hamming_encoder is
  port (
    clk       : in  STD_LOGIC;                      -- Clock
    valid_in  : in  STD_LOGIC;                      -- Indicates data_in is valid
    data_in   : in  STD_LOGIC_VECTOR(7 downto 0);   -- Input: 8 data bits
    data_out  : out STD_LOGIC_VECTOR(11 downto 0);  -- Output: 12-bit codeword
    ready_out : out STD_LOGIC                       -- Indicates data_out is valid
  );
end entity;

architecture Behavioral of hamming_encoder is

  signal output_data : STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
  signal ready       : STD_LOGIC := '0';

begin

  process(clk)
    variable frame : STD_LOGIC_VECTOR(11 downto 0);
    variable p     : STD_LOGIC;
  begin
    if rising_edge(clk) then
      if valid_in = '1' then
        -- Place data bits (parity slots start at 0)
        frame := (others => '0');
        frame(2)  := data_in(0);
        frame(4)  := data_in(1);
        frame(5)  := data_in(2);
        frame(6)  := data_in(3);
        frame(8)  := data_in(4);
        frame(9)  := data_in(5);
        frame(10) := data_in(6);
        frame(11) := data_in(7);

        -- Parity k (position 2**k) covers every position with bit k set
        for k in 0 to 3 loop
          p := '0';
          for i in 0 to 11 loop
            if (((i + 1) / (2 ** k)) mod 2) = 1 then
              p := p xor frame(i);
            end if;
          end loop;
          frame((2 ** k) - 1) := p;
        end loop;

        output_data <= frame;
        ready       <= '1';
      else
        ready <= '0';
      end if;
    end if;
  end process;

  data_out  <= output_data;
  ready_out <= ready;

end architecture;

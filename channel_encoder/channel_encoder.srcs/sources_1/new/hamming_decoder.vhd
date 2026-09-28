----------------------------------------------------------------------------------
-- Module Name: hamming_decoder - Behavioral
-- Description: Clocked Hamming(12,8) decoder matching hamming_encoder.
--              Codeword index i holds position i+1. Parity at positions
--              1, 2, 4, 8; data at 3, 5, 6, 7, 9, 10, 11, 12.
--              Syndrome = XOR of positions of all '1' bits (computed per bit as
--              s(k) = parity of bits whose position has bit k set).
--                syndrome = 0      : no error
--                syndrome = 1..12  : single-bit error at that position, corrected
--                syndrome = 13..15 : not a valid single-bit error, uncorrectable
--              Note: some double-bit errors alias to syndrome 1..12 and are
--              miscorrected. Detecting all doubles needs an overall parity bit.
--              Outputs are registered, one clock after valid_in is sampled high.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity hamming_decoder is
  port (
    clk                 : in  STD_LOGIC;                      -- Clock
    valid_in            : in  STD_LOGIC;                      -- Indicates data_in is valid
    data_in             : in  STD_LOGIC_VECTOR(11 downto 0);  -- Input: 12-bit codeword
    data_out            : out STD_LOGIC_VECTOR(7 downto 0);   -- Output: 8 data bits
    error_detect        : out STD_LOGIC;                      -- Syndrome nonzero
    error_corrected     : out STD_LOGIC;                      -- Single-bit error corrected
    uncorrectable_error : out STD_LOGIC;                      -- Syndrome out of range
    ready_out           : out STD_LOGIC                       -- Indicates outputs are valid
  );
end entity;

architecture Behavioral of hamming_decoder is

  signal data_reg      : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
  signal detect_reg    : STD_LOGIC := '0';
  signal corrected_reg : STD_LOGIC := '0';
  signal uncorr_reg    : STD_LOGIC := '0';
  signal ready_reg     : STD_LOGIC := '0';

begin

  process(clk)
    variable frame    : STD_LOGIC_VECTOR(11 downto 0);
    variable syndrome : STD_LOGIC_VECTOR(3 downto 0);
    variable err_pos  : integer range 0 to 15;
  begin
    if rising_edge(clk) then
      if valid_in = '1' then
        frame := data_in;

        -- Syndrome bit k = XOR of every bit whose position has bit k set
        for k in 0 to 3 loop
          syndrome(k) := '0';
          for i in 0 to 11 loop
            if (((i + 1) / (2 ** k)) mod 2) = 1 then
              syndrome(k) := syndrome(k) xor frame(i);
            end if;
          end loop;
        end loop;

        err_pos := to_integer(unsigned(syndrome));

        detect_reg    <= '0';
        corrected_reg <= '0';
        uncorr_reg    <= '0';

        if err_pos /= 0 then
          detect_reg <= '1';
          if err_pos <= 12 then
            frame(err_pos - 1) := not frame(err_pos - 1);
            corrected_reg <= '1';
          else
            uncorr_reg <= '1';
          end if;
        end if;

        -- Extract data from positions 3, 5, 6, 7, 9, 10, 11, 12
        data_reg <= frame(11) & frame(10) & frame(9) & frame(8) &
                    frame(6)  & frame(5)  & frame(4) & frame(2);
        ready_reg <= '1';
      else
        ready_reg <= '0';
      end if;
    end if;
  end process;

  data_out            <= data_reg;
  error_detect        <= detect_reg;
  error_corrected     <= corrected_reg;
  uncorrectable_error <= uncorr_reg;
  ready_out           <= ready_reg;

end architecture;

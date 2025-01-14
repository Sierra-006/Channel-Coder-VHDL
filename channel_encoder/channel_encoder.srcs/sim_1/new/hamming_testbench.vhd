----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 15.12.2024 18:16:49
-- Design Name: 
-- Module Name: hamming_testbench - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity hamming_testbench is
end hamming_testbench;

architecture Behavioral of hamming_testbench is
    -- Signals for testing the encoder
    signal data_in : STD_LOGIC_VECTOR(3 downto 0);
    signal codeword_out : STD_LOGIC_VECTOR(6 downto 0);

    -- Signals for testing the decoder
    signal codeword_in : STD_LOGIC_VECTOR(6 downto 0);
    signal data_out : STD_LOGIC_VECTOR(3 downto 0);
    signal error_pos : std_logic;

    -- Internal signals for error injection
    signal corrupted_codeword : STD_LOGIC_VECTOR(6 downto 0);

    -- Time constant
    constant CLK_PERIOD : time := 8 ns;

begin
    -- Instantiate the encoder
    uut_encoder: entity work.hamming_encoder
        port map(
            data_in => data_in,
            data_out => codeword_out
        );

    -- Instantiate the decoder
    uut_decoder: entity work.hamming_decoder
        port map(
            data_in => codeword_in,
            data_out => data_out,
            error_detect => error_pos
        );

    -- Test process
    test_process: process
    begin
        -- Test case 1: Encode and decode without error
        data_in <= "1010"; -- Input data bits
        wait for CLK_PERIOD;

        -- Verify the encoded output
        assert codeword_out = "1011010"
        report "Test Case 1 Failed: Encoder output mismatch." severity error;

        -- Pass the encoded data to the decoder
        codeword_in <= codeword_out;
        wait for CLK_PERIOD;

        -- Verify the decoded output
        assert data_out = "1010"
        report "Test Case 1 Failed: Decoder output mismatch." severity error;

        -- Verify no error detected
        assert error_pos = 0
        report "Test Case 1 Failed: Error position mismatch." severity error;

        -- Test case 2: Inject a single-bit error and decode
        corrupted_codeword <= codeword_out;
        corrupted_codeword(4) <= not corrupted_codeword(4); -- Flip bit at position 4
        codeword_in <= corrupted_codeword;
        wait for CLK_PERIOD;

        -- Verify the decoded output matches the original input
        assert data_out = "1010"
        report "Test Case 2 Failed: Decoder output mismatch after correction." severity error;

        -- Verify error position
        assert error_pos = 4
        report "Test Case 2 Failed: Error position mismatch after correction." severity error;

        -- Test case 3: Another single-bit error
        corrupted_codeword <= codeword_out;
        corrupted_codeword(1) <= not corrupted_codeword(1); -- Flip bit at position 1
        codeword_in <= corrupted_codeword;
        wait for CLK_PERIOD;

        -- Verify the decoded output matches the original input
        assert data_out = "1010"
        report "Test Case 3 Failed: Decoder output mismatch after correction." severity error;

        -- Verify error position
        assert error_pos = 1
        report "Test Case 3 Failed: Error position mismatch after correction." severity error;

        -- Test case 4: No error, different data input
        data_in <= "1100"; -- Input data bits
        wait for CLK_PERIOD;

        -- Verify the encoded output
        assert codeword_out = "0110110"
        report "Test Case 4 Failed: Encoder output mismatch." severity error;

        -- Pass the encoded data to the decoder
        codeword_in <= codeword_out;
        wait for CLK_PERIOD;

        -- Verify the decoded output
        assert data_out = "1100"
        report "Test Case 4 Failed: Decoder output mismatch." severity error;

        -- Verify no error detected
        assert error_pos = 0
        report "Test Case 4 Failed: Error position mismatch." severity error;

        -- End simulation
        report "All test cases passed successfully." severity note;
        wait;
    end process;
end Behavioral;
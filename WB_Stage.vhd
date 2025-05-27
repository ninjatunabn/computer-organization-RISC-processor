-- Write Back (WB) Stage
-- This stage writes results back to the register file

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity WB_Stage is
    Port (
        -- Inputs from MEM stage
        mem_data     : in  STD_LOGIC_VECTOR(31 downto 0);
        alu_result   : in  STD_LOGIC_VECTOR(31 downto 0);
        reg_dst_in   : in  STD_LOGIC_VECTOR(4 downto 0);
        -- Control signals
        mem_to_reg   : in  STD_LOGIC;
        reg_write    : in  STD_LOGIC;
        -- Outputs to ID stage (for register write back)
        reg_write_out: out STD_LOGIC;
        reg_dst_out  : out STD_LOGIC_VECTOR(4 downto 0);
        reg_data_out : out STD_LOGIC_VECTOR(31 downto 0)
    );
end WB_Stage;

architecture Behavioral of WB_Stage is
    signal write_data : STD_LOGIC_VECTOR(31 downto 0);
begin
    -- MUX for selecting write back data
    write_data <= alu_result when mem_to_reg = '0' else mem_data;
    
    -- Output assignments
    reg_write_out <= reg_write;
    reg_dst_out <= reg_dst_in;
    reg_data_out <= write_data;
    
end Behavioral;
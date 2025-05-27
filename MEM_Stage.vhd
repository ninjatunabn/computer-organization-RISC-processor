-- Memory Access (MEM) Stage
-- This stage handles memory operations (loads/stores)

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity MEM_Stage is
    Port (
        clk          : in  STD_LOGIC;
        -- Inputs from EX stage
        alu_result   : in  STD_LOGIC_VECTOR(31 downto 0);
        reg_data2    : in  STD_LOGIC_VECTOR(31 downto 0);
        reg_dst_in   : in  STD_LOGIC_VECTOR(4 downto 0);
        zero_flag    : in  STD_LOGIC;
        -- Control signals
        mem_read     : in  STD_LOGIC;
        mem_write    : in  STD_LOGIC;
        branch       : in  STD_LOGIC;
        mem_to_reg   : in  STD_LOGIC;
        reg_write    : in  STD_LOGIC;
        -- Outputs to WB stage
        mem_data     : out STD_LOGIC_VECTOR(31 downto 0);
        alu_result_out: out STD_LOGIC_VECTOR(31 downto 0);
        reg_dst_out  : out STD_LOGIC_VECTOR(4 downto 0);
        -- Control signals to WB stage
        mem_to_reg_out: out STD_LOGIC;
        reg_write_out: out STD_LOGIC;
        -- Branch control
        branch_taken : out STD_LOGIC
    );
end MEM_Stage;

architecture Behavioral of MEM_Stage is
    -- Data Memory component
    component Data_Memory is
        Port (
            clk      : in  STD_LOGIC;
            address  : in  STD_LOGIC_VECTOR(31 downto 0);
            write_data : in  STD_LOGIC_VECTOR(31 downto 0);
            mem_read : in  STD_LOGIC;
            mem_write : in  STD_LOGIC;
            read_data : out STD_LOGIC_VECTOR(31 downto 0)
        );
    end component;
    
    signal mem_data_temp : STD_LOGIC_VECTOR(31 downto 0);
    
begin
    -- Data Memory instance
    Data_Mem: Data_Memory port map (
        clk => clk,
        address => alu_result,
        write_data => reg_data2,
        mem_read => mem_read,
        mem_write => mem_write,
        read_data => mem_data_temp
    );
    
    -- Branch taken logic
    branch_taken <= branch and zero_flag;
    
    -- MEM/WB pipeline register
    process(clk)
    begin
        if rising_edge(clk) then
            mem_data <= mem_data_temp;
            alu_result_out <= alu_result;
            reg_dst_out <= reg_dst_in;
            mem_to_reg_out <= mem_to_reg;
            reg_write_out <= reg_write;
        end if;
    end process;
    
end Behavioral;

-- Data Memory (RAM)
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Data_Memory is
    Port (
        clk       : in  STD_LOGIC;
        address   : in  STD_LOGIC_VECTOR(31 downto 0);
        write_data: in  STD_LOGIC_VECTOR(31 downto 0);
        mem_read  : in  STD_LOGIC;
        mem_write : in  STD_LOGIC;
        read_data : out STD_LOGIC_VECTOR(31 downto 0)
    );
end Data_Memory;

architecture Behavioral of Data_Memory is
    type mem_type is array (0 to 255) of STD_LOGIC_VECTOR(31 downto 0);
    signal memory : mem_type := (others => X"00000000");
    
    signal word_addr : integer range 0 to 255;
    
begin
    word_addr <= to_integer(unsigned(address(9 downto 2))); -- Convert byte address to word address
    
    -- Memory read process
    process(mem_read, word_addr)
    begin
        if mem_read = '1' then
            read_data <= memory(word_addr);
        else
            read_data <= (others => '0');
        end if;
    end process;
    
    -- Memory write process
    process(clk)
    begin
        if rising_edge(clk) then
            if mem_write = '1' then
                memory(word_addr) <= write_data;
            end if;
        end if;
    end process;
    
end Behavioral;
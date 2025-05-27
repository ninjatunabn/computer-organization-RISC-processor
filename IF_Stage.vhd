-- Instruction Fetch (IF) Stage
-- This stage fetches instructions from memory

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity IF_Stage is
    Port (
        clk         : in  STD_LOGIC;
        reset       : in  STD_LOGIC;
        stall       : in  STD_LOGIC;
        branch_pc   : in  STD_LOGIC_VECTOR(31 downto 0);
        branch_taken: in  STD_LOGIC;
        pc_out      : out STD_LOGIC_VECTOR(31 downto 0);
        instr_out   : out STD_LOGIC_VECTOR(31 downto 0)
    );
end IF_Stage;

architecture Behavioral of IF_Stage is
    -- Instruction Memory component
    component Instruction_Memory is
        Port (
            address : in  STD_LOGIC_VECTOR(31 downto 0);
            instr   : out STD_LOGIC_VECTOR(31 downto 0)
        );
    end component;
    
    -- Program Counter register
    signal pc_reg    : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal next_pc   : STD_LOGIC_VECTOR(31 downto 0);
    signal pc_plus_4 : STD_LOGIC_VECTOR(31 downto 0);
    signal instruction : STD_LOGIC_VECTOR(31 downto 0);
    
begin
    -- Instruction Memory instance
    Instr_Mem: Instruction_Memory port map (
        address => pc_reg,
        instr => instruction
    );
    
    -- PC + 4 calculation
    pc_plus_4 <= std_logic_vector(unsigned(pc_reg) + 4);
    
    -- PC MUX (for branch)
    next_pc <= branch_pc when branch_taken = '1' else pc_plus_4;
    
    -- Program Counter update process
    process(clk, reset)
    begin
        if reset = '1' then
            pc_reg <= (others => '0');
        elsif rising_edge(clk) then
            if stall = '0' then
                pc_reg <= next_pc;
            end if;
        end if;
    end process;
    
    -- IF/ID pipeline register
    process(clk, reset)
    begin
        if reset = '1' then
            pc_out <= (others => '0');
            instr_out <= (others => '0');
        elsif rising_edge(clk) then
            if stall = '0' then
                pc_out <= pc_reg;
                instr_out <= instruction;
            end if;
        end if;
    end process;
    
end Behavioral;

-- Instruction Memory (ROM)
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Instruction_Memory is
    Port (
        address : in  STD_LOGIC_VECTOR(31 downto 0);
        instr   : out STD_LOGIC_VECTOR(31 downto 0)
    );
end Instruction_Memory;

architecture Behavioral of Instruction_Memory is
    type mem_type is array (0 to 255) of STD_LOGIC_VECTOR(31 downto 0);
    signal memory : mem_type := (
        -- Sample MIPS program (can be modified as needed)
        -- addi $t0, $zero, 5    ($t0 = 5)
        0 => X"20080005",
        -- addi $t1, $zero, 10   ($t1 = 10)
        1 => X"2009000A",
        -- add $t2, $t0, $t1     ($t2 = $t0 + $t1 = 15)
        2 => X"01095020",
        -- sw $t2, 0($zero)      (store $t2 to memory address 0)
        3 => X"AC0A0000",
        -- lw $t3, 0($zero)      (load from memory address 0 to $t3)
        4 => X"8C0B0000",
        -- beq $t3, $t2, 2       (branch if $t3 == $t2, to PC+4+4*2=16)
        5 => X"116A0002",
        -- add $t4, $t2, $t3     ($t4 = $t2 + $t3 = 15 + 15 = 30)
        6 => X"014B6020",
        -- j 2                   (jump to address 8 (2 << 2))
        7 => X"08000002",
        -- add $t5, $t0, $t1     ($t5 = $t0 + $t1 = 5 + 10 = 15)
        8 => X"01096820",
        others => X"00000000"
    );
    
    signal word_addr : integer range 0 to 255;
    
begin
    word_addr <= to_integer(unsigned(address(9 downto 2))); -- Convert byte address to word address
    instr <= memory(word_addr);
end Behavioral;
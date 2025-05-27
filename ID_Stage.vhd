-- Instruction Decode (ID) Stage
-- This stage decodes instructions and reads from register file

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ID_Stage is
    Port (
        clk          : in  STD_LOGIC;
        reset        : in  STD_LOGIC;
        -- Input from IF stage
        pc_in        : in  STD_LOGIC_VECTOR(31 downto 0);
        instr_in     : in  STD_LOGIC_VECTOR(31 downto 0);
        -- Write back inputs
        wb_reg_write : in  STD_LOGIC;
        wb_reg_addr  : in  STD_LOGIC_VECTOR(4 downto 0);
        wb_reg_data  : in  STD_LOGIC_VECTOR(31 downto 0);
        -- Outputs to EX stage
        pc_out       : out STD_LOGIC_VECTOR(31 downto 0);
        reg_data1    : out STD_LOGIC_VECTOR(31 downto 0);
        reg_data2    : out STD_LOGIC_VECTOR(31 downto 0);
        imm_ext      : out STD_LOGIC_VECTOR(31 downto 0);
        rt           : out STD_LOGIC_VECTOR(4 downto 0);
        rd           : out STD_LOGIC_VECTOR(4 downto 0);
        -- Control signals
        alu_op       : out STD_LOGIC_VECTOR(1 downto 0);
        alu_src      : out STD_LOGIC;
        reg_dst      : out STD_LOGIC;
        mem_read     : out STD_LOGIC;
        mem_write    : out STD_LOGIC;
        branch       : out STD_LOGIC;
        mem_to_reg   : out STD_LOGIC;
        reg_write    : out STD_LOGIC
    );
end ID_Stage;

architecture Behavioral of ID_Stage is
    -- Register File component
    component Register_File is
        Port (
            clk       : in  STD_LOGIC;
            rs_addr   : in  STD_LOGIC_VECTOR(4 downto 0);
            rt_addr   : in  STD_LOGIC_VECTOR(4 downto 0);
            write_en  : in  STD_LOGIC;
            write_addr: in  STD_LOGIC_VECTOR(4 downto 0);
            write_data: in  STD_LOGIC_VECTOR(31 downto 0);
            rs_data   : out STD_LOGIC_VECTOR(31 downto 0);
            rt_data   : out STD_LOGIC_VECTOR(31 downto 0)
        );
    end component;
    
    -- Control Unit component
    component Control_Unit is
        Port (
            opcode     : in  STD_LOGIC_VECTOR(5 downto 0);
            funct      : in  STD_LOGIC_VECTOR(5 downto 0);
            reg_dst    : out STD_LOGIC;
            alu_src    : out STD_LOGIC;
            mem_to_reg : out STD_LOGIC;
            reg_write  : out STD_LOGIC;
            mem_read   : out STD_LOGIC;
            mem_write  : out STD_LOGIC;
            branch     : out STD_LOGIC;
            alu_op     : out STD_LOGIC_VECTOR(1 downto 0)
        );
    end component;
    
    -- Instruction fields
    signal opcode     : STD_LOGIC_VECTOR(5 downto 0);
    signal rs_addr    : STD_LOGIC_VECTOR(4 downto 0);
    signal rt_addr    : STD_LOGIC_VECTOR(4 downto 0);
    signal rd_addr    : STD_LOGIC_VECTOR(4 downto 0);
    signal shamt      : STD_LOGIC_VECTOR(4 downto 0);
    signal funct      : STD_LOGIC_VECTOR(5 downto 0);
    signal immediate  : STD_LOGIC_VECTOR(15 downto 0);
    
    -- Control signals
    signal ctrl_reg_dst    : STD_LOGIC;
    signal ctrl_alu_src    : STD_LOGIC;
    signal ctrl_mem_to_reg : STD_LOGIC;
    signal ctrl_reg_write  : STD_LOGIC;
    signal ctrl_mem_read   : STD_LOGIC;
    signal ctrl_mem_write  : STD_LOGIC;
    signal ctrl_branch     : STD_LOGIC;
    signal ctrl_alu_op     : STD_LOGIC_VECTOR(1 downto 0);
    
    -- Register data
    signal reg_data1_temp  : STD_LOGIC_VECTOR(31 downto 0);
    signal reg_data2_temp  : STD_LOGIC_VECTOR(31 downto 0);
    
    -- Sign-extended immediate
    signal imm_ext_temp    : STD_LOGIC_VECTOR(31 downto 0);
    
begin
    -- Extract instruction fields
    opcode <= instr_in(31 downto 26);
    rs_addr <= instr_in(25 downto 21);
    rt_addr <= instr_in(20 downto 16);
    rd_addr <= instr_in(15 downto 11);
    shamt <= instr_in(10 downto 6);
    funct <= instr_in(5 downto 0);
    immediate <= instr_in(15 downto 0);
    
    -- Sign extension for immediate
    imm_ext_temp <= X"0000" & immediate when immediate(15) = '0' else
                    X"FFFF" & immediate;
    
    -- Register File instance
    Reg_File: Register_File port map (
        clk => clk,
        rs_addr => rs_addr,
        rt_addr => rt_addr,
        write_en => wb_reg_write,
        write_addr => wb_reg_addr,
        write_data => wb_reg_data,
        rs_data => reg_data1_temp,
        rt_data => reg_data2_temp
    );
    
    -- Control Unit instance
    Ctrl_Unit: Control_Unit port map (
        opcode => opcode,
        funct => funct,
        reg_dst => ctrl_reg_dst,
        alu_src => ctrl_alu_src,
        mem_to_reg => ctrl_mem_to_reg,
        reg_write => ctrl_reg_write,
        mem_read => ctrl_mem_read,
        mem_write => ctrl_mem_write,
        branch => ctrl_branch,
        alu_op => ctrl_alu_op
    );
    
    -- ID/EX pipeline register
    process(clk, reset)
    begin
        if reset = '1' then
            pc_out <= (others => '0');
            reg_data1 <= (others => '0');
            reg_data2 <= (others => '0');
            imm_ext <= (others => '0');
            rt <= (others => '0');
            rd <= (others => '0');
            alu_op <= (others => '0');
            alu_src <= '0';
            reg_dst <= '0';
            mem_read <= '0';
            mem_write <= '0';
            branch <= '0';
            mem_to_reg <= '0';
            reg_write <= '0';
        elsif rising_edge(clk) then
            pc_out <= pc_in;
            reg_data1 <= reg_data1_temp;
            reg_data2 <= reg_data2_temp;
            imm_ext <= imm_ext_temp;
            rt <= rt_addr;
            rd <= rd_addr;
            alu_op <= ctrl_alu_op;
            alu_src <= ctrl_alu_src;
            reg_dst <= ctrl_reg_dst;
            mem_read <= ctrl_mem_read;
            mem_write <= ctrl_mem_write;
            branch <= ctrl_branch;
            mem_to_reg <= ctrl_mem_to_reg;
            reg_write <= ctrl_reg_write;
        end if;
    end process;
    
end Behavioral;

-- Register File
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Register_File is
    Port (
        clk       : in  STD_LOGIC;
        rs_addr   : in  STD_LOGIC_VECTOR(4 downto 0);
        rt_addr   : in  STD_LOGIC_VECTOR(4 downto 0);
        write_en  : in  STD_LOGIC;
        write_addr: in  STD_LOGIC_VECTOR(4 downto 0);
        write_data: in  STD_LOGIC_VECTOR(31 downto 0);
        rs_data   : out STD_LOGIC_VECTOR(31 downto 0);
        rt_data   : out STD_LOGIC_VECTOR(31 downto 0)
    );
end Register_File;

architecture Behavioral of Register_File is
    type register_array is array(0 to 31) of STD_LOGIC_VECTOR(31 downto 0);
    signal registers : register_array := (others => X"00000000");
    
begin
    -- Reading from registers
    rs_data <= X"00000000" when rs_addr = "00000" else registers(to_integer(unsigned(rs_addr)));
    rt_data <= X"00000000" when rt_addr = "00000" else registers(to_integer(unsigned(rt_addr)));
    
    -- Writing to registers
    process(clk)
    begin
        if rising_edge(clk) then
            if write_en = '1' and write_addr /= "00000" then
                registers(to_integer(unsigned(write_addr))) <= write_data;
            end if;
        end if;
    end process;
    
end Behavioral;

-- Control Unit
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Control_Unit is
    Port (
        opcode     : in  STD_LOGIC_VECTOR(5 downto 0);
        funct      : in  STD_LOGIC_VECTOR(5 downto 0);
        reg_dst    : out STD_LOGIC;
        alu_src    : out STD_LOGIC;
        mem_to_reg : out STD_LOGIC;
        reg_write  : out STD_LOGIC;
        mem_read   : out STD_LOGIC;
        mem_write  : out STD_LOGIC;
        branch     : out STD_LOGIC;
        alu_op     : out STD_LOGIC_VECTOR(1 downto 0)
    );
end Control_Unit;

architecture Behavioral of Control_Unit
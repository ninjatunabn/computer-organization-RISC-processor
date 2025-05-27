-- MIPS 5-Stage Pipeline Processor
-- Top-level entity

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity MIPS_Pipeline is
    Port (
        clk         : in  STD_LOGIC;
        reset       : in  STD_LOGIC;
        -- External memory interface can be added here
        -- Debug outputs
        pc_out      : out STD_LOGIC_VECTOR(31 downto 0);
        instr_out   : out STD_LOGIC_VECTOR(31 downto 0);
        alu_result  : out STD_LOGIC_VECTOR(31 downto 0)
    );
end MIPS_Pipeline;

architecture Behavioral of MIPS_Pipeline is
    -- Component declarations for each pipeline stage
    component IF_Stage is
        Port (
            clk         : in  STD_LOGIC;
            reset       : in  STD_LOGIC;
            stall       : in  STD_LOGIC;
            branch_pc   : in  STD_LOGIC_VECTOR(31 downto 0);
            branch_taken: in  STD_LOGIC;
            pc_out      : out STD_LOGIC_VECTOR(31 downto 0);
            instr_out   : out STD_LOGIC_VECTOR(31 downto 0)
        );
    end component;
    
    component ID_Stage is
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
    end component;
    
    component EX_Stage is
        Port (
            -- Inputs from ID stage
            pc_in        : in  STD_LOGIC_VECTOR(31 downto 0);
            reg_data1    : in  STD_LOGIC_VECTOR(31 downto 0);
            reg_data2    : in  STD_LOGIC_VECTOR(31 downto 0);
            imm_ext      : in  STD_LOGIC_VECTOR(31 downto 0);
            rt           : in  STD_LOGIC_VECTOR(4 downto 0);
            rd           : in  STD_LOGIC_VECTOR(4 downto 0);
            -- Control signals
            alu_op       : in  STD_LOGIC_VECTOR(1 downto 0);
            alu_src      : in  STD_LOGIC;
            reg_dst      : in  STD_LOGIC;
            -- Outputs to MEM stage
            alu_result   : out STD_LOGIC_VECTOR(31 downto 0);
            reg_data2_out: out STD_LOGIC_VECTOR(31 downto 0);
            reg_dst_out  : out STD_LOGIC_VECTOR(4 downto 0);
            -- Branch calculation
            branch_pc    : out STD_LOGIC_VECTOR(31 downto 0);
            zero_flag    : out STD_LOGIC
        );
    end component;
    
    component MEM_Stage is
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
    end component;
    
    component WB_Stage is
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
    end component;
    
    -- Pipeline registers (signals between stages)
    -- IF/ID registers
    signal if_pc        : STD_LOGIC_VECTOR(31 downto 0);
    signal if_instr     : STD_LOGIC_VECTOR(31 downto 0);
    
    -- ID/EX registers
    signal id_pc        : STD_LOGIC_VECTOR(31 downto 0);
    signal id_reg_data1 : STD_LOGIC_VECTOR(31 downto 0);
    signal id_reg_data2 : STD_LOGIC_VECTOR(31 downto 0);
    signal id_imm_ext   : STD_LOGIC_VECTOR(31 downto 0);
    signal id_rt        : STD_LOGIC_VECTOR(4 downto 0);
    signal id_rd        : STD_LOGIC_VECTOR(4 downto 0);
    signal id_alu_op    : STD_LOGIC_VECTOR(1 downto 0);
    signal id_alu_src   : STD_LOGIC;
    signal id_reg_dst   : STD_LOGIC;
    signal id_mem_read  : STD_LOGIC;
    signal id_mem_write : STD_LOGIC;
    signal id_branch    : STD_LOGIC;
    signal id_mem_to_reg: STD_LOGIC;
    signal id_reg_write : STD_LOGIC;
    
    -- EX/MEM registers
    signal ex_alu_result : STD_LOGIC_VECTOR(31 downto 0);
    signal ex_reg_data2  : STD_LOGIC_VECTOR(31 downto 0);
    signal ex_reg_dst    : STD_LOGIC_VECTOR(4 downto 0);
    signal ex_zero_flag  : STD_LOGIC;
    signal ex_branch_pc  : STD_LOGIC_VECTOR(31 downto 0);
    
    -- MEM/WB registers
    signal mem_data       : STD_LOGIC_VECTOR(31 downto 0);
    signal mem_alu_result : STD_LOGIC_VECTOR(31 downto 0);
    signal mem_reg_dst    : STD_LOGIC_VECTOR(4 downto 0);
    signal mem_mem_to_reg : STD_LOGIC;
    signal mem_reg_write  : STD_LOGIC;
    signal mem_branch_taken : STD_LOGIC;
    
    -- WB signals (back to ID)
    signal wb_reg_write   : STD_LOGIC;
    signal wb_reg_dst     : STD_LOGIC_VECTOR(4 downto 0);
    signal wb_reg_data    : STD_LOGIC_VECTOR(31 downto 0);
    
    -- Hazard control signals
    signal stall          : STD_LOGIC := '0';
    
begin
    -- Instantiate pipeline stages
    IF_Stage_Inst: IF_Stage port map (
        clk => clk,
        reset => reset,
        stall => stall,
        branch_pc => ex_branch_pc,
        branch_taken => mem_branch_taken,
        pc_out => if_pc,
        instr_out => if_instr
    );
    
    ID_Stage_Inst: ID_Stage port map (
        clk => clk,
        reset => reset,
        pc_in => if_pc,
        instr_in => if_instr,
        wb_reg_write => wb_reg_write,
        wb_reg_addr => wb_reg_dst,
        wb_reg_data => wb_reg_data,
        pc_out => id_pc,
        reg_data1 => id_reg_data1,
        reg_data2 => id_reg_data2,
        imm_ext => id_imm_ext,
        rt => id_rt,
        rd => id_rd,
        alu_op => id_alu_op,
        alu_src => id_alu_src,
        reg_dst => id_reg_dst,
        mem_read => id_mem_read,
        mem_write => id_mem_write,
        branch => id_branch,
        mem_to_reg => id_mem_to_reg,
        reg_write => id_reg_write
    );
    
    EX_Stage_Inst: EX_Stage port map (
        pc_in => id_pc,
        reg_data1 => id_reg_data1,
        reg_data2 => id_reg_data2,
        imm_ext => id_imm_ext,
        rt => id_rt,
        rd => id_rd,
        alu_op => id_alu_op,
        alu_src => id_alu_src,
        reg_dst => id_reg_dst,
        alu_result => ex_alu_result,
        reg_data2_out => ex_reg_data2,
        reg_dst_out => ex_reg_dst,
        branch_pc => ex_branch_pc,
        zero_flag => ex_zero_flag
    );
    
    MEM_Stage_Inst: MEM_Stage port map (
        clk => clk,
        alu_result => ex_alu_result,
        reg_data2 => ex_reg_data2,
        reg_dst_in => ex_reg_dst,
        zero_flag => ex_zero_flag,
        mem_read => id_mem_read,
        mem_write => id_mem_write,
        branch => id_branch,
        mem_to_reg => id_mem_to_reg,
        reg_write => id_reg_write,
        mem_data => mem_data,
        alu_result_out => mem_alu_result,
        reg_dst_out => mem_reg_dst,
        mem_to_reg_out => mem_mem_to_reg,
        reg_write_out => mem_reg_write,
        branch_taken => mem_branch_taken
    );
    
    WB_Stage_Inst: WB_Stage port map (
        mem_data => mem_data,
        alu_result => mem_alu_result,
        reg_dst_in => mem_reg_dst,
        mem_to_reg => mem_mem_to_reg,
        reg_write => mem_reg_write,
        reg_write_out => wb_reg_write,
        reg_dst_out => wb_reg_dst,
        reg_data_out => wb_reg_data
    );
    
    -- Output assignments
    pc_out <= if_pc;
    instr_out <= if_instr;
    alu_result <= ex_alu_result;
    
    -- TODO: Hazard detection and forwarding units would be added here
    
end Behavioral;
-- Execute (EX) Stage
-- This stage performs ALU operations and calculates branch addresses

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity EX_Stage is
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
end EX_Stage;

architecture Behavioral of EX_Stage is
    -- ALU component
    component ALU is
        Port (
            a       : in  STD_LOGIC_VECTOR(31 downto 0);
            b       : in  STD_LOGIC_VECTOR(31 downto 0);
            alu_ctrl: in  STD_LOGIC_VECTOR(3 downto 0);
            result  : out STD_LOGIC_VECTOR(31 downto 0);
            zero    : out STD_LOGIC
        );
    end component;
    
    -- ALU Control component
    component ALU_Control is
        Port (
            alu_op  : in  STD_LOGIC_VECTOR(1 downto 0);
            funct   : in  STD_LOGIC_VECTOR(5 downto 0);
            alu_ctrl: out STD_LOGIC_VECTOR(3 downto 0)
        );
    end component;
    
    signal alu_b      : STD_LOGIC_VECTOR(31 downto 0);
    signal alu_ctrl_sig : STD_LOGIC_VECTOR(3 downto 0);
    signal alu_result_sig : STD_LOGIC_VECTOR(31 downto 0);
    signal zero_flag_sig  : STD_LOGIC;
    signal destination_reg : STD_LOGIC_VECTOR(4 downto 0);
    signal funct      : STD_LOGIC_VECTOR(5 downto 0);
    
begin
    -- Extract function code from immediate (for R-type instructions)
    funct <= imm_ext(5 downto 0);
    
    -- ALU source mux
    alu_b <= reg_data2 when alu_src = '0' else imm_ext;
    
    -- Register destination mux
    destination_reg <= rt when reg_dst = '0' else rd;
    
    -- ALU Control instance
    ALU_Ctrl: ALU_Control port map (
        alu_op => alu_op,
        funct => funct,
        alu_ctrl => alu_ctrl_sig
    );
    
    -- ALU instance
    ALU_Unit: ALU port map (
        a => reg_data1,
        b => alu_b,
        alu_ctrl => alu_ctrl_sig,
        result => alu_result_sig,
        zero => zero_flag_sig
    );
    
    -- Branch target calculation (PC + 4 + offset * 4)
    -- Note: PC already points to the next instruction (PC+4)
    branch_pc <= std_logic_vector(unsigned(pc_in) + (unsigned(imm_ext) sll 2));
    
    -- Output assignments
    alu_result <= alu_result_sig;
    reg_data2_out <= reg_data2;
    reg_dst_out <= destination_reg;
    zero_flag <= zero_flag_sig;
    
end Behavioral;

-- ALU Control
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ALU_Control is
    Port (
        alu_op  : in  STD_LOGIC_VECTOR(1 downto 0);
        funct   : in  STD_LOGIC_VECTOR(5 downto 0);
        alu_ctrl: out STD_LOGIC_VECTOR(3 downto 0)
    );
end ALU_Control;

architecture Behavioral of ALU_Control is
begin
    process(alu_op, funct)
    begin
        case alu_op is
            when "00" =>  -- lw, sw (add)
                alu_ctrl <= "0010";
                
            when "01" =>  -- beq (subtract)
                alu_ctrl <= "0110";
                
            when "10" =>  -- R-type instructions
                case funct is
                    when "100000" =>  -- add
                        alu_ctrl <= "0010";
                    when "100010" =>  -- sub
                        alu_ctrl <= "0110";
                    when "100100" =>  -- and
                        alu_ctrl <= "0000";
                    when "100101" =>  -- or
                        alu_ctrl <= "0001";
                    when "101010" =>  -- slt (set less than)
                        alu_ctrl <= "0111";
                    when others =>
                        alu_ctrl <= "0000";
                end case;
                
            when others =>
                alu_ctrl <= "0000";
        end case;
    end process;
end Behavioral;

-- ALU
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ALU is
    Port (
        a       : in  STD_LOGIC_VECTOR(31 downto 0);
        b       : in  STD_LOGIC_VECTOR(31 downto 0);
        alu_ctrl: in  STD_LOGIC_VECTOR(3 downto 0);
        result  : out STD_LOGIC_VECTOR(31 downto 0);
        zero    : out STD_LOGIC
    );
end ALU;

architecture Behavioral of ALU is
    signal result_temp : STD_LOGIC_VECTOR(31 downto 0);
begin
    process(a, b, alu_ctrl)
    begin
        case alu_ctrl is
            when "0000" =>  -- AND
                result_temp <= a and b;
            when "0001" =>  -- OR
                result_temp <= a or b;
            when "0010" =>  -- ADD
                result_temp <= std_logic_vector(signed(a) + signed(b));
            when "0110" =>  -- SUB
                result_temp <= std_logic_vector(signed(a) - signed(b));
            when "0111" =>  -- SLT (Set on Less Than)
                if signed(a) < signed(b) then
                    result_temp <= X"00000001";
                else
                    result_temp <= X"00000000";
                end if;
            when others =>
                result_temp <= (others => '0');
        end case;
    end process;
    
    -- Zero flag is set if result is zero
    zero <= '1' when result_temp = X"00000000" else '0';
    result <= result_temp;
    
end Behavioral;
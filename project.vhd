----------------------------------------------------------------------------------
--
-- Prova Finale (Progetto di Reti Logiche)
-- Prof. William Fornaciari - Anno 2020/2021
--
-- Riccardo Luigi Aielli (Codice Persona 10621879 Matricola 907237)
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity project_reti_logiche is
port (
    i_clk : in std_logic;
    i_rst : in std_logic;
    i_start : in std_logic;
    i_data : in std_logic_vector(7 downto 0);
    o_address : out std_logic_vector(15 downto 0);
    o_done : out std_logic;
    o_en : out std_logic;
    o_we : out std_logic;
    o_data : out std_logic_vector (7 downto 0)
);
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is

    type state_type is (IDLE, COLUMN_READ_SET, PAUSA_RAM_COL, COLUMN_READ, ROW_READ_SET, PAUSA_RAM_ROW, ROW_READ, PIXEL_COUNT, INCREASE_ADDRESS, CURRENT_PIXEL_READ, FIND_MIN_MAX, PREPARE_SHIFT, PREPARE_READ_ADDRESS, SET_EN_ON, CURRENT_MENO_MIN_CALC, CALCULATE_TEMP_PIXEL, CALCULATE_NEW_PIXEL, WRITE_PIXEL, SALVA_IN_RAM, REPEAT_LOOP, DONE);
    
    signal cur_state, next_state : state_type;
    
    signal min_pixel : STD_LOGIC_VECTOR(7 downto 0);
    signal min_pixel_load: std_logic := '0';
    signal max_pixel : STD_LOGIC_VECTOR(7 downto 0);
    signal max_pixel_load: std_logic := '0';
    
    signal delta_value_somma_uno: STD_LOGIC_VECTOR (15 downto 0);
    
    signal current_meno_min:  STD_LOGIC_VECTOR (15 downto 0);
    signal current_meno_min_load: std_logic := '0';
    
    signal temp_pixel:  STD_LOGIC_VECTOR (15 downto 0);
    signal temp_pixel_load: std_logic := '0';
    
    signal new_pixel:  STD_LOGIC_VECTOR (7 downto 0);
    signal new_pixel_load: std_logic := '0';
    
    signal shift : STD_LOGIC_VECTOR(7 downto 0);
    signal shift_calc: std_logic := '0';
    
    signal o_address_next : STD_LOGIC_VECTOR(15 downto 0);
    signal o_address_next_increase: std_logic := '0';
    signal o_address_next_rst: std_logic := '0';
    
    signal last_address : STD_LOGIC_VECTOR(15 downto 0) := "0000000000000000";
    
    signal row : STD_LOGIC_VECTOR(7 downto 0);
    signal row_load: std_logic := '0';
    
    signal column : STD_LOGIC_VECTOR(7 downto 0);
    signal column_load: std_logic := '0';
    
    signal contatore: STD_LOGIC_VECTOR (7 downto 0);
    signal contatore_set: std_logic := '0';
    signal contatore_decremento: std_logic := '0';
    
    signal pixel_num : STD_LOGIC_VECTOR(15 downto 0);
    signal pixel_num_load: std_logic := '0';
    
    signal o_data_load: std_logic := '0';
    
    signal o_address_increase: std_logic := '0';
    signal o_address_column: std_logic := '0';
    signal o_address_row: std_logic := '0';
    signal o_address_write: std_logic := '0';
    
    signal reset: std_logic := '0';
    
    begin
    
        --Circuito di reset e avanzamento stato
        process (i_clk, i_rst) 
        begin
            if (i_rst = '1') then
                cur_state <= IDLE;  
            elsif (rising_edge(i_clk)) then
                cur_state <= next_state;
            end if;
        end process;
        
        --REGISTRI--
        --Registro column
         process(i_clk, i_rst, reset, column_load)
            begin
                if(i_rst = '1' or reset = '1') then
                    column <= "00000000";
                elsif (rising_edge(i_clk)) and column_load = '1' then
                    column <= i_data;
                end if;
         end process;
         
         --Registro row
         process(i_clk, i_rst, reset, row_load)
            begin
                if(i_rst = '1' or reset = '1') then
                    row <= "00000000";
                elsif (rising_edge(i_clk)) and row_load = '1' then
                    row <= i_data;
                end if;
         end process;
         
         --Registro max_pixel
         process(i_clk, i_rst, reset, max_pixel_load)
            begin
                if(i_rst = '1' or reset = '1') then
                    max_pixel <= "00000000";
                elsif (rising_edge(i_clk)) and max_pixel_load = '1' then
                    max_pixel <= i_data;
                end if;
         end process;
         
         --Registro min_pixel
         process(i_clk, i_rst, reset, min_pixel_load)
            begin
                if(i_rst = '1' or reset = '1') then
                    min_pixel <= "11111111";
                elsif (rising_edge(i_clk)) and min_pixel_load = '1' then
                    min_pixel <= i_data;
                end if;
         end process;
         
         --Registro o_data
         process(i_clk, i_rst, reset, o_data_load)
            begin
                if(i_rst = '1' or reset = '1') then
                    o_data <= "00000000";
                elsif (rising_edge(i_clk)) and o_data_load = '1' then
                    o_data <= new_pixel;
                end if;
         end process;
         -----------------
         --FINE REGISTRI--
         
         --Ultimo indirizzo immagine originale
         last_address <= pixel_num + "0000000000000010";
         
         --Calcolo delta + 1
         delta_value_somma_uno <= ("00000000" & max_pixel) - ("00000000" & min_pixel) + "0000000000000001";
        
        --REGISTRI/PROCESSI UTILI--
        --Contatore utile al prodotto
        process(i_clk, i_rst, reset)
        begin
            if(i_rst = '1' or reset = '1') then
                    contatore <= "00000000";
            elsif (rising_edge(i_clk)) then
                if contatore_decremento = '1' then
                    contatore <= contatore - "00000001";
                elsif contatore_set = '1' then
                    contatore <= column;
                end if;
            end if;
        end process;
    
        --Calcolo prodotto per somme
        process(i_clk, i_rst, reset, pixel_num_load)
        begin
            if(i_rst = '1' or reset = '1') then
                pixel_num <= "0000000000000000";
            elsif (rising_edge(i_clk)) and pixel_num_load = '1' then
                pixel_num <= pixel_num + row; 
            end if;
        end process;
        
        --Registro o_address_next 
        process(i_clk, i_rst, reset)
        begin
            if(i_rst = '1' or reset = '1') then
                    o_address_next <= "0000000000000010";
            elsif (rising_edge(i_clk)) then
                if o_address_next_increase = '1' then
                    o_address_next <= o_address_next + "0000000000000001";
                elsif o_address_next_rst = '1' then
                o_address_next <= "0000000000000010";
                end if;
            end if;
        end process;
        
        --Registro o_address
        process(i_clk, i_rst, reset)
        begin
            if(i_rst = '1' or reset = '1') then
                    o_address <= "0000000000000000";
            elsif (rising_edge(i_clk)) then
                if o_address_increase = '1' then
                    o_address <= o_address_next;
                elsif o_address_column = '1' then
                    o_address <= "0000000000000000";
                elsif o_address_row = '1' then
                    o_address <= "0000000000000001";
                elsif o_address_write = '1' then
                    o_address <= o_address_next + pixel_num;
                end if;
            end if;
        end process;
         
        --Registro current_meno_min
        process(i_clk, i_rst, reset, current_meno_min_load)
        begin
            if(i_rst = '1' or reset = '1') then
                current_meno_min <= "0000000000000000";
            elsif (rising_edge(i_clk)) and current_meno_min_load = '1' then
                --Calcolo current_meno_min
                current_meno_min <= ("00000000" & i_data)-("00000000" & min_pixel); 
            end if;
        end process;
         
        --Registro shift, calcolo shift level con controllo a soglia
        process(i_clk, i_rst, reset, shift_calc)
            begin
                if(i_rst = '1' or reset = '1') then
                    shift <= "00000000";
                elsif (rising_edge(i_clk)) and shift_calc = '1' then
                    --Calcolo shift level con controllo a soglia
                    if delta_value_somma_uno = "0000000100000000" then
                        shift <= "00000000";
                     elsif (("0000000010000000" <= delta_value_somma_uno) and (delta_value_somma_uno < "0000000100000000")) then -- tra 128 e 256
                        shift <= "00000001";
                     elsif (("0000000001000000" <= delta_value_somma_uno) and (delta_value_somma_uno < "0000000010000000")) then -- tra 64 e 128
                        shift <= "00000010";
                     elsif (("0000000000100000" <= delta_value_somma_uno) and (delta_value_somma_uno < "0000000001000000")) then -- tra 32 e 64
                        shift <= "00000011";
                     elsif (("0000000000010000" <= delta_value_somma_uno) and (delta_value_somma_uno < "0000000000100000")) then -- tra 16 e 32
                        shift <= "00000100";
                     elsif (("0000000000001000" <= delta_value_somma_uno) and (delta_value_somma_uno < "0000000000010000")) then -- tra 8 e 16
                        shift <= "00000101";
                     elsif (("0000000000000100" <= delta_value_somma_uno) and (delta_value_somma_uno < "0000000000001000")) then -- tra 4 e 8
                        shift <= "00000110";
                     elsif (("0000000000000010" <= delta_value_somma_uno) and (delta_value_somma_uno < "0000000000000100")) then -- tra 2 e 4
                        shift <= "00000111";
                     elsif (("0000000000000001" <= delta_value_somma_uno) and (delta_value_somma_uno < "0000000000000010")) then -- tra 1 e 2
                        shift <= "00001000";
                     end if;
                end if;
         end process;
         
         --Registro temp_pixel, calcolo temp_pixel facendo lo shift
         process(i_clk, i_rst, reset, temp_pixel_load)
            begin
                if(i_rst = '1' or reset = '1') then
                    temp_pixel <= "0000000000000000";
                elsif (rising_edge(i_clk)) and temp_pixel_load = '1' then
                    if shift="00000000" then
                        temp_pixel <= current_meno_min;
                    elsif shift="00000001" then
                        temp_pixel <= current_meno_min(14 downto 0) & "0";
                    elsif shift="00000010" then
                        temp_pixel <= current_meno_min(13 downto 0) & "00";
                    elsif shift="00000011" then
                        temp_pixel <= current_meno_min(12 downto 0) & "000";
                    elsif shift="00000100" then
                        temp_pixel <= current_meno_min(11 downto 0) & "0000";
                    elsif shift="00000101" then
                        temp_pixel <= current_meno_min(10 downto 0) & "00000";
                    elsif shift="00000110" then
                        temp_pixel <= current_meno_min(9 downto 0) & "000000";
                    elsif shift="00000111" then
                        temp_pixel <= current_meno_min(8 downto 0) & "0000000";
                    elsif shift="00001000" then
                        temp_pixel <= current_meno_min(7 downto 0) & "00000000";
                    end if;
                end if;
         end process;
         
         --Registro new_pixel, calcolo il new_pixel. Min tra 255 e temp_pixel
         process(i_clk, i_rst, reset, new_pixel_load)
            begin
                if(i_rst = '1' or reset = '1') then
                    new_pixel <= "00000000";
                elsif (rising_edge(i_clk)) and new_pixel_load = '1' then
                    --Calcolo il new_pixel
                    if (temp_pixel < "0000000011111111") then
                        new_pixel <= temp_pixel(7 downto 0);
                    else new_pixel <= "11111111";
                    end if;
                end if;
         end process;
         --------------------------------
         --FINE REGISTRI/PROCESSI UTILI--
        
        --MACCHINA A STATI FINITI--
        process(i_clk , cur_state , i_data , i_start)
        begin
        
        --setup segnali registri e process
        pixel_num_load <= '0';
        new_pixel_load <= '0';
        column_load <= '0';
        row_load <= '0';
        contatore_decremento <= '0';
        contatore_set <= '0';
        o_address_next_increase <= '0';
        o_address_next_rst <= '0';
        max_pixel_load <= '0';
        min_pixel_load <= '0';
        temp_pixel_load <= '0';
        shift_calc <= '0';
        current_meno_min_load <= '0';
        o_data_load <= '0';
        o_address_increase <= '0';
        o_address_column <= '0';
        o_address_row <= '0';
        o_address_write <= '0';
        --segnali memoria
        o_en <= '0';
        o_we <= '0';
        --segnale done
        o_done <= '0';
        reset <= '0';
                
        next_state <= cur_state;
        
            case cur_state is
                when IDLE =>
                    --Fa il reset di tutti i registri
                    reset <= '1';
                    if (i_start = '1') then
                        --setup segnali registri e process
                        pixel_num_load <= '0';
                        new_pixel_load <= '0';
                        column_load <= '0';
                        row_load <= '0';
                        contatore_decremento <= '0';
                        contatore_set <= '0';
                        o_address_next_increase <= '0';
                        o_address_next_rst <= '0';
                        max_pixel_load <= '0';
                        min_pixel_load <= '0';
                        temp_pixel_load <= '0';
                        shift_calc <= '0';
                        current_meno_min_load <= '0';
                        o_data_load <= '0';
                        o_address_increase <= '0';
                        o_address_column <= '0';
                        o_address_row <= '0';
                        o_address_write <= '0';
                        --segnali memoria
                        o_en <= '0';
                        o_we <= '0';
                        --segnale done
                        o_done <= '0';

                        next_state <= COLUMN_READ_SET; 
                    end if;
                -----------------------------------------------    
                when COLUMN_READ_SET =>
                    o_en <= '1';
                    o_address_column <= '1';
                    next_state <= PAUSA_RAM_COL;
                -----------------------------------------------
                when PAUSA_RAM_COL =>
                    o_en <= '1';
                    next_state <= COLUMN_READ;   
                -----------------------------------------------  
                when COLUMN_READ =>
                    o_en <= '1';
                    column_load <= '1';
                    next_state <= ROW_READ_SET;
                -----------------------------------------------    
                when ROW_READ_SET =>
                    o_en <= '1';
                    if (column = "00000000") then
                            next_state <= DONE;
                    end if;
                    contatore_set <= '1';
                    o_address_row <= '1';
                    next_state <= PAUSA_RAM_ROW;
                -----------------------------------------------
                when PAUSA_RAM_ROW =>
                    o_en <= '1';
                    next_state <= ROW_READ;  
                -----------------------------------------------    
                when ROW_READ =>
                    o_en <= '1';
                    row_load <= '1';
                    next_state <= PIXEL_COUNT;
                -----------------------------------------------    
                when PIXEL_COUNT =>
                    if (row = "00000000") then
                        next_state <= DONE;
                    end if;
                    pixel_num_load <= '1';
                    contatore_decremento <= '1';
                    if (contatore = "00000001") then --devo confrontare il contatore con 1
                        next_state <= INCREASE_ADDRESS;
                    end if;
                -----------------------------------------------
                when INCREASE_ADDRESS =>
                    o_address_increase <= '1';
                    next_state <= CURRENT_PIXEL_READ;
                -----------------------------------------------
                when CURRENT_PIXEL_READ =>  
                    if (o_address_next = last_address) then
                        o_address_next_rst <= '1';
                        next_state <= PREPARE_SHIFT; 
                    else 
                        o_en<='1';
                        next_state <= FIND_MIN_MAX;
                    end if;
                -----------------------------------------------  
                when FIND_MIN_MAX =>
                    if (i_data > max_pixel ) then
                        max_pixel_load <= '1';
                    end if;
                    if (i_data < min_pixel ) then
                        min_pixel_load <= '1';
                    end if;
                    o_address_next_increase <= '1';
                    next_state <= INCREASE_ADDRESS;
                ----------------------------------------------- 
                when PREPARE_SHIFT =>
                    shift_calc <= '1';
                    next_state <= PREPARE_READ_ADDRESS;
                -----------------------------------------------
                when PREPARE_READ_ADDRESS =>
                    o_address_increase <= '1';
                    next_state <= SET_EN_ON; 
                ----------------------------------------------- 
                when SET_EN_ON =>
                    o_en<='1';
                    next_state <= CURRENT_MENO_MIN_CALC;
                -----------------------------------------------
                when CURRENT_MENO_MIN_CALC =>
                    current_meno_min_load <= '1';
                    next_state <= CALCULATE_TEMP_PIXEL;
                -----------------------------------------------
                when CALCULATE_TEMP_PIXEL =>
                    temp_pixel_load <= '1';
                    next_state <= CALCULATE_NEW_PIXEL;
                -----------------------------------------------
                when CALCULATE_NEW_PIXEL =>
                    new_pixel_load <= '1';
                    o_address_write <= '1';
                    next_state <= WRITE_PIXEL;
                -----------------------------------------------
                when WRITE_PIXEL =>
                    o_data_load <= '1';
                next_state <= SALVA_IN_RAM;
                -----------------------------------------------
                when SALVA_IN_RAM =>
                    o_en<='1';
                    o_we <= '1';
                    next_state <= REPEAT_LOOP;
                -----------------------------------------------
                when REPEAT_LOOP =>
                    if (o_address_next > pixel_num) then
                        next_state <= DONE;
                    else 
                        o_address_next_increase <= '1';
                        next_state <= PREPARE_READ_ADDRESS;
                    end if;
                -----------------------------------------------  
                when DONE =>
                    o_done <= '1';
                    if (i_start = '0') then
                        next_state <= IDLE;
                    end if;
                -----------------------------------------------  
            end case;
        end process;
        ---------------------------
        --MACCHINA A STATI FINITI--
end Behavioral;

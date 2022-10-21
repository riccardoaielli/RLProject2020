# RLProject2020

This is the project of *Reti Logiche* course (Politecnico di Milano, A.Y. 2020/2021).
<br>
Evaluation: 30/30 Cum Laude

## Specs
It consists in a simple implementation of the histogram equalization method to adjust the contrast of images.
For more details read the official [specifications](/Specifications.pdf) written in italian.

The component must have the following interface:
```
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
```

## Report
For more details about my work read the [report](/Report.pdf).

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity control_unit is
    generic(data_width: integer :=32;
            addr_width: integer :=32);
    port(clk_i: in std_logic
        );
end entity;

architecture str of control_unit is

begin

end str;
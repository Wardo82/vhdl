library ieee;
use ieee.std_logic_1164.all, ieee.numeric_logic.all;

package trigonometry is


    -- Component declaration
    component cos is
        port(theta: in real; result: out real);
    end component;
    
end package;

library trigonometry;
use trigonometry.all;

entity cos is 
    port(theta: in real; result: out real);
end entity;

architecture series of cos is
begin
    summation: process(theta) is
        variable sum, term: real;
        variable n: natural;
    begin
        term := 1;
        sum := term;
        n := 0;
        while abs term > abs (sum / 1.E06) loop
            n := n + 2;
            term := (-term) * (theta**2) / real((n-1)*n);
            sum := sum + term;
        end loop;
        result <= sum;
    end process summation;
end architecture series;
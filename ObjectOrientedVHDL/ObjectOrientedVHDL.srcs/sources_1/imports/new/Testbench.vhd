----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/03/2022 07:13:24 PM
-- Design Name: 
-- Module Name: Testbench - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

library work;
use work.DataStructures.all;

entity Testbench is
--  Port ( );
end Testbench;

architecture Behavioral of Testbench is
    shared variable List: LinkedList;
    shared variable BTree: BinaryTree;
begin

    process is
    begin
        for i in 1 to 5 loop
            report "Pushing " & integer'image(i);
            List.Push(i);
            BTree.AddNode(i);
        end loop;
        
        while not List.IsEmpty loop
            report "Popping " & integer'image(List.Pop);
        end loop;
        
        report "The root of the tree is " & integer'image(BTree.GetRoot);
        
        wait;
    end process;
end Behavioral;

----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/02/2022 10:32:39 PM
-- Design Name: 
-- Module Name: DataStructures - Behavioral
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

-- Public declarations go here, in the declarative region.
package DataStructures is
    
    type LinkedList is protected
        procedure Push(constant Data: in integer);
        impure function Pop return integer;
        impure function IsEmpty return boolean;
    end protected;
    
    type Node;
        
    type NodePtr is access Node;
        
    type Node is record
        Data: integer;
        Left: NodePtr;
        Right: NodePtr;
    end record;
        
    type BinaryTree is protected 
        procedure AddNode(constant Data: in integer);
        -- impure function Find(constant Data: in integer) return boolean;
        impure function GetRoot return integer;
    end protected;
    
end package DataStructures;

-- Private declarations and Implementations go here, in the body.
package body DataStructures is

    type LinkedList is protected body
        type Item;
        
        type Ptr is access Item;
        
        type Item is record
            Data: integer;
            NextItem: Ptr;
        end record;
        
        variable Root: Ptr;
        
        procedure Push(Data: in integer) is
            variable NewItem: Ptr;
            variable Node: Ptr;
        begin
            -- Dynamically allocate a new item
            NewItem := new Item;
            NewItem.Data := Data;
            -- If the list is empty, this becomes the root node
            if Root = null then
                Root := NewItem;
            else
                -- Start searching from the root node
                Node := Root;
                -- Find the last node
                while Node.NextItem  /= null loop
                    Node := Node.NextItem;
                end loop;
                -- Append the new item at the end of the list
                Node.NextItem := NewItem;
            end if;
        end procedure Push;
        
        impure function Pop return integer is
            variable Node: Ptr;
            variable RetVal: integer;
        begin
            Node := Root;
            Root := Root.NextItem;
            
            -- Copy and free the dynamic object before return
            RetVal := Node.Data;
            deallocate (Node);
            
            return RetVal;
        end;
        
        impure function IsEmpty return boolean is
        begin 
            return Root = null;
        end;
    end protected body;
    
    type BinaryTree is protected body
        
        variable Root: NodePtr;
        
        procedure AddNode(constant Data: integer) is
            variable NewNode: NodePtr;
            variable AuxNode: NodePtr;
        begin
            -- Dynamically allocate a new item
            NewNode := new Node;
            NewNode.Data := Data;
            
            -- IF the tree is empty, this becomes the root node
            if Root = null then
                Root := NewNode;
            else
                -- Start searching from the root node
                AuxNode := Root;
                
                -- Find the corresponding node for a balanced Binary tree
                while AuxNode.Data /= NewNode.Data loop
                    -- If it is greater, go right
                    if AuxNode.Data > NewNode.Data then
                        if AuxNode.Right = null then
                            AuxNode.Right := NewNode;
                            AuxNode := NewNode;
                        else 
                            AuxNode := AuxNode.Right;
                        end if;
                    -- If it is lower, go left
                    elsif AuxNode.Data < NewNode.Data then
                        if AuxNode.Left = null then
                            AuxNode.Left := NewNode;
                            AuxNode := NewNode;
                        else 
                            AuxNode := AuxNode.Left;
                        end if;
                    end if;
                end loop;
            end if;
        end procedure;
             
        impure function GetRoot return Integer is
        begin
            return Root.Data;
        end;
    end protected body;
end package body DataStructures;

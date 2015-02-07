-- ************************************************************************
--  Copyright (C) 1996, 1997 - Xilinx, Inc.
-- ************************************************************************
--  Title:	Unified library utilities
--  Created:	Fri Apr 11 11:09:56 1997
--  Author:	Tony Williams
--  $Id: da_utils.vhd,v 1.9 2008/09/08 20:07:46 akennedy Exp $
--
--  Description:
--
--  Modification History:
--  Copy of ul.ul_utils bitsneededto represent function for local use
--  Steve Creaney, October 2005
--
--  $Header: /devl/xcs/repo/env/Databases/ip/src/com/xilinx/ip/da_fir_v9_0/da_utils.vhd,v 1.9 2008/09/08 20:07:46 akennedy Exp $
--
-- ************************************************************************

-- LIBRARY ieee;
-- USE ieee.std_logic_1164.ALL;

PACKAGE da_utils IS

-- ------------------------------------------------------------------------ --
-- FUNCTION PROTOTYPES:							    --
-- ------------------------------------------------------------------------ --

  FUNCTION bitsneededtorepresent( a_value : INTEGER )
    RETURN INTEGER;

END da_utils;

PACKAGE BODY da_utils IS

-- ------------------------------------------------------------------------ --
-- FUNCTIONS:
-- ------------------------------------------------------------------------ --
  FUNCTION bitsneededtorepresent( a_value : INTEGER )
    RETURN INTEGER IS

    VARIABLE return_value : INTEGER := 1;

  BEGIN

    FOR i IN 30 DOWNTO 0 LOOP
      IF a_value >= 2**i THEN
	return_value := i+1;
	EXIT;
      END IF;
    END LOOP;

    RETURN return_value;

  END bitsneededtorepresent;

END da_utils;

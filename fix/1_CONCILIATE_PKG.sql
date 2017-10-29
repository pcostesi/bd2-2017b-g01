--------------------------------------------------------
--  DDL for Package CONCILIATE_PKG
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE "BDII_TEAM1"."CONCILIATE_PKG" AS 

  PROCEDURE conciliate_statement ( pStatementLocator VARCHAR ) ;

  PROCEDURE conciliate_all_statements;

END CONCILIATE_PKG;

/

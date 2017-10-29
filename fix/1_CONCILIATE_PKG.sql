create or replace PACKAGE CONCILIATE_PKG AS 

  PROCEDURE conciliate_statement ( pStatementLocator VARCHAR ) ;

  PROCEDURE conciliate_all_statements;

END CONCILIATE_PKG;

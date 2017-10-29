create or replace PACKAGE reset_pkg AS
  PROCEDURE drop_table_if_exists(name VARCHAR);
  PROCEDURE drop_sequence_if_exists(name VARCHAR);
  PROCEDURE drop_index_if_exists(name VARCHAR);
END reset_pkg;
/

create or replace PACKAGE BODY reset_pkg AS

   PROCEDURE run_ignoring(stmt VARCHAR, errcode NUMBER) AS
   BEGIN
      EXECUTE IMMEDIATE stmt;
   EXCEPTION
      WHEN OTHERS THEN
         IF SQLCODE != errcode THEN
            RAISE;
         END IF;
   END run_ignoring;

   PROCEDURE drop_table_if_exists(name VARCHAR) AS
   BEGIN
      run_ignoring('DROP TABLE ' || name, -942);
   END drop_table_if_exists;

   PROCEDURE drop_sequence_if_exists(name VARCHAR) AS
   BEGIN
      run_ignoring('DROP SEQUENCE ' || name, -2289);
   END drop_sequence_if_exists;

   PROCEDURE drop_index_if_exists(name VARCHAR) AS
   BEGIN
      run_ignoring('DROP INDEX ' || name, -1418);
   END drop_index_if_exists;

END reset_pkg;
/

-- Original
EXECUTE reset_pkg.drop_table_if_exists('CONCILIATION');
EXECUTE reset_pkg.drop_table_if_exists('HOTEL_STATEMENT');
EXECUTE reset_pkg.drop_table_if_exists('PAYMENT_ORDER');
EXECUTE reset_pkg.drop_table_if_exists('SUPPLIER');

EXECUTE reset_pkg.drop_sequence_if_exists('CONCILIATION_SEQ');
EXECUTE reset_pkg.drop_sequence_if_exists('HOTEL_STATEMENT_SEQ');
EXECUTE reset_pkg.drop_sequence_if_exists('PAYMENT_ORDER_SEQ');
EXECUTE reset_pkg.drop_sequence_if_exists('SUPPLIER_SEQ');

EXECUTE reset_pkg.drop_index_if_exists('PO2_IDX');
EXECUTE reset_pkg.drop_index_if_exists('SUPPLIER_PK');
EXECUTE reset_pkg.drop_index_if_exists('PAYMENT_ORDER_PK');
EXECUTE reset_pkg.drop_index_if_exists('PO3_IDX');
EXECUTE reset_pkg.drop_index_if_exists('PO1_IDX');

-- Ours
EXECUTE reset_pkg.drop_table_if_exists('CONCILIATION_STATUS');
EXECUTE reset_pkg.drop_index_if_exists('HOTEL_STATEMENT_RECORD_LOCATOR_UNQ');
EXECUTE reset_pkg.drop_index_if_exists('PAYMENT_ORDER_RECORD_LOCATOR_UNQ');

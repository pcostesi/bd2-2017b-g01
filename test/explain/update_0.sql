
	/**
	* CBO Explain for UPDATE-0:
	*		"Remove Statement Locator"
	*/

	/* Resultados:

	STATEMENT_ID                         COST    IO_COST   CPU_COST      BYTES CARDINALITY
	------------------------------ ---------- ---------- ---------- ---------- -----------
	UPDATE-0:INSERT-CONCILIATION            1          1          0        100           1	CHANGED!
	UPDATE-0:SELECT-1                      23         23    1485611         61           1
	UPDATE-0:SELECT-2                      34         34    1612020        246           1
	UPDATE-0:SELECT-3                       2          2      11631         12           1
	UPDATE-0:SELECT-4                      35         34   20532047       2442          11
	UPDATE-0:UPDATE-HOTEL_STATE             2          2      11671        216           1
	UPDATE-0:UPDATE-PAYMENT_ORDER           2          2      11731         59           1
	*/

	ALTER SESSION SET OPTIMIZER_MODE = CHOOSE;

	/* Table Statistics */
	EXEC DBMS_STATS.gather_table_stats('BDII_TEAM1', 'HOTEL_STATEMENT', cascade => TRUE);
	EXEC DBMS_STATS.gather_table_stats('BDII_TEAM1', 'PAYMENT_ORDER', cascade => TRUE);
	EXEC DBMS_STATS.gather_table_stats('BDII_TEAM1', 'SUPPLIER', cascade => TRUE);

	/* Index Statistics */
	EXEC DBMS_STATS.gather_index_stats('BDII_TEAM1', 'HOTEL_STATEMENT_PK');
	EXEC DBMS_STATS.gather_index_stats('BDII_TEAM1', 'PAYMENT_ORDER_PK');
	EXEC DBMS_STATS.gather_index_stats('BDII_TEAM1', 'PO1_IDX');
	EXEC DBMS_STATS.gather_index_stats('BDII_TEAM1', 'PO2_IDX');
	EXEC DBMS_STATS.gather_index_stats('BDII_TEAM1', 'PO3_IDX');
	EXEC DBMS_STATS.gather_index_stats('BDII_TEAM1', 'SUPPLIER_PK');

	DELETE FROM PLAN_TABLE;

	/* --------------------------------------------------------------------- */
	EXPLAIN PLAN
		SET STATEMENT_ID = 'UPDATE-0:SELECT-1'
		INTO PLAN_TABLE FOR
			select /*+ MERGE */
				po.ID, po.TOTAL_COST, po.TOTAL_COST_CURRENCY,
				po.STATUS, po.CHECKIN, po.CHECKOUT
			from PAYMENT_ORDER po, SUPPLIER s
			where po.supplier_id = 9
				and po.supplier_id = s.id
				and lower(po.record_locator) = lower('BBGTID')
				and rtrim(ltrim(po.status)) = 'PENDING';
	/* --------------------------------------------------------------------- */
	/* CHANGED! */
	EXPLAIN PLAN
		SET STATEMENT_ID = 'UPDATE-0:INSERT-CONCILIATION'
		INTO PLAN_TABLE FOR
			INSERT INTO CONCILIATION (
				ID, HOTEL_STATEMENT_ID, PAYMENT_ORDER_ID,
				CONCILIATED_AMOUNT, CONCILIATED_AMOUNT_CURRENCY,
				ADJUSTMENT_AMOUNT, ADJUSTMENT_AMOUNT_CURRENCY,
				STATUS, CREATED, MODIFIED)
				VALUES (
					CONCILIATION_SEQ.nextval, '1',
					null, null, null, null, null,
					'CHECKOUT_PENDING', sysdate, sysdate);
	/* --------------------------------------------------------------------- */
	EXPLAIN PLAN
		SET STATEMENT_ID = 'UPDATE-0:UPDATE-HOTEL_STATE'
		INTO PLAN_TABLE FOR
			UPDATE HOTEL_STATEMENT SET STATUS = 'CHECKOUT_PENDING', MODIFIED = SYSDATE
			WHERE ID = '1';
	/* --------------------------------------------------------------------- */
	EXPLAIN PLAN
		SET STATEMENT_ID = 'UPDATE-0:UPDATE-PAYMENT_ORDER'
		INTO PLAN_TABLE FOR
			UPDATE PAYMENT_ORDER SET STATUS = 'CONCILIATED', MODIFIED = SYSDATE
			WHERE ID = '1';
	/* --------------------------------------------------------------------- */
	EXPLAIN PLAN
		SET STATEMENT_ID = 'UPDATE-0:SELECT-2'
		INTO PLAN_TABLE FOR
			SELECT
				hs.ID, hs.SUPPLIER_ID, hs.RECORD_LOCATOR,
				hs.AMOUNT, hs.CURRENCY
			FROM hotel_statement hs
			WHERE hs.statement_locator = '119/08/09/17'
			AND LTRIM(RTRIM(hs.STATUS)) = 'PENDING';
	/* --------------------------------------------------------------------- */
	EXPLAIN PLAN
		SET STATEMENT_ID = 'UPDATE-0:SELECT-3'
		INTO PLAN_TABLE FOR
			SELECT s.CONCILIATION_TOLERANCE_PERC, s.CONCILIATION_TOLERANCE_MAX
			FROM supplier s
			WHERE s.ID = '1';
	/* --------------------------------------------------------------------- */
	EXPLAIN PLAN
		SET STATEMENT_ID = 'UPDATE-0:SELECT-4'
		INTO PLAN_TABLE FOR
			SELECT distinct hs.statement_locator
			FROM hotel_statement hs
			WHERE LTRIM(RTRIM(hs.STATUS)) = 'PENDING';
	/* --------------------------------------------------------------------- */

	/* Mostrar las estadísticas de los planes explicados */
	@view_plans.sql

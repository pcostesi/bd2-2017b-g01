
	/**
	* CBO Explain for UPDATE-3:
	*		"Conciliation Status Refactor"
	*/

	/* Resultados:

	STATEMENT_ID                         COST    IO_COST   CPU_COST      BYTES CARDINALITY
	------------------------------ ---------- ---------- ---------- ---------- -----------
	UPDATE-3:INSERT-CONCILIATION            1          1          0        100           1	CHANGED!
	UPDATE-3:SELECT-1                       4          4     300236         53           1	CHANGED!
	UPDATE-3:SELECT-2                       0          0          0          0           0
	UPDATE-3:SELECT-3                       0          0          0          0           0
	UPDATE-3:SELECT-4                      41         40   20451109      57036        1164	CHANGED!
	UPDATE-3:UPDATE-HOTEL_STATE             0          0          0          0           0	CHANGED!
	UPDATE-3:UPDATE-PAYMENT_ORDER           0          0          0          0           0	CHANGED!
	*/

	ALTER SESSION SET OPTIMIZER_MODE = CHOOSE;

	/* Table Statistics */
	EXEC DBMS_STATS.gather_table_stats('BDII_TEAM1', 'CONCILIATION_STATUS', cascade => TRUE);
	EXEC DBMS_STATS.gather_table_stats('BDII_TEAM1', 'HOTEL_STATEMENT', cascade => TRUE);
	EXEC DBMS_STATS.gather_table_stats('BDII_TEAM1', 'PAYMENT_ORDER', cascade => TRUE);
	EXEC DBMS_STATS.gather_table_stats('BDII_TEAM1', 'SUPPLIER', cascade => TRUE);

	/* Index Statistics */
	EXEC DBMS_STATS.gather_index_stats('BDII_TEAM1', 'HOTEL_STATEMENT_PK');
	EXEC DBMS_STATS.gather_index_stats('BDII_TEAM1', 'HOTEL_STATEMENT_RECORD_LOCATOR');
	EXEC DBMS_STATS.gather_index_stats('BDII_TEAM1', 'PAYMENT_ORDER_PK');
	EXEC DBMS_STATS.gather_index_stats('BDII_TEAM1', 'PAYMENT_ORDER_RECORD_LOCATOR');
	EXEC DBMS_STATS.gather_index_stats('BDII_TEAM1', 'PO2_IDX');
	EXEC DBMS_STATS.gather_index_stats('BDII_TEAM1', 'STATUS_ID_IDX');
	EXEC DBMS_STATS.gather_index_stats('BDII_TEAM1', 'SUPPLIER_PK');

	DELETE FROM PLAN_TABLE;

	/* --------------------------------------------------------------------- */
	/* CHANGED! */
	EXPLAIN PLAN
		SET STATEMENT_ID = 'UPDATE-3:SELECT-1'
		INTO PLAN_TABLE FOR
			select /*+ MERGE */
				po.ID, po.TOTAL_COST, po.TOTAL_COST_CURRENCY,
				po.CHECKIN, po.CHECKOUT
			from PAYMENT_ORDER po, SUPPLIER s
			where po.supplier_id = 9
				and po.supplier_id = s.id
				and po.record_locator = 'bbgtid'
				and po.id NOT IN (
					SELECT payment_order_id
					FROM conciliation
					WHERE payment_order_id IS NOT NULL
				);
	/* --------------------------------------------------------------------- */
	/* CHANGED! */
	EXPLAIN PLAN
		SET STATEMENT_ID = 'UPDATE-3:INSERT-CONCILIATION'
		INTO PLAN_TABLE FOR
			INSERT INTO CONCILIATION (
				ID, HOTEL_STATEMENT_ID, PAYMENT_ORDER_ID,
				CONCILIATED_AMOUNT, CONCILIATED_AMOUNT_CURRENCY,
				ADJUSTMENT_AMOUNT, ADJUSTMENT_AMOUNT_CURRENCY,
				STATUS_ID, CREATED, MODIFIED)
				VALUES (
					CONCILIATION_SEQ.nextval, '1',
					null, null, null, null, null,
					1, sysdate, sysdate);
	/* --------------------------------------------------------------------- */
	/* CHANGED! */
	EXPLAIN PLAN
		SET STATEMENT_ID = 'UPDATE-3:SELECT-4'
		INTO PLAN_TABLE FOR
			SELECT
				hs.ID, hs.SUPPLIER_ID, hs.RECORD_LOCATOR, hs.AMOUNT,
				hs.CURRENCY, s.CONCILIATION_TOLERANCE_PERC,
				s.CONCILIATION_TOLERANCE_MAX
			FROM hotel_statement hs
			JOIN supplier s ON s.ID = hs.SUPPLIER_ID
			WHERE hs.id NOT IN (
				SELECT hotel_statement_id
				FROM conciliation
			);
	/* --------------------------------------------------------------------- */

	/* Mostrar las estadísticas de los planes explicados */
	@view_plans.sql

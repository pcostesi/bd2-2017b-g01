
	/**
	* CBO Explain for UPDATE-4:
	*		"(N + 1) Anti-pattern Fix"
	*/

	/* Resultados:

	STATEMENT_ID                         COST    IO_COST   CPU_COST      BYTES CARDINALITY
	------------------------------ ---------- ---------- ---------- ---------- -----------
	UPDATE-4:INSERT-CONCILIATION            1          1          0        100           1
	UPDATE-4:SELECT-1                       0          0          0          0           0	CHANGED!
	UPDATE-4:SELECT-2                       0          0          0          0           0
	UPDATE-4:SELECT-3                       0          0          0          0           0
	UPDATE-4:SELECT-4                    4716       4696  369925906     114072        1164	CHANGED!
	UPDATE-4:UPDATE-HOTEL_STATE             0          0          0          0           0
	UPDATE-4:UPDATE-PAYMENT_ORDER           0          0          0          0           0
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
	EXPLAIN PLAN
		SET STATEMENT_ID = 'UPDATE-4:INSERT-CONCILIATION'
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
		SET STATEMENT_ID = 'UPDATE-4:SELECT-4'
		INTO PLAN_TABLE FOR
			SELECT
				hs.ID, hs.SUPPLIER_ID, hs.RECORD_LOCATOR, hs.AMOUNT,
				hs.CURRENCY, s.CONCILIATION_TOLERANCE_PERC,
				s.CONCILIATION_TOLERANCE_MAX, po.ID vPoId, po.TOTAL_COST,
				po.TOTAL_COST_CURRENCY, po.CHECKIN, po.CHECKOUT
			FROM hotel_statement hs
			JOIN supplier s ON s.ID = hs.SUPPLIER_ID
			LEFT JOIN payment_order po ON (
				po.RECORD_LOCATOR = hs.RECORD_LOCATOR
					AND po.supplier_id = hs.supplier_id
					AND po.id NOT IN (
						SELECT payment_order_id
						FROM conciliation
						WHERE payment_order_id IS NOT NULL
					)
			)
			WHERE hs.id NOT IN (
				SELECT hotel_statement_id
				FROM conciliation
			);
	/* --------------------------------------------------------------------- */

	/* Mostrar las estadísticas de los planes explicados */
	@view_plans.sql

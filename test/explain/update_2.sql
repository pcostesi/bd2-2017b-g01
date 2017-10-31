
	/**
	* CBO Explain for UPDATE-2:
	*		"Drop Conciliate Statement PSM"
	*/

	/* Resultados:

	STATEMENT_ID                         COST    IO_COST   CPU_COST      BYTES CARDINALITY
	------------------------------ ---------- ---------- ---------- ---------- -----------
	UPDATE-2:INSERT-CONCILIATION            1          1          0        100           1
	UPDATE-2:SELECT-1                       2          2      11747         61           1
	UPDATE-2:SELECT-2                       0          0          0          0           0	CHANGED!
	UPDATE-2:SELECT-3                       0          0          0          0           0	CHANGED!
	UPDATE-2:SELECT-4                      39         38   11341159       2844          12	CHANGED!
	UPDATE-2:UPDATE-HOTEL_STATE             2          2      11651        216           1
	UPDATE-2:UPDATE-PAYMENT_ORDER           2          2      11731         59           1
	*/

	ALTER SESSION SET OPTIMIZER_MODE = CHOOSE;

	/* Table Statistics */
	EXEC DBMS_STATS.gather_table_stats('BDII_TEAM1', 'HOTEL_STATEMENT', cascade => TRUE);
	EXEC DBMS_STATS.gather_table_stats('BDII_TEAM1', 'PAYMENT_ORDER', cascade => TRUE);
	EXEC DBMS_STATS.gather_table_stats('BDII_TEAM1', 'SUPPLIER', cascade => TRUE);

	/* Index Statistics */
	EXEC DBMS_STATS.gather_index_stats('BDII_TEAM1', 'HOTEL_STATEMENT_PK');
	EXEC DBMS_STATS.gather_index_stats('BDII_TEAM1', 'HOTEL_STATEMENT_RECORD_LOCATOR');
	EXEC DBMS_STATS.gather_index_stats('BDII_TEAM1', 'PAYMENT_ORDER_PK');
	EXEC DBMS_STATS.gather_index_stats('BDII_TEAM1', 'PAYMENT_ORDER_RECORD_LOCATOR');
	EXEC DBMS_STATS.gather_index_stats('BDII_TEAM1', 'PO1_IDX');
	EXEC DBMS_STATS.gather_index_stats('BDII_TEAM1', 'PO2_IDX');
	EXEC DBMS_STATS.gather_index_stats('BDII_TEAM1', 'PO3_IDX');
	EXEC DBMS_STATS.gather_index_stats('BDII_TEAM1', 'SUPPLIER_PK');

	DELETE FROM PLAN_TABLE;

	/* --------------------------------------------------------------------- */
	EXPLAIN PLAN
		SET STATEMENT_ID = 'UPDATE-2:SELECT-1'
		INTO PLAN_TABLE FOR
			select /*+ MERGE */
				po.ID, po.TOTAL_COST, po.TOTAL_COST_CURRENCY,
				po.STATUS, po.CHECKIN, po.CHECKOUT
			from PAYMENT_ORDER po, SUPPLIER s
			where po.supplier_id = 9
				and po.supplier_id = s.id
				and po.record_locator = 'bbgtid'
				and rtrim(ltrim(po.status)) = 'PENDING';
	/* --------------------------------------------------------------------- */
	EXPLAIN PLAN
		SET STATEMENT_ID = 'UPDATE-2:INSERT-CONCILIATION'
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
		SET STATEMENT_ID = 'UPDATE-2:UPDATE-HOTEL_STATE'
		INTO PLAN_TABLE FOR
			UPDATE HOTEL_STATEMENT SET STATUS = 'CHECKOUT_PENDING', MODIFIED = SYSDATE
			WHERE ID = '1';
	/* --------------------------------------------------------------------- */
	EXPLAIN PLAN
		SET STATEMENT_ID = 'UPDATE-2:UPDATE-PAYMENT_ORDER'
		INTO PLAN_TABLE FOR
			UPDATE PAYMENT_ORDER SET STATUS = 'CONCILIATED', MODIFIED = SYSDATE
			WHERE ID = '1';
	/* --------------------------------------------------------------------- */
	/* CHANGED! */
	EXPLAIN PLAN
		SET STATEMENT_ID = 'UPDATE-2:SELECT-4'
		INTO PLAN_TABLE FOR
			SELECT
				hs.ID, hs.SUPPLIER_ID, hs.RECORD_LOCATOR, hs.AMOUNT,
				hs.CURRENCY, s.CONCILIATION_TOLERANCE_PERC,
				s.CONCILIATION_TOLERANCE_MAX
			FROM hotel_statement hs
			JOIN supplier s ON s.ID = hs.SUPPLIER_ID
			WHERE LTRIM(RTRIM(hs.STATUS)) = 'PENDING';
	/* --------------------------------------------------------------------- */

	/* Mostrar las estadísticas de los planes explicados */
	@view_plans.sql

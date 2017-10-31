
	/**
	* Aplica el UPDATE-4 y prepara el sistema para el despliegue final, lo que
	* implica reconstruir los índices con el estado actual, y computar las
	* estadísticas completas sobre todas las tablas para mejorar el CBO.
	*/

	@4_n+1AntipatternFix.sql

	/* Index Rebuild */
	ALTER INDEX HOTEL_STATEMENT_PK REBUILD;
	ALTER INDEX HOTEL_STATEMENT_RECORD_LOCATOR REBUILD;
	ALTER INDEX PAYMENT_ORDER_PK REBUILD;
	ALTER INDEX PAYMENT_ORDER_RECORD_LOCATOR REBUILD;
	ALTER INDEX PO2_IDX REBUILD;
	ALTER INDEX STATUS_ID_IDX REBUILD;
	ALTER INDEX SUPPLIER_PK REBUILD;

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

-- autoextend tablespaces
ALTER DATABASE DATAFILE '$ORACLE_HOME/dbs/team1_data.ora'
    AUTOEXTEND ON;
ALTER DATABASE DATAFILE '$ORACLE_HOME/dbs/team1_indexes.ora'
    AUTOEXTEND ON;

-- remove unneeded STATEMENT_LOCATOR in CONCILIATION.
ALTER TABLE CONCILIATION
    DROP COLUMN STATEMENT_LOCATOR;

-- enforce upper case so we don't need to check it on PKG.
ALTER TABLE HOTEL_STATEMENT
    ADD CONSTRAINT HS_RECORD_LOCATOR_UPPER
        CHECK (upper(RECORD_LOCATOR) = RECORD_LOCATOR);
CREATE UNIQUE INDEX HOTEL_STATEMENT_RECORD_LOCATOR
    ON HOTEL_STATEMENT(RECORD_LOCATOR)
    TABLESPACE TEAM1_INDEXES;

ALTER TABLE PAYMENT_ORDER
    ADD CONSTRAINT PO_RECORD_LOCATOR_UPPER
        CHECK (upper(RECORD_LOCATOR) = RECORD_LOCATOR);
CREATE UNIQUE INDEX PAYMENT_ORDER_RECORD_LOCATOR
    ON PAYMENT_ORDER(RECORD_LOCATOR)
    TABLESPACE TEAM1_INDEXES;

-- remove unneeded STATEMENT_LOCATOR in HOTEL_STATEMENT.
ALTER TABLE HOTEL_STATEMENT
    DROP COLUMN STATEMENT_LOCATOR;

-- better STATUS management
CREATE TABLE CONCILIATION_STATUS (
    "ID" NUMBER(1,0),
    "NAME" CHAR(20 BYTE),
    PRIMARY KEY ("ID") ENABLE
) TABLESPACE TEAM1_DATA;

INSERT INTO CONCILIATION_STATUS VALUES (1, 'CHECKOUT_PENDING');
INSERT INTO CONCILIATION_STATUS VALUES (2, 'WRONG_CURRENCY');
INSERT INTO CONCILIATION_STATUS VALUES (3, 'ERROR_TOLERANCE');
INSERT INTO CONCILIATION_STATUS VALUES (4, 'NOT_FOUND');
INSERT INTO CONCILIATION_STATUS VALUES (5, 'CONCILIATED');

ALTER TABLE CONCILIATION
    ADD STATUS_ID NUMBER(1,0);

-- Necesario para poder crear un BITMAP INDEX en una IOT
ALTER TABLE CONCILIATION MOVE MAPPING TABLE;

CREATE BITMAP INDEX STATUS_ID_IDX ON CONCILIATION(STATUS_ID)
    TABLESPACE TEAM1_INDEXES;
ALTER TABLE CONCILIATION
    ADD CONSTRAINT STATUS_ID_FK
        FOREIGN KEY (STATUS_ID) REFERENCES CONCILIATION_STATUS(ID);
ALTER TABLE CONCILIATION
    DROP COLUMN STATUS;

ALTER TABLE HOTEL_STATEMENT
    DROP COLUMN STATUS;

ALTER TABLE PAYMENT_ORDER
    DROP COLUMN STATUS;

-- BDII_TEAM1 no tiene privilegios para crear vistas.
-- descomentar cuando los tenga.
/*CREATE OR REPLACE VIEW CONCILIATION_WS AS
    SELECT
    c.ID, c.HOTEL_STATEMENT_ID, c.PAYMENT_ORDER_ID,
    c.CONCILIATED_AMOUNT, c.CONCILIATED_AMOUNT_CURRENCY,
    c.ADJUSTMENT_AMOUNT, c.ADJUSTMENT_AMOUNT_CURRENCY,
    cs.NAME STATUS, c.CREATED, c.MODIFIED
    FROM CONCILIATION c
    JOIN CONCILIATION_STATUS cs ON cs.ID = c.STATUS_ID;

CREATE OR REPLACE VIEW HOTEL_STATEMENT_WS AS
    SELECT
    hs.ID, hs.RECORD_LOCATOR, hs.SUPPLIER_ID, hs.AMOUNT,
    hs.CURRENCY, COALESCE(c.STATUS, 'PENDING') STATUS,
    hs.CREATED, COALESCE(GREATEST(hs.MODIFIED, c.MODIFIED), hs.MODIFIED) MODIFIED
    FROM HOTEL_STATEMENT hs
    LEFT JOIN CONCILIATION_WS c ON c.HOTEL_STATEMENT_ID = hs.ID;

CREATE OR REPLACE VIEW PAYMENT_ORDER_WS AS
    SELECT
    po.ID, po.RECORD_LOCATOR, po.SUPPLIER_ID,
    po.TOTAL_AMOUNT, po.TOTAL_AMOUNT_CURRENCY,
    po.TOTAL_COST, po.TOTAL_COST_CURRENCY,
    COALESCE(c.STATUS, 'PENDING') STATUS, po.CHECKIN, po.CHECKOUT,
    po.CREATED, COALESCE(GREATEST(po.MODIFIED, c.MODIFIED), po.MODIFIED) MODIFIED
    FROM PAYMENT_ORDER po
    LEFT JOIN CONCILIATION_WS c ON c.PAYMENT_ORDER_ID = po.ID;*/

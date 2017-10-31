--------------------------------------------------------
--  DDL for Index PO2_IDX
--------------------------------------------------------

  CREATE INDEX "BDII_TEAM1"."PO2_IDX" ON "BDII_TEAM1"."PAYMENT_ORDER" ("ID", "RECORD_LOCATOR", "SUPPLIER_ID") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 10240 NEXT 36864 MINEXTENTS 1 MAXEXTENTS 121
  PCTINCREASE 50 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE TEAM1_INDEXES;
--------------------------------------------------------
--  DDL for Index SUPPLIER_PK
--------------------------------------------------------

  CREATE UNIQUE INDEX "BDII_TEAM1"."SUPPLIER_PK" ON "BDII_TEAM1"."SUPPLIER" ("ID") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 10240 NEXT 10240 MINEXTENTS 1 MAXEXTENTS 121
  PCTINCREASE 50 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE TEAM1_INDEXES;
--------------------------------------------------------
--  DDL for Index PAYMENT_ORDER_PK
--------------------------------------------------------

  CREATE UNIQUE INDEX "BDII_TEAM1"."PAYMENT_ORDER_PK" ON "BDII_TEAM1"."PAYMENT_ORDER" ("ID") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 10240 NEXT 24576 MINEXTENTS 1 MAXEXTENTS 121
  PCTINCREASE 50 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE TEAM1_INDEXES;
--------------------------------------------------------
--  DDL for Index HOTEL_STATEMENT_PK
--------------------------------------------------------

  CREATE UNIQUE INDEX "BDII_TEAM1"."HOTEL_STATEMENT_PK" ON "BDII_TEAM1"."HOTEL_STATEMENT" ("ID") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 10240 NEXT 24576 MINEXTENTS 1 MAXEXTENTS 121
  PCTINCREASE 50 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE TEAM1_INDEXES;
--------------------------------------------------------
--  DDL for Index PO3_IDX
--------------------------------------------------------

  CREATE INDEX "BDII_TEAM1"."PO3_IDX" ON "BDII_TEAM1"."PAYMENT_ORDER" ("STATUS", "CREATED", "MODIFIED", "SUPPLIER_ID") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 10240 NEXT 126976 MINEXTENTS 1 MAXEXTENTS 121
  PCTINCREASE 50 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE TEAM1_INDEXES;
--------------------------------------------------------
--  DDL for Index PO1_IDX
--------------------------------------------------------

  CREATE INDEX "BDII_TEAM1"."PO1_IDX" ON "BDII_TEAM1"."PAYMENT_ORDER" ("CHECKOUT", "STATUS") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 10240 NEXT 83968 MINEXTENTS 1 MAXEXTENTS 121
  PCTINCREASE 50 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE TEAM1_INDEXES;

create or replace PACKAGE BODY CONCILIATE_PKG AS

  -- Conciliacion de una reserva
  PROCEDURE conciliate_booking ( pHsId NUMBER, pSupplier NUMBER, pRecordLocator VARCHAR,
                   pAmount NUMBER, pCurrency VARCHAR, vTolPercentage NUMBER, vTolMax NUMBER ) AS
    vPoId NUMBER(10);
    vAmount NUMBER(10,2);
    vCurrency CHAR(3);
    vCheckinDate DATE;
    vCheckoutDate DATE;
  BEGIN
    dbms_output.put_line('Conciliate_booking - pHsId: ' || pHsId || ' pSupplier: ' || pSupplier || ' pRecordLocator: ' || pRecordLocator);

      -- Buscar la PO asociada
      select /*+MERGE*/ po.ID, po.TOTAL_COST, po.TOTAL_COST_CURRENCY, po.CHECKIN, po.CHECKOUT
      into vPoId, vAmount, vCurrency, vCheckinDate, vCheckoutDate
      from PAYMENT_ORDER po, SUPPLIER s
      where po.supplier_id = pSupplier
      and po.supplier_id = s.id
      and po.record_locator = pRecordLocator
      and po.id NOT IN (
        SELECT payment_order_id
        FROM conciliation
        WHERE payment_order_id IS NOT NULL
      );

      dbms_output.put_line('vPoId: ' || vPoId);

      -- Si no paso la fecha de checkout no se puede pagar aun
      IF vCheckOutDate>SYSDATE THEN
          -- Registrar que la reserva aun no puede conciliarse por estar pendiente su fecha de checkout
          dbms_output.put_line('    Checkout Pending');
          INSERT INTO CONCILIATION (
              ID, HOTEL_STATEMENT_ID, PAYMENT_ORDER_ID,
              CONCILIATED_AMOUNT, CONCILIATED_AMOUNT_CURRENCY, 
              ADJUSTMENT_AMOUNT, ADJUSTMENT_AMOUNT_CURRENCY,
              STATUS_ID, CREATED, MODIFIED)
          VALUES (CONCILIATION_SEQ.nextval, pHsId, null,
              null, null, null, null,
              C_STATUS_CHECKOUT_PENDING,sysdate,sysdate);
      -- Si la moneda de conciliacion y la del hotelero no coinciden
      ELSIF vCurrency NOT LIKE pCurrency THEN
          -- Registrar que la moneda indicada en el extracto no es la correcta
          dbms_output.put_line('    Wrong Currency');
          INSERT INTO CONCILIATION (
              ID, HOTEL_STATEMENT_ID, PAYMENT_ORDER_ID,
              CONCILIATED_AMOUNT, CONCILIATED_AMOUNT_CURRENCY, 
              ADJUSTMENT_AMOUNT, ADJUSTMENT_AMOUNT_CURRENCY,
              STATUS_ID, CREATED, MODIFIED)
          VALUES (CONCILIATION_SEQ.nextval, pHsId, null,
              null, null, null, null,
              C_STATUS_WRONG_CURRENCY,sysdate,sysdate);
      -- Si el monto solicitado por el hotelero esta dentro de los limites de tolerancia
      ELSIF ( ((vAmount-pAmount)<((vTolPercentage/100)*pAmount)) AND ((vAmount-pAmount)<vTolMax) ) THEN
          -- Registrar que se aprueba la conciliacion de la reserva
          dbms_output.put_line('    Conciliated');
          INSERT INTO CONCILIATION (
              ID, HOTEL_STATEMENT_ID, PAYMENT_ORDER_ID,
              CONCILIATED_AMOUNT, CONCILIATED_AMOUNT_CURRENCY, 
              ADJUSTMENT_AMOUNT, ADJUSTMENT_AMOUNT_CURRENCY,
              STATUS_ID, CREATED, MODIFIED)
          VALUES (CONCILIATION_SEQ.nextval, pHsId, vPoId,
              pAmount, pCurrency, round(vAmount-pAmount,2), pCurrency,
              C_STATUS_CONCILIATED,sysdate,sysdate);
      -- Si el monto solicitado por el hotelero no esta dentro de los limites de tolerancia
      ELSE
          -- Registrar que la reserva no puede conciliarse por diferencia de monto
          dbms_output.put_line('    Error Tolerance');
          INSERT INTO CONCILIATION (
              ID, HOTEL_STATEMENT_ID, PAYMENT_ORDER_ID,
              CONCILIATED_AMOUNT, CONCILIATED_AMOUNT_CURRENCY, 
              ADJUSTMENT_AMOUNT, ADJUSTMENT_AMOUNT_CURRENCY,
              STATUS_ID, CREATED, MODIFIED)
          VALUES (CONCILIATION_SEQ.nextval, pHsId, vPoId,
              pAmount, pCurrency, null, null,
              C_STATUS_ERROR_TOLERANCE,sysdate,sysdate);
      END IF;

  EXCEPTION
      WHEN NO_DATA_FOUND THEN
          -- Registrar que no se encontro una reserva de las caracteriticas que el hotelero indico
          dbms_output.put_line('    Not Found');
          INSERT INTO CONCILIATION (
              ID, HOTEL_STATEMENT_ID, PAYMENT_ORDER_ID,
              CONCILIATED_AMOUNT, CONCILIATED_AMOUNT_CURRENCY, 
              ADJUSTMENT_AMOUNT, ADJUSTMENT_AMOUNT_CURRENCY,
              STATUS_ID, CREATED, MODIFIED)
          VALUES (CONCILIATION_SEQ.nextval, pHsId, null,
              null, null, null, null,
              C_STATUS_NOT_FOUND,sysdate,sysdate);
  END conciliate_booking;

    -- Conciliacion de todos los extractos pendientes
    PROCEDURE conciliate_all_statements AS
    BEGIN
        -- Recorro los extractos pendientes
        FOR R IN (
            SELECT
                hs.ID, hs.SUPPLIER_ID, hs.RECORD_LOCATOR, hs.AMOUNT, hs.CURRENCY,
                s.CONCILIATION_TOLERANCE_PERC, s.CONCILIATION_TOLERANCE_MAX
            FROM hotel_statement hs
            JOIN supplier s ON s.ID = hs.SUPPLIER_ID
            WHERE hs.id NOT IN (
                SELECT hotel_statement_id
                FROM conciliation
            )
        ) LOOP
            -- Concilio una reserva
            conciliate_booking(
                R.ID,R.SUPPLIER_ID,R.RECORD_LOCATOR,R.AMOUNT,R.CURRENCY,
                R.CONCILIATION_TOLERANCE_PERC, R.CONCILIATION_TOLERANCE_MAX
            );
            -- El extracto debe procesarse completo
            COMMIT;
        END LOOP;
    END conciliate_all_statements;

END CONCILIATE_PKG;

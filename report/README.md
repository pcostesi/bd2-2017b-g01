# Trabajo Práctico Especial
> Bases de Datos 2

<!-- TOC -->

- [Trabajo Práctico Especial](#trabajo-práctico-especial)
    - [Integrantes](#integrantes)
    - [Objetivos](#objetivos)
    - [Análisis de la Solución](#análisis-de-la-solución)
        - [Problemas Encontrados](#problemas-encontrados)
        - [Optimizaciones Realizadas](#optimizaciones-realizadas)
    - [Resultados](#resultados)
        - [Plan de Ejecución](#plan-de-ejecución)
        - [Recomendaciones](#recomendaciones)

<!-- /TOC -->

## Integrantes

## Objetivos

## Análisis de la Solución

### Problemas Encontrados

#### Los tablespaces no son auto-extensibles

Los tablespaces `TEAM1_DATA` y `TEAM1_INDEXES` no son *autoextensibles*, por lo cual la generación de índices, las inserciones o el cálculo de nuevas conciliaciones acabarían bloqueando los procesos llevados a cabo por la empresa de turismo. Para solventar la falta de espacio físico, se alteraron las propiedades de ambos tablespaces mediante:

```
ALTER DATABASE DATAFILE '$ORACLE_HOME/dbs/team1_data.ora'
    AUTOEXTEND ON;

ALTER DATABASE DATAFILE '$ORACLE_HOME/dbs/team1_indexes.ora'
    AUTOEXTEND ON;
```

#### Supplier.status nunca se usa
En la tabla Supplier, existe el campo `status`. Este campo nunca es utilizado en el procedure por lo que en el caso de que exista algun registro que no sea `status='ACTIVE'`, no va a ser tenido en cuenta en el Procedure.

Se decidió no cambiar esta lógica porque el objetivo de esta trabajo es sólo performance.

### Optimizaciones Realizadas

#### REMOVER `STATEMENT_LOCATOR` de `conciliate_booking`
El procedure `conciliate_booking` recibe como primer parámetro `STATEMENT_LOCATOR` y en la tabla `CONCILIATION` se está guardando el mismo. Este parámetro carece de total sentido debido a que un `HOTEL_STATEMENT` posee ya una *Primary Key* (`HOTEL_STATEMENT.ID`). Además esta columna no posee indice (como sí posee la `PK`) y el tipo de la columna `CONCILIATION.STATEMENT_LOCATOR` es inconsistente con el de la columna `HOTEL_STATEMENT.STATEMENT_LOCATOR`.

Por todas estas razones se removió la columna `STATEMENT_LOCATOR` de `CONCILIATION` y se quitó el primer parámetro de `conciliate_booking` acordemente. (El segundo parámetro es la PK mencionada `pHsId`).

No se removió en el contexto de este cambio la columna `STATEMENT_LOCATOR` de `HOTEL_STATEMENT` porque luego en un cambio más grande esta columna sera removida por completo.

#### Columna RECORD_LOCATOR en PAYMENT_ORDER y HOTEL_STATEMENT

Una de las primeras mejoras analizadas fue la posibilidad de modificar el uso de RECORD_LOCATOR por directamente una referencia a la *Primary Key* como se muestra a continuación:
```
ALTER TABLE PAYMENT_ORDER
    ADD HOTEL_STATEMENT_ID NUMBER(10,0) REFERENCES HOTEL_STATEMENT(ID);

MERGE INTO PAYMENT_ORDER po
USING HOTEL_STATEMENT hs
ON (lower(po.RECORD_LOCATOR) = lower(hs.RECORD_LOCATOR))
WHEN MATCHED THEN UPDATE SET po.HOTEL_STATEMENT_ID = hs.ID;
```
Dado que una `PAYMENT_ORDER` se genera a partir de un `HOTEL_STATEMENT` en principio parece una buena solución.

Al analizar el resultado de esta query notamos que No existe una correlación 1 a 1 entre estas dos tablas. Existen códigos en `RECORD_LOCATOR` que existen en `PAYMENT_ORDER` y no en `HOTEL_STATEMENT` y viceversa. Esto sugiere que el concepto de `RECORD_LOCATOR` es de orden superior al de estas dos tablas, por ejemplo puede ser que una `PAYMENT_ORDER` se pueda relacionar con otros tipos de pagos que no sean `HOTEL_STATEMENT` en otros ámbitos y es por esto que decidimos mantener dicha columna.

Mantener esta columna de "incierto origen", requiere que se tenga mas cuidado con el cambio realizado, es por esto que se decidió agregar el siguiente código a nuestro update:
```
ALTER TABLE HOTEL_STATEMENT
    ADD CONSTRAINT HS_RECORD_LOCATOR_UPPER
        CHECK (upper(RECORD_LOCATOR) = RECORD_LOCATOR);
CREATE UNIQUE INDEX HOTEL_STATEMENT_RECORD_LOCATOR
    ON HOTEL_STATEMENT(RECORD_LOCATOR);

ALTER TABLE PAYMENT_ORDER
    ADD CONSTRAINT PO_RECORD_LOCATOR_UPPER
        CHECK (upper(RECORD_LOCATOR) = RECORD_LOCATOR);
CREATE UNIQUE INDEX PAYMENT_ORDER_RECORD_LOCATOR
    ON PAYMENT_ORDER(RECORD_LOCATOR);
```

De esta manera se mueve el chequeo de las mayúsculas a la hora del insert (en lugar de nuestro script de conciliación), podemos confiar en los datos y dejar de hacer consultas que no entran por índice.
A su vez se agregó el indice `UNIQUE` para garantizar que sea unívoco el acceso al mismo.

Éste último cambio nos lleva a pensar una limitación que tiene el sistema actual, el `RECORD_LOCATOR` es de tipo `CHAR(6 BYTE)`, la cardinalidad de este tipo es mucho menor a la de nuestras PKs de `NUMBER(10, 0)`, por lo que en algún momento el sistema se va a quedar sin RECORD_LOCATOR que generar. Se pensó en cambiar la columna de `RECORD_LOCATOR` por otra cosa, pero debido a que el origen de este dato es incierto se decidió dejarlo como está y hacer esta mención en el informe.

#### Eliminación completa del paso intermedio `conciliate_statement`

El script `conciliate_all_statements` estaba iterando por las rows de `hotel_statement` en  `STATUS='PENDING'` y luego en el `LOOP` invocando a `conciliate_statement` con un único parámetro `STATEMENT_LOCATOR`. Ya hemos mencionado la innecesidad de utilizar la columna `STATEMENT_LOCATOR`, la ausencia de indice en ella. Por último esta procedure hace una búsqueda del SUPPLIER para obtener los valores `vTolPercentage` y `vTolMax` para finalmente invocar a `conciliate_booking`.

Debido a que todo este paso intermedio es innecesario podemos remover la clausula `conciliate_statement` por completo como así también la columna `STATEMENT_LOCATOR` de `HOTEL_STATEMENT` y realizar directamente en `conciliate_all_statements` un LOOP conteniendo toda la información necesaria y llamar directamente a `conciliate_booking` desde allí:
```
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
        WHERE LTRIM(RTRIM(hs.STATUS)) = 'PENDING'
    ) LOOP
        -- Concilio una reserva
        dbms_output.put_line('  Conciliating booking '||R.RECORD_LOCATOR);
        conciliate_booking(
            R.ID,R.SUPPLIER_ID,R.RECORD_LOCATOR,R.AMOUNT,R.CURRENCY,
            R.CONCILIATION_TOLERANCE_PERC, R.CONCILIATION_TOLERANCE_MAX
        );
        -- El extracto debe procesarse completo
        COMMIT;
    END LOOP;
END conciliate_all_statements;
```

#### Conciliation STATUS
En la conciliación se utiliza el concepto de `STATUS`.
Las tablas `CONCILIATION`, `HOTEL_STATEMENT` y `PAYMENT_ORDER` todas poseen una columna `STATUS`, pero las mismas no tienen indice y tienen tipos diferentes. Además en el paquete se implementan condiciones que por mas de que haya un indice, no sería utilizado: `rtrim(ltrim(po.status)) = 'PENDING'`. Por último, nos llamó la atención que si bien las tablas `HOTEL_STATEMENT` y `PAYMENT_ORDER` tienen la columna STATUS, no parece tener sentido que esto sea así, dado que es un dato propio de la conciliación, evidencia de esto es que se replica el mismo valor de STATUS en todos las las tablas correspondientes (dependiendo del resultado).

Debido a que la cantidad de `STATUS` values esperados es limitada, se decidió utilizar `NUMBER(1, 0)` para el tipo de dato de la `PK` y se agregó un `BITMAP INDEX` en la tabla `CONCILIATION` para su utilización. Esto mejora tanto en size como en performance el chequeo de `STATUS`.

Por todo lo mencionado se decidió extraer el concepto de STATUS a una nueva tabla CONCILIATION_STATUS y reemplazar el `CHAR` type por una `PK` a la misma; de esta forma nos aseguramos que existe el indice, los tipos coinciden y no hace falta realizar transformaciones romo el `rtrim` y `ltrim`. Se creó una *vista* `CONCILIATION_WS` para que el usuario final pueda tener una experiencia similar a la anterior mostrando el `STATUS.NAME` en lugar de `STATUS_ID`.

Tambien se quitaron las columnas `STATUS` de `HOTEL_STATEMENT` y `PAYMENT_ORDER`, pero en esta dos no fue reemplazado por el `STATUS_ID` porque nos pareció irrelevante la información para estas tablas. No obstante se crearon las *vistas* `HOTEL_STATEMENT_WS` y `PAYMENT_ORDER_WS` que realizan el correspondiente `JOIN` a `CONCILIATION` para mostrar el estado correspondiente (si en la tabla `CONCILIATION` no hay un registro relacionado se muestra `'PENDING'`).

Por ultimo se destaca el cambio de condiciones de `WHERE ltrim(rtrim(...))` por ANTIJOINS en los siguientes casos:
`conciliate_all_statements`:
```
...
-            WHERE LTRIM(RTRIM(hs.STATUS)) = 'PENDING'
+            WHERE hs.id NOT IN (
+                SELECT hotel_statement_id
+                FROM conciliation
+            )
...
```

`conciliate_booking`:
```
...
-      and rtrim(ltrim(po.status)) = 'PENDING';
+      and po.id NOT IN (
+        SELECT payment_order_id
+        FROM conciliation
+        WHERE payment_order_id IS NOT NULL
+      );
...
```

#### Una sola query (resolviendo el problema N+1)

En esta etapa nos queda un script que hace dos operaciones:
1. Busca `HOTEL_STATEMENT`s en estado `PENDING` para analizar.
2. Por cada resultado en `HOTEL_STATEMENT` llama a `conciliate_booking`
    a. Busca las `PAYMENT_ORDER`s relacionadas a través de `RECORD_LOCATOR`.
    b. Realiza una serie de chequeos y graba en `CONCILIATION` el record con el resultado en base a diferentes escenarios posibles.

Este es un claro ejemplo del antipatrón N+1, primero hacemos una query de búsqueda (`1.`) y luego por cada resultado realizamos otra query para buscar mas información relacionada (`2.a`). Esto afecta a la perforance porque tener un quiebre desde la lógica del script no permite al motor de base de datos realizar las optimizaciones pertientes a la hora de buscar los datos todos juntos.

Para poder ir a buscar `PAYMENT_ORDER`s en la misma query original es importante destacar que tiene que hacerse a través de un `LEFT JOIN` porque nos interesa atrapar el caso de `NOT_FOUND` que se venia comprobando como una `EXCEPTION WHEN NO_DATA_FOUND`. En su lugar revisaremos cuando llegue un `NULL` en `vPoId` significa que no encontró la orden que queríamos.

Con este cambio nos quedan dos procedures en nuestra implementación final:
1. `CONCILIATE_PKG.conciliate_all_statements`. Es público (definido en el package) y realiza la query que levanta toda la infornación necesaría para la conciliación.
2. `CONCILIATE_PKG.conciliate_booking`. Es privada, recibe todos los parámetros necesarios para realizar una conciliación y contiene la lógica de negocio para definir si la conciliación es correcta guardando el resultado en la tabla `CONCILIATION`.

## Resultados

### Plan de Ejecución

### Recomendaciones

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

#### Permitir el uso de RECORD_LOCATOR

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
    ADD CONSTRAINT HOTEL_STATEMENT_RECORD_LOCATOR_UPPER
        CHECK (upper(RECORD_LOCATOR) = RECORD_LOCATOR);
CREATE UNIQUE INDEX HOTEL_STATEMENT_RECORD_LOCATOR_UNQ
    ON HOTEL_STATEMENT(RECORD_LOCATOR);

ALTER TABLE PAYMENT_ORDER
    ADD CONSTRAINT PAYMENT_ORDER_RECORD_LOCATOR_UPPER
        CHECK (upper(RECORD_LOCATOR) = RECORD_LOCATOR);
CREATE UNIQUE INDEX PAYMENT_ORDER_RECORD_LOCATOR_UNQ
    ON PAYMENT_ORDER(RECORD_LOCATOR);
```

De esta manera se mueve el chequeo de las mayúsculas a la hora del insert (en lugar de nuestro script de conciliación), podemos confiar en los datos y dejar de hacer consultas que no entran por índice.
A su vez se agregó el indice `UNIQUE` para garantizar que sea unívoco el acceso al mismo.

Éste último cambio nos lleva a pensar una limitación que tiene el sistema actual, el `RECORD_LOCATOR` es de tipo `CHAR(6 BYTE)`, la cardinalidad de este tipo es mucho menor a la de nuestras PKs de `NUMBER(10, 0)`, por lo que en algún momento el sistema se va a quedar sin RECORD_LOCATOR que generar. Se pensó en cambiar la columna de `RECORD_LOCATOR` por otra cosa, pero debido a que el origen de este dato es incierto se decidió dejarlo como está y hacer esta mención en el informe.

### Optimizaciones Realizadas

## Resultados

### Plan de Ejecución

### Recomendaciones

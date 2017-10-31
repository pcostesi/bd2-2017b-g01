
	/**
	* Este script permite destruir el contenido de ambos tablespaces asignados
	* al TEAM-1, para luego reconstruir su estado original. Esto permite
	* restaurar el esquema y su contenido por completo, sin importar el estado
	* de los mismos (salvo que se destruyan los tablespaces, aunque el usuario
	* BDII_TEAM1 carece de privilegios).
	*
	* @issue 1
	*	Se detectó que durante la reinserción de tuplas en las tablas, se
	*	generaba un error debido a falta de espacio en el tablespace TEAM_DATA,
	*	por lo cual se hizo necesario declarar al mismo como 'auto-extendible'.
	*
	* @issue 2
	*	El esquema exportado especificaba la cláusula USING INDEX para una
	*	PRIMARY KEY sobre la tabla CONCILIATION, lo cual es inválido en Oracle,
	*	ya que la tabla es declarada bajo ORGANIZATION INDEX.
	*/

	/* Tablespace ilimitado */
	ALTER DATABASE DATAFILE '$ORACLE_HOME/dbs/team1_data.ora'
		AUTOEXTEND ON;
	ALTER DATABASE DATAFILE '$ORACLE_HOME/dbs/team1_indexes.ora'
		AUTOEXTEND ON;

	/* Destruir el esquema completo */
	@../docker/db/x_reset.sql

	/* Eliminar el paquete temporal */
	DROP PACKAGE RESET_PKG;

	/* Reconstruir el esquema original */
	@builder/create_schema.sql

	/* Importar datos */
	@import_data.sql

	/* Construir índices */
	@builder/create_indexes.sql

	/* Construir PACKAGE y PSMs */
	@builder/create_package.sql

	/* Agregar restricciones */
	@builder/create_constraints.sql

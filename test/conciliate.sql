
	/**
	* Aplica el proceso de conciliación, según el estado actual de la base de
	* datos. No aplica ninguna preparación ni post-procesamiento del estado.
	*/
	EXECUTE CONCILIATE_PKG.conciliate_all_statements();

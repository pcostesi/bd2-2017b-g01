
	/**
	* Aplica el proceso de conciliación, según el estado actual de la base de
	* datos. No aplica ninguna preparación ni post-procesamiento del estado.
	*/
	EXECUTE CONCILIATE_PKG.conciliate_all_statements();

		/* Los tiempos de ejecución fueron:
		*
		*	BASE TIME: 2.272, 2.546, 2.246, 2.062 -> Average = 2.282 sec.
		*
		*	UPDATE 0: 2.644, 1.422, 1.547, 1.297 -> Average = 1.728 sec.
		*	UPDATE 1: 1.579, 1.368, 1.351, 1.313 -> Average = 1.403 sec.
		*	UPDATE 2: 1.796, 1.843, 1.610, 1.547 -> Average = 1.699 sec.
		*	UPDATE 3: 1.594, 1.062, 1.407, 1.249 -> Average = 1.328 sec.
		*	UPDATE 4: 0.734, 1.438, 1.140, 1.375 -> Average = 1.172 sec.
		*	UPDATE 5:
		*/

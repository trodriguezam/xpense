# TODO

## Hecho
- [x] Arreglar localizacion — catálogo `.xcstrings` completado (es/en), fix de `%lld`, frases de Siri. Todo el texto sigue el idioma del sistema.
- [x] Mostrar categorias con progreso diferenciadas de las sin progreso — las con límite muestran barra; las sin límite van atenuadas y con "sin límite".
- [x] swipe to delete de gastos en home — botón ahora pegado a la fila, alto completo (fila con fondo `superficie`, sin tarjeta flotante).
- [x] agregar swipe to delete a categorias — vía `swipeEliminar` (todas, incluidas las base).
- [x] gastos apretables en todas partes — el detalle de categoría ahora abre el editor al tocar un gasto.
- [x] todas las categorias editables/borrables — nombre, ícono y color editables en el detalle; borrar disponible para todas (el seed solo re-crea si hay 0 categorías).
- [x] Agregar iconos para categorias — selector de íconos (carrusel) en crear y editar.
- [x] agregar colores para categorias y transformar en carrusel — `SelectorIconoColor` reutilizable (íconos + colores en carrusel horizontal).

## Grupos compartidos — casi listo (falta probar en hardware)
- [x] UI de invitar — botón **"Invitar personas"** en el detalle del grupo, con `UICloudSharingController` (`CloudSharingSheet.swift`). Crea/espeja el grupo (`Grupo.idCompartido` ↔ `GrupoCompartidoMO`) y presenta la hoja. En simulador (sin iCloud) avisa con calma, no se cae.
- [ ] Reflejar gastos en el pozo compartido — crear `AporteCompartido` al guardar un gasto que aporta, y que `MotorPresupuesto.pozo` lea del store compartido cuando el grupo está compartido (hoy el pozo es local).
- [ ] **Probar el sync real en 2 dispositivos** con 2 Apple IDs (CKShare no corre en simulador). Ver `docs/grupos-compartidos.md` › Plan de prueba.

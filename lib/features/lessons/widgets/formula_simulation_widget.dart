// The real implementation now lives in the correctly-owned module per
// docs/MODULE_OWNERSHIP.md (TV3 owns `lib/features/formula_simulation`).
// This re-export keeps `lesson_screen.dart`'s existing import working
// unchanged.
export '../../formula_simulation/widgets/formula_simulation_widget.dart';

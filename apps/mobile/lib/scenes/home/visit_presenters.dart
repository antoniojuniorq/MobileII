import 'package:ace_core/ace_core.dart';
import 'package:ace_design_system/ace_design_system.dart';

/// Tradução entre o status da API (Core) e o status visual (Design System).
AceStatus aceStatusOf(VisitStatus s) => switch (s) {
      VisitStatus.pendente => AceStatus.pendente,
      VisitStatus.visitado => AceStatus.visitado,
      VisitStatus.fechado => AceStatus.fechado,
      VisitStatus.recusado => AceStatus.recusado,
      VisitStatus.recuperado => AceStatus.recuperado,
      VisitStatus.comFoco => AceStatus.comFoco,
    };

VisitStatus visitStatusOf(AceStatus s) => switch (s) {
      AceStatus.pendente => VisitStatus.pendente,
      AceStatus.visitado => VisitStatus.visitado,
      AceStatus.fechado => VisitStatus.fechado,
      AceStatus.recusado => VisitStatus.recusado,
      AceStatus.recuperado => VisitStatus.recuperado,
      AceStatus.comFoco => VisitStatus.comFoco,
    };

String visitDetail(Visit v) => '${v.quadra} · ${v.horario ?? 'a visitar'}';

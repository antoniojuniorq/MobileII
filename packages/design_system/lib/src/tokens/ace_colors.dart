import 'package:flutter/material.dart';

/// Cores primitivas do ACE CONTROL (v3, "Frost and slate").
///
/// Paleta escolhida pela Taste Skill para serviços de saúde: fundo gelo,
/// tinta ardósia e um petróleo como cor de ação. O vermelho, o verde e o cinza
/// ficam reservados para a situação dos lotes, então a marca não usa nenhum
/// deles. Contraste alto para uso a pé, sob sol forte.
///
/// Telas e componentes NÃO devem usar estas constantes diretamente;
/// usem o tema (`Theme.of(context)`) e `context.ace`.
abstract final class AceColors {
  // Petróleo (ação, foco, marca)
  static const teal50 = Color(0xFFE3F1F2);
  static const teal100 = Color(0xFFC4E2E5);
  static const teal300 = Color(0xFF63C3CC);
  static const teal600 = Color(0xFF0D7480);
  static const teal700 = Color(0xFF0A5C66);
  static const teal900 = Color(0xFF062F34);

  // Âmbar (atenção pontual)
  static const amber500 = Color(0xFFF2A93B);
  static const amber900 = Color(0xFF2B1A00);

  // Ardósia - tema claro
  static const ink900 = Color(0xFF1F3038);
  static const ink600 = Color(0xFF4B5D66);
  static const ink300 = Color(0xFF8FA0A8);
  static const line = Color(0xFFDCE3E7);
  static const frost50 = Color(0xFFF7F9FA);
  static const frost100 = Color(0xFFECF0F2);
  static const white = Color(0xFFFFFFFF);

  // Ardósia - tema escuro
  static const night950 = Color(0xFF0E171B);
  static const night900 = Color(0xFF142127);
  static const night800 = Color(0xFF1B2B32);
  static const night600 = Color(0xFF2A3E47);
  static const night300 = Color(0xFF9FB1B9);
  static const night50 = Color(0xFFE8EFF2);

  // Erro
  static const red600 = Color(0xFFB3261E);
  static const red300 = Color(0xFFF5A5A2);
}

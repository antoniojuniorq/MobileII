import 'package:ace_control_app/scenes/shared/lot_visit_view_model.dart';
import 'package:ace_core/ace_core.dart';
import 'package:flutter_test/flutter_test.dart';

const _pendente = Lote(
  id: 'QI02-L03',
  numero: '3',
  poly: [(x: 0, y: 0), (x: 7, y: 0), (x: 7, y: 13), (x: 0, y: 13)],
  status: LoteStatus.pendente,
);

void main() {
  test('sem resultado escolhido não salva e pede a escolha', () async {
    var chamadas = 0;
    final vm = LotVisitViewModel(
      lote: _pendente,
      salvar: (_, __) async {
        chamadas++;
        return null;
      },
    );
    await vm.salvar();
    expect(vm.error, 'Escolha o resultado da visita.');
    expect(chamadas, 0);
    expect(vm.saved, isFalse);
  });

  test('visitado envia as quatro contagens', () async {
    Achados? enviado;
    final vm = LotVisitViewModel(
      lote: _pendente,
      salvar: (r, a) async {
        enviado = a;
        return null;
      },
    );
    vm.escolher(ResultadoVisita.visitado);
    vm.setCriadouros(2);
    vm.setLarvas(15);
    vm.setFocos(1);
    await vm.salvar();
    expect(vm.saved, isTrue);
    expect(enviado!.criadouros, 2);
    expect(enviado!.larvas, 15);
    expect(enviado!.focos, 1);
  });

  test('recusa envia contagens zeradas', () async {
    Achados? enviado;
    final vm = LotVisitViewModel(
      lote: _pendente,
      salvar: (r, a) async {
        enviado = a;
        return null;
      },
    );
    vm.escolher(ResultadoVisita.visitado);
    vm.setLarvas(9);
    vm.escolher(ResultadoVisita.recusado);
    await vm.salvar();
    expect(enviado!.larvas, 0);
  });

  test('erro da API fica na tela e permite tentar de novo', () async {
    final vm = LotVisitViewModel(
      lote: _pendente,
      salvar: (_, __) async => 'Sem conexão com o servidor.',
    );
    vm.escolher(ResultadoVisita.recusado);
    await vm.salvar();
    expect(vm.error, 'Sem conexão com o servidor.');
    expect(vm.saving, isFalse);
    expect(vm.saved, isFalse);
  });

  test('sem função de salvar é só leitura (supervisor)', () async {
    final vm = LotVisitViewModel(lote: _pendente);
    expect(vm.readOnly, isTrue);
    vm.escolher(ResultadoVisita.visitado);
    expect(vm.resultado, isNull);
  });
}

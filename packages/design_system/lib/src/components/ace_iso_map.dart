import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/ace_theme.dart';
import '../tokens/ace_spacing.dart';
import '../tokens/ace_status.dart';

/// Um lote no mapa: o contorno da planta (x para leste, y para sul).
@immutable
class AceIsoLot {
  const AceIsoLot({
    required this.id,
    required this.polygon,
    required this.status,
    required this.label,
  });

  final String id;
  final List<Offset> polygon;
  final AceLotStatus status;

  /// Número mostrado sobre o bloco quando o mapa está aproximado.
  final String label;
}

/// Um grupo de lotes (quadra interna) para aproximar de uma vez.
@immutable
class AceIsoGroup {
  const AceIsoGroup({required this.id, required this.label, required this.bounds});

  final String id;
  final String label;
  final Rect bounds;
}

enum AceIsoAreaKind { park, building }

/// Área sem lotes: praça (verde, plana) ou equipamento público (bloco baixo).
@immutable
class AceIsoArea {
  const AceIsoArea({required this.label, required this.polygon, required this.kind});

  final String label;
  final List<Offset> polygon;
  final AceIsoAreaKind kind;
}

/// Pede ao mapa para aproximar um grupo ou voltar à quadra inteira.
class AceIsoMapController extends ChangeNotifier {
  String? _focus;
  bool _reset = false;

  String? get focusedGroup => _focus;

  void focusGroup(String id) {
    _focus = id;
    _reset = false;
    notifyListeners();
  }

  void showAll() {
    _focus = null;
    _reset = true;
    notifyListeners();
  }
}

/// Mapa 3D da quadra, fiel à planta: cada lote é o seu contorno levantado como
/// um bloco liso, pintado pela situação (vermelho, verde ou cinza).
///
/// Vista inclinada com o norte para cima, como a planta da Prefeitura. Pinça e
/// arrasto aproximam. Afastado, tocar num conjunto aproxima o conjunto;
/// aproximado, tocar num bloco chama [onLotTap].
class AceIsoMap extends StatefulWidget {
  const AceIsoMap({
    super.key,
    required this.lots,
    required this.worldWidth,
    required this.worldHeight,
    this.groups = const [],
    this.areas = const [],
    this.selectedLotId,
    this.onLotTap,
    this.onGroupFocused,
    this.controller,
    this.interactive = true,
    this.showLabels = true,
    this.semanticLabel = 'Mapa 3D da quadra',
  });

  final List<AceIsoLot> lots;
  final List<AceIsoGroup> groups;
  final List<AceIsoArea> areas;
  final double worldWidth;
  final double worldHeight;
  final String? selectedLotId;
  final ValueChanged<AceIsoLot>? onLotTap;
  final ValueChanged<AceIsoGroup?>? onGroupFocused;
  final AceIsoMapController? controller;

  /// `false` desenha só a imagem (sem toque, pinça ou arrasto).
  final bool interactive;

  /// Números dos lotes e nomes dos conjuntos ao aproximar.
  final bool showLabels;
  final String semanticLabel;

  @override
  State<AceIsoMap> createState() => _AceIsoMapState();
}

class _AceIsoMapState extends State<AceIsoMap> with TickerProviderStateMixin {
  final _transform = TransformationController();
  late final AnimationController _grow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final AnimationController _fly = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  Animation<Matrix4>? _flight;
  _Scene? _scene;
  Size _viewport = Size.zero;
  Object? _sceneKey;

  /// Abaixo desta largura de lote na tela (px), o toque aproxima o conjunto.
  static const _tapLotMinPx = 22.0;
  static const _maxScale = 14.0;

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_onController);
    _fly.addListener(() {
      final f = _flight;
      if (f != null) _transform.value = f.value;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final still = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      still ? _grow.value = 1 : _grow.forward();
    });
  }

  @override
  void didUpdateWidget(AceIsoMap old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller?.removeListener(_onController);
      widget.controller?.addListener(_onController);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onController);
    _transform.dispose();
    _grow.dispose();
    _fly.dispose();
    super.dispose();
  }

  Offset get _mapOffset {
    final s = _scene;
    if (s == null) return Offset.zero;
    return Offset((_viewport.width - s.size.width) / 2, (_viewport.height - s.size.height) / 2);
  }

  void _onController() {
    final c = widget.controller!;
    if (c._reset) {
      _flyTo(Matrix4.identity());
      widget.onGroupFocused?.call(null);
      return;
    }
    final g = widget.groups.where((g) => g.id == c._focus).firstOrNull;
    if (g != null) _focus(g);
  }

  void _flyTo(Matrix4 target) {
    final still = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (still) {
      _transform.value = target;
      return;
    }
    _flight = Matrix4Tween(begin: _transform.value, end: target)
        .animate(CurvedAnimation(parent: _fly, curve: AceMotion.curve));
    _fly.forward(from: 0);
  }

  void _focus(AceIsoGroup g) {
    final s = _scene;
    if (s == null || _viewport.isEmpty) return;
    final r = s.proj.screenRect(g.bounds.inflate(4), lift: _Scene.height).shift(_mapOffset);
    final k = math.min(_viewport.width / r.width, _viewport.height / r.height).clamp(1.0, _maxScale);
    final tx = _viewport.width / 2 - r.center.dx * k;
    final ty = _viewport.height / 2 - r.center.dy * k;
    _flyTo(Matrix4.identity()
      ..translateByDouble(tx, ty, 0, 1)
      ..scaleByDouble(k, k, 1, 1));
    widget.onGroupFocused?.call(g);
  }

  double get _zoom => _transform.value.getMaxScaleOnAxis();

  void _onTapUp(TapUpDetails d) {
    final s = _scene;
    if (s == null) return;
    if (s.typicalLotPx * _zoom >= _tapLotMinPx) {
      final lot = s.hitLot(d.localPosition, _grow.value);
      if (lot != null) {
        widget.onLotTap?.call(lot);
        return;
      }
    }
    final ground = s.proj.toGround(d.localPosition);
    final g = widget.groups.where((g) => g.bounds.inflate(2).contains(ground)).firstOrNull;
    if (g != null) _focus(g);
  }

  _Scene _sceneFor(Size viewport) {
    final key = (viewport, widget.lots, widget.areas, widget.worldWidth, widget.worldHeight);
    if (_scene == null || _sceneKey != key) {
      _scene = _Scene.build(
        lots: widget.lots,
        areas: widget.areas,
        worldW: widget.worldWidth,
        worldH: widget.worldHeight,
        viewport: viewport,
      );
      _sceneKey = key;
    }
    return _scene!;
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final palette = _Palette(dark: dark, ink: context.colors.onSurface, accent: context.colors.primary);
    return Semantics(
      label: widget.semanticLabel,
      child: LayoutBuilder(
        builder: (context, box) {
          _viewport = box.biggest;
          final scene = _sceneFor(box.biggest);
          final map = SizedBox(
            width: scene.size.width,
            height: scene.size.height,
            child: Stack(
              children: [
                RepaintBoundary(
                  child: CustomPaint(size: scene.size, painter: _BlocksPainter(scene, palette, _grow)),
                ),
                if (widget.showLabels || widget.selectedLotId != null)
                  CustomPaint(
                    size: scene.size,
                    painter: _OverlayPainter(
                      scene: scene,
                      palette: palette,
                      transform: _transform,
                      grow: _grow,
                      selectedId: widget.selectedLotId,
                      groups: widget.showLabels ? widget.groups : const [],
                      showLotLabels: widget.showLabels,
                      text: context.text,
                      viewport: box.biggest,
                    ),
                  ),
              ],
            ),
          );

          if (!widget.interactive) return Center(child: map);

          return InteractiveViewer(
            transformationController: _transform,
            minScale: 1,
            maxScale: _maxScale,
            boundaryMargin: EdgeInsets.all(box.maxWidth * 0.25),
            constrained: false,
            child: SizedBox(
              width: box.maxWidth,
              height: box.maxHeight,
              child: Center(
                child: GestureDetector(behavior: HitTestBehavior.opaque, onTapUp: _onTapUp, child: map),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ------------------------------------------------------------------ cena 3D

class _Palette {
  _Palette({required this.dark, required this.ink, required this.accent});
  final bool dark;
  final Color ink;
  final Color accent;

  Color get ground => dark ? const Color(0xFF16242A) : const Color(0xFFE6ECEE);
  Color get block => dark ? const Color(0xFF1E3038) : const Color(0xFFF7F9FA);
  Color get park => dark ? const Color(0xFF1D3B30) : const Color(0xFFD3E8D6);
  Color get parkLine => dark ? const Color(0xFF2D5545) : const Color(0xFFB2D4B8);
  Color get building => dark ? const Color(0xFF3A4B53) : const Color(0xFFCFD8DC);
  Color get labelBg => dark ? const Color(0xE6101B20) : const Color(0xF2FFFFFF);
}

/// Projeção ortográfica inclinada (norte para cima).
class _Proj {
  _Proj(this.k, this.origin);

  static const yaw = 0.16; // giro leve: aparece a face leste dos blocos
  static const tilt = 0.72; // ~41° a partir da vista de cima
  static final ca = math.cos(yaw), sa = math.sin(yaw);
  static final ct = math.cos(tilt), st = math.sin(tilt);
  static final toCamera = (x: sa * st, y: ca * st, z: ct);

  final double k;
  final Offset origin;

  static Offset raw(double x, double y, double z) {
    final u = x * ca - y * sa;
    final v = x * sa + y * ca;
    return Offset(u, v * ct - z * st);
  }

  static double depth(double x, double y) => x * sa + y * ca;

  Offset p(double x, double y, [double z = 0]) => origin + raw(x, y, z) * k;

  Offset toGround(Offset s) {
    final u = (s.dx - origin.dx) / k;
    final v = (s.dy - origin.dy) / (k * ct);
    return Offset(ca * u + sa * v, -sa * u + ca * v);
  }

  Rect screenRect(Rect world, {double lift = 0}) {
    final pts = [
      p(world.left, world.top), p(world.right, world.top),
      p(world.left, world.bottom), p(world.right, world.bottom),
      p(world.left, world.top, lift), p(world.right, world.top, lift),
    ];
    return _bounds(pts);
  }

  Path polygon(List<Offset> pts, [double z = 0]) =>
      Path()..addPolygon([for (final q in pts) p(q.dx, q.dy, z)], true);
}

Rect _bounds(List<Offset> pts) {
  var r = Rect.fromLTRB(pts.first.dx, pts.first.dy, pts.first.dx, pts.first.dy);
  for (final q in pts) {
    r = r.expandToInclude(Rect.fromLTRB(q.dx, q.dy, q.dx, q.dy));
  }
  return r;
}

/// Um bloco: o contorno do lote encolhido um pouco (vão entre lotes) e levantado.
class _Block {
  _Block(this.lot) {
    final pts = lot.polygon;
    final c = pts.fold(Offset.zero, (a, b) => a + b) / pts.length.toDouble();
    center = c;
    // encolhe em direção ao centro para separar os blocos vizinhos
    base = [
      for (final q in pts)
        q + (c - q) * math.min(0.22, _Scene.gap / math.max(0.01, (c - q).distance)),
    ];
    depth = _Proj.depth(c.dx, c.dy);
    final b = _bounds(pts);
    size = math.min(b.width, b.height);
  }

  final AceIsoLot lot;
  late final Offset center;
  late final List<Offset> base;
  late final double depth;
  late final double size;

  /// Entrada: os blocos sobem de trás para a frente, uma vez.
  double rise(double t, double maxDepth) {
    final delay = (depth / math.max(1, maxDepth)).clamp(0.0, 1.0) * 0.4;
    return Curves.easeOutCubic.transform(((t - delay) / 0.6).clamp(0.0, 1.0));
  }

  /// Paredes voltadas para a câmera (normal para fora do contorno convexo).
  Iterable<(List<Offset>, double)> walls() sync* {
    for (var i = 0; i < base.length; i++) {
      final a = base[i];
      final b = base[(i + 1) % base.length];
      final e = b - a;
      if (e.distance < 0.01) continue;
      var n = Offset(e.dy, -e.dx) / e.distance;
      final mid = (a + b) / 2;
      if ((mid - center).dx * n.dx + (mid - center).dy * n.dy < 0) n = -n;
      final facing = n.dx * _Proj.toCamera.x + n.dy * _Proj.toCamera.y;
      if (facing > 0.001) yield ([a, b], facing);
    }
  }
}

class _Scene {
  _Scene._(this.proj, this.size, this.blocks, this.areas, this.worldW, this.worldH, this.maxDepth,
      this.typicalLot);

  static const height = 3.2; // altura do bloco (unidade da planta)
  static const gap = 0.45; // vão entre lotes vizinhos

  final _Proj proj;
  final Size size;
  final List<_Block> blocks;
  final List<AceIsoArea> areas;
  final double worldW;
  final double worldH;
  final double maxDepth;
  final double typicalLot;

  double get typicalLotPx => typicalLot * proj.k;

  factory _Scene.build({
    required List<AceIsoLot> lots,
    required List<AceIsoArea> areas,
    required double worldW,
    required double worldH,
    required Size viewport,
  }) {
    final corners = [
      _Proj.raw(0, 0, 0), _Proj.raw(worldW, 0, 0), _Proj.raw(0, worldH, 0),
      _Proj.raw(worldW, worldH, 0), _Proj.raw(0, 0, height), _Proj.raw(worldW, 0, height),
    ];
    final b = _bounds(corners);
    const pad = 10.0;
    final w = viewport.width.isFinite ? viewport.width : 360.0;
    final h = viewport.height.isFinite ? viewport.height : 480.0;
    final k = math.max(0.05, math.min((w - pad * 2) / b.width, (h - pad * 2) / b.height));
    final size = Size(b.width * k + pad * 2, b.height * k + pad * 2);
    final origin = Offset(pad - b.left * k, pad - b.top * k);
    final blocks = [for (final l in lots) if (l.polygon.length >= 3) _Block(l)]
      ..sort((a, b) => a.depth.compareTo(b.depth));
    final sizes = blocks.map((b) => b.size).toList()..sort();
    final typical = sizes.isEmpty ? 1.0 : sizes[sizes.length ~/ 2];
    final maxDepth = blocks.isEmpty ? 1.0 : blocks.last.depth;
    return _Scene._(_Proj(k, origin), size, blocks, areas, worldW, worldH, maxDepth, typical);
  }

  AceIsoLot? hitLot(Offset s, double grow) {
    for (final b in blocks.reversed) {
      final z = height * b.rise(grow, maxDepth);
      if (proj.polygon(b.base, z).contains(s) || proj.polygon(b.base).contains(s)) return b.lot;
      for (final (w, _) in b.walls()) {
        final path = Path()
          ..addPolygon([
            proj.p(w[0].dx, w[0].dy), proj.p(w[1].dx, w[1].dy),
            proj.p(w[1].dx, w[1].dy, z), proj.p(w[0].dx, w[0].dy, z),
          ], true);
        if (path.contains(s)) return b.lot;
      }
    }
    return null;
  }
}

Color _shade(Color c, double f) => Color.from(alpha: 1, red: c.r * f, green: c.g * f, blue: c.b * f);

class _BlocksPainter extends CustomPainter {
  _BlocksPainter(this.scene, this.palette, this.grow) : super(repaint: grow);

  final _Scene scene;
  final _Palette palette;
  final Animation<double> grow;

  @override
  void paint(Canvas canvas, Size size) {
    final s = scene;
    final p = s.proj;
    final fill = Paint()..isAntiAlias = true;

    // chão da quadra
    canvas.drawPath(
      p.polygon([const Offset(-4, -4), Offset(s.worldW + 4, -4), Offset(s.worldW + 4, s.worldH + 4),
        Offset(-4, s.worldH + 4)]),
      fill..color = palette.ground,
    );

    // áreas livres: praça plana, equipamento como bloco baixo neutro
    for (final a in s.areas) {
      if (a.polygon.length < 3) continue;
      if (a.kind == AceIsoAreaKind.park) {
        canvas.drawPath(p.polygon(a.polygon), fill..color = palette.park);
        canvas.drawPath(
          p.polygon(a.polygon),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(0.5, p.k * 0.25)
            ..color = palette.parkLine,
        );
      } else {
        final blk = _Block(AceIsoLot(id: a.label, polygon: a.polygon, status: AceLotStatus.semAcesso, label: ''));
        _drawPrism(canvas, blk, _Scene.height * 0.6 * grow.value, palette.building, null);
      }
    }

    // calçada: pegada clara de cada lote (lê o desenho da quadra mesmo sem altura)
    for (final b in s.blocks) {
      canvas.drawPath(p.polygon(b.lot.polygon), fill..color = palette.block);
    }

    // blocos, de trás para a frente
    for (final b in s.blocks) {
      final r = b.rise(grow.value, s.maxDepth);
      if (r <= 0.01) continue;
      _drawPrism(canvas, b, _Scene.height * r, b.lot.status.color, b.lot.status);
    }
  }

  void _drawPrism(Canvas canvas, _Block b, double z, Color top, AceLotStatus? status) {
    final p = scene.proj;
    final fill = Paint()..isAntiAlias = true;
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = math.max(0.35, p.k * 0.12)
      ..color = _shade(top, 0.62).withValues(alpha: 0.7);
    for (final (w, facing) in b.walls()) {
      final path = Path()
        ..addPolygon([
          p.p(w[0].dx, w[0].dy), p.p(w[1].dx, w[1].dy),
          p.p(w[1].dx, w[1].dy, z), p.p(w[0].dx, w[0].dy, z),
        ], true);
      // parede para o sul mais clara que a do leste (luz do noroeste)
      final f = 0.62 + 0.18 * facing;
      canvas.drawPath(path, fill..color = _shade(top, f));
    }
    final roof = p.polygon(b.base, z);
    canvas.drawPath(roof, fill..color = top);
    canvas.drawPath(roof, edge);
  }

  @override
  bool shouldRepaint(_BlocksPainter old) => old.scene != scene || old.palette.dark != palette.dark;
}

/// Números, nomes dos conjuntos e destaque do lote escolhido.
class _OverlayPainter extends CustomPainter {
  _OverlayPainter({
    required this.scene,
    required this.palette,
    required this.transform,
    required this.grow,
    required this.selectedId,
    required this.groups,
    required this.showLotLabels,
    required this.text,
    required this.viewport,
  }) : super(repaint: Listenable.merge([transform, grow]));

  final _Scene scene;
  final _Palette palette;
  final TransformationController transform;
  final Animation<double> grow;
  final String? selectedId;
  final List<AceIsoGroup> groups;
  final bool showLotLabels;
  final TextTheme text;
  final Size viewport;

  static final _cache = <String, TextPainter>{};

  TextPainter _tp(String s, TextStyle style) {
    final key = '$s|${style.fontSize?.toStringAsFixed(3)}|${style.color}|${style.fontWeight}';
    return _cache.putIfAbsent(
      key,
      () => TextPainter(text: TextSpan(text: s, style: style), textDirection: TextDirection.ltr)..layout(),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_cache.length > 3000) _cache.clear();
    final s = scene;
    final p = s.proj;
    final zoom = transform.value.getMaxScaleOnAxis();
    final inv = Matrix4.inverted(transform.value);
    final off = Offset((viewport.width - size.width) / 2, (viewport.height - size.height) / 2);
    final view = Rect.fromPoints(
      MatrixUtils.transformPoint(inv, Offset.zero) - off,
      MatrixUtils.transformPoint(inv, viewport.bottomRight(Offset.zero)) - off,
    ).inflate(30);
    final g = grow.value;

    // destaque do lote escolhido
    if (selectedId != null) {
      final b = s.blocks.where((b) => b.lot.id == selectedId).firstOrNull;
      if (b != null) {
        final z = _Scene.height * b.rise(g, s.maxDepth);
        canvas.drawPath(
          p.polygon(b.base, z),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeJoin = StrokeJoin.round
            ..strokeWidth = 3 / zoom
            ..color = palette.ink,
        );
      }
    }

    final lotPx = s.typicalLotPx * zoom;

    // números dos lotes: só com o lote grande o bastante na tela
    if (showLotLabels && lotPx >= 26 && g > 0.6) {
      final style = (text.labelSmall ?? const TextStyle()).copyWith(
        fontSize: 11.5 / zoom * math.min(1.5, lotPx / 34),
        color: Colors.white,
        fontWeight: FontWeight.w700,
        height: 1,
      );
      for (final b in s.blocks) {
        final c = p.p(b.center.dx, b.center.dy, _Scene.height * b.rise(g, s.maxDepth));
        if (!view.contains(c)) continue;
        final tp = _tp(b.lot.label, style);
        tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
      }
    }

    // nomes dos conjuntos: no meio do caminho entre afastado e perto
    if (groups.isNotEmpty && lotPx >= 9 && lotPx < 70) {
      final style = (text.labelSmall ?? const TextStyle()).copyWith(
        fontSize: 11 / zoom,
        color: palette.ink,
        fontWeight: FontWeight.w700,
        height: 1,
      );
      final bg = Paint()..color = palette.labelBg;
      final border = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1 / zoom
        ..color = palette.accent.withValues(alpha: 0.5);
      for (final grp in groups) {
        final a = p.p(grp.bounds.center.dx, grp.bounds.center.dy, _Scene.height + 1);
        if (!view.contains(a)) continue;
        final tp = _tp(grp.label, style);
        final r = RRect.fromRectAndRadius(
          Rect.fromCenter(center: a, width: tp.width + 10 / zoom, height: tp.height + 7 / zoom),
          Radius.circular(AceRadius.sm / zoom),
        );
        canvas.drawRRect(r, bg);
        canvas.drawRRect(r, border);
        tp.paint(canvas, r.center - Offset(tp.width / 2, tp.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(_OverlayPainter old) =>
      old.selectedId != selectedId || old.scene != scene || old.palette.dark != palette.dark;
}

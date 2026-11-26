import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/ace_theme.dart';
import '../tokens/ace_spacing.dart';
import '../tokens/ace_status.dart';

/// Um lote no mapa. Medidas em testadas de lote; x cresce para leste, y para sul.
@immutable
class AceIsoLot {
  const AceIsoLot({
    required this.id,
    required this.x,
    required this.y,
    required this.w,
    required this.d,
    required this.status,
    required this.label,
  });

  final String id;
  final double x;
  final double y;
  final double w;
  final double d;
  final AceLotStatus status;

  /// Número mostrado sobre a casa quando o mapa está aproximado.
  final String label;
}

/// Um grupo de lotes (conjunto voltado para a mesma alameda).
@immutable
class AceIsoGroup {
  const AceIsoGroup({
    required this.id,
    required this.label,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
  });

  final String id;
  final String label;
  final double x;
  final double y;
  final double w;
  final double h;

  bool contains(Offset p) =>
      p.dx >= x && p.dx <= x + w && p.dy >= y && p.dy <= y + h;
}

enum AceIsoAreaKind { park, building }

/// Área sem lotes: praça (árvores) ou equipamento público (prédio).
@immutable
class AceIsoArea {
  const AceIsoArea({
    required this.label,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.kind,
  });

  final String label;
  final double x;
  final double y;
  final double w;
  final double h;
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

/// Mapa 3D (projeção ortográfica inclinada, norte para cima) da quadra.
///
/// Cada lote vira uma casa com telhado de duas águas pintada pela situação do
/// lote. Pinça e arrasto aproximam. Com o mapa afastado, tocar num conjunto
/// aproxima o conjunto; aproximado, tocar numa casa chama [onLotTap].
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
    this.semanticLabel = 'Mapa 3D da quadra',
    this.dark,
    this.showLabels = true,
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
  final String semanticLabel;

  /// Força o chão escuro (ex.: sobre o verde da marca). Padrão: tema atual.
  final bool? dark;

  /// Números das casas e nomes das alamedas ao aproximar.
  final bool showLabels;

  @override
  State<AceIsoMap> createState() => _AceIsoMapState();
}

class _AceIsoMapState extends State<AceIsoMap> with TickerProviderStateMixin {
  final _transform = TransformationController();
  late final AnimationController _grow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final AnimationController _fly = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  Animation<Matrix4>? _flight;
  _IsoProjection? _proj;
  Size _viewport = Size.zero;

  /// Canto do mapa dentro da área do InteractiveViewer (o mapa fica centrado).
  Offset get _mapOffset {
    final p = _proj;
    if (p == null) return Offset.zero;
    return Offset((_viewport.width - p.size.width) / 2,
        (_viewport.height - p.size.height) / 2);
  }

  /// Telas abaixo deste tamanho de lote (px) tocam no conjunto, não na casa.
  static const _tapLotMinPx = 18.0;

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
    final p = _proj;
    if (p == null || _viewport.isEmpty) return;
    final r = p
        .groundRect(g.x - 0.6, g.y - 0.6, g.w + 1.2, g.h + 1.2, lift: 1.3)
        .shift(_mapOffset);
    final s = math
        .min(_viewport.width / r.width, _viewport.height / r.height)
        .clamp(1.0, _maxScale);
    final tx = _viewport.width / 2 - r.center.dx * s;
    final ty = _viewport.height / 2 - r.center.dy * s;
    _flyTo(Matrix4.identity()
      ..translateByDouble(tx, ty, 0, 1)
      ..scaleByDouble(s, s, 1, 1));
    widget.onGroupFocused?.call(g);
  }

  double get _maxScale => 10;

  double get _zoom => _transform.value.getMaxScaleOnAxis();

  void _onTapUp(TapUpDetails d) {
    final p = _proj;
    if (p == null) return;
    final pxPerLot = p.k * _zoom;
    if (pxPerLot >= _tapLotMinPx) {
      final lot = p.hitLot(d.localPosition, _grow.value);
      if (lot != null) {
        widget.onLotTap?.call(lot);
        return;
      }
    }
    final ground = p.toGround(d.localPosition);
    final g = widget.groups.where((g) => g.contains(ground)).firstOrNull;
    if (g != null) _focus(g);
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.dark ?? Theme.of(context).brightness == Brightness.dark;
    final palette = _IsoPalette(
      dark: dark,
      ink: dark ? const Color(0xFFE8EFEC) : const Color(0xFF12201D),
    );
    return Semantics(
      label: widget.semanticLabel,
      child: LayoutBuilder(
        builder: (context, box) {
          _viewport = box.biggest;
          final proj = _IsoProjection.fit(
            lots: widget.lots,
            areas: widget.areas,
            worldW: widget.worldWidth,
            worldH: widget.worldHeight,
            viewport: box.biggest,
          );
          _proj = proj;

          final map = SizedBox(
            width: proj.size.width,
            height: proj.size.height,
            child: Stack(
              children: [
                RepaintBoundary(
                  child: CustomPaint(
                    size: proj.size,
                    painter: _GeometryPainter(proj, palette, _grow),
                  ),
                ),
                if (widget.showLabels || widget.selectedLotId != null)
                  CustomPaint(
                    size: proj.size,
                    painter: _OverlayPainter(
                      proj,
                      palette,
                      _transform,
                      _grow,
                      widget.selectedLotId,
                      widget.groups,
                      context.text,
                      box.biggest,
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
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: _onTapUp,
                  child: map,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ------------------------------------------------------------ projeção 3D

class _IsoPalette {
  _IsoPalette({required this.dark, required this.ink});
  final bool dark;
  final Color ink;

  Color get ground => dark ? const Color(0xFF1C2623) : const Color(0xFFE9ECE6);
  Color get sidewalk =>
      dark ? const Color(0xFF26322E) : const Color(0xFFF7F8F4);
  Color get yardLine =>
      dark ? const Color(0xFF34433E) : const Color(0xFFD3D9D2);
  Color get park => dark ? const Color(0xFF1F3E2E) : const Color(0xFFCFE6C8);
  Color get tree => dark ? const Color(0xFF3F8A5F) : const Color(0xFF3E8F5A);
  Color get building =>
      dark ? const Color(0xFF6F7C78) : const Color(0xFFD9D2C3);
  Color get labelBg => dark ? const Color(0xE6121A17) : const Color(0xF2FFFFFF);
}

/// Projeção ortográfica: giro (yaw) e inclinação (tilt) da câmera.
class _IsoProjection {
  _IsoProjection._(this.k, this.origin, this.size, this.houses, this.areas,
      this.worldW, this.worldH);

  static const yaw = 0.2; // ~11°: norte quase para cima, fachada leste visível
  static const tilt = 0.74; // ~42° a partir da vista de cima
  static final _ca = math.cos(yaw), _sa = math.sin(yaw);
  static final _ct = math.cos(tilt), _st = math.sin(tilt);

  /// Direção para a câmera (para descartar faces de trás).
  static final toCamera = _V3(_sa * _st, _ca * _st, _ct);

  /// Luz vinda do noroeste, do alto.
  static final light = _V3(-0.35, -0.55, 1).normalized();

  final double k; // px por testada de lote, sem zoom
  final Offset origin;
  final Size size;
  final List<_House> houses;
  final List<AceIsoArea> areas;
  final double worldW;
  final double worldH;

  static Offset _raw(double x, double y, double z) {
    final u = x * _ca - y * _sa;
    final v = x * _sa + y * _ca;
    return Offset(u, v * _ct - z * _st);
  }

  factory _IsoProjection.fit({
    required List<AceIsoLot> lots,
    required List<AceIsoArea> areas,
    required double worldW,
    required double worldH,
    required Size viewport,
  }) {
    final corners = [
      _raw(0, 0, 0),
      _raw(worldW, 0, 0),
      _raw(0, worldH, 0),
      _raw(worldW, worldH, 0),
      _raw(0, 0, 2),
      _raw(worldW, 0, 2),
    ];
    var b = Rect.fromPoints(corners[0], corners[1]);
    for (final c in corners) {
      b = b.expandToInclude(Rect.fromCenter(center: c, width: 0, height: 0));
    }
    const pad = 12.0;
    final w = viewport.width.isFinite ? viewport.width : 360.0;
    final h = viewport.height.isFinite ? viewport.height : 480.0;
    final k = math.max(
      1.0,
      math.min((w - pad * 2) / b.width, (h - pad * 2) / b.height),
    );
    final size = Size(b.width * k + pad * 2, b.height * k + pad * 2);
    final origin = Offset(pad - b.left * k, pad - b.top * k);

    final houses = [for (final l in lots) _House(l)]
      ..sort((a, b) => a.depth.compareTo(b.depth));
    return _IsoProjection._(k, origin, size, houses, areas, worldW, worldH);
  }

  Offset p(double x, double y, double z) => origin + _raw(x, y, z) * k;

  /// Ponto da tela (sem zoom) de volta para o chão (z = 0).
  Offset toGround(Offset s) {
    final u = (s.dx - origin.dx) / k;
    final v = (s.dy - origin.dy) / (k * _ct);
    return Offset(_ca * u + _sa * v, -_sa * u + _ca * v);
  }

  Rect groundRect(double x, double y, double w, double h, {double lift = 0}) {
    final pts = [
      p(x, y, 0),
      p(x + w, y, 0),
      p(x, y + h, 0),
      p(x + w, y + h, 0),
      p(x, y, lift),
      p(x + w, y, lift),
    ];
    var r = Rect.fromPoints(pts[0], pts[1]);
    for (final q in pts) {
      r = r.expandToInclude(Rect.fromCenter(center: q, width: 0, height: 0));
    }
    return r;
  }

  Path quad(double x, double y, double w, double h, [double z = 0]) => Path()
    ..addPolygon(
        [p(x, y, z), p(x + w, y, z), p(x + w, y + h, z), p(x, y + h, z)], true);

  AceIsoLot? hitLot(Offset s, double grow) {
    for (final h in houses.reversed) {
      if (h.outline(this, h.growAt(grow)).contains(s)) return h.lot;
      if (quad(h.lot.x, h.lot.y, h.lot.w, h.lot.d).contains(s)) return h.lot;
    }
    return null;
  }
}

class _V3 {
  const _V3(this.x, this.y, this.z);
  final double x, y, z;
  double dot(_V3 o) => x * o.x + y * o.y + z * o.z;
  _V3 normalized() {
    final l = math.sqrt(x * x + y * y + z * z);
    return _V3(x / l, y / l, z / l);
  }
}

class _Face {
  const _Face(this.points, this.normal, this.isRoof);
  final List<(double, double, double)> points;
  final _V3 normal;
  final bool isRoof;
}

/// Casa sobre o lote: caixa + telhado de duas águas (cumeeira no lado maior).
class _House {
  _House(this.lot)
      : depth = (lot.x + lot.w / 2) * _IsoProjection._sa +
            (lot.y + lot.d / 2) * _IsoProjection._ca;

  final AceIsoLot lot;
  final double depth;

  static const _inset = 0.14;
  static const _wall = 0.62;
  static const _roof = 0.34;

  /// Entrada: as casas sobem de trás para a frente, uma vez.
  double growAt(double t) {
    final delay = (depth / 70).clamp(0.0, 1.0) * 0.45;
    return Curves.easeOutBack.transform(((t - delay) / 0.55).clamp(0.0, 1.0));
  }

  List<_Face> faces(double g) {
    final x0 = lot.x + _inset, x1 = lot.x + lot.w - _inset;
    final y0 = lot.y + _inset, y1 = lot.y + lot.d - _inset;
    final h = _wall * g, top = (_wall + _roof) * g;
    final alongX = (x1 - x0) >= (y1 - y0);
    if (alongX) {
      final ym = (y0 + y1) / 2;
      final run = ym - y0;
      return [
        _Face([(x0, y0, 0), (x1, y0, 0), (x1, y0, h), (x0, y0, h)],
            const _V3(0, -1, 0), false),
        _Face([(x1, y1, 0), (x0, y1, 0), (x0, y1, h), (x1, y1, h)],
            const _V3(0, 1, 0), false),
        _Face(
            [(x0, y1, 0), (x0, y0, 0), (x0, y0, h), (x0, ym, top), (x0, y1, h)],
            const _V3(-1, 0, 0),
            false),
        _Face(
            [(x1, y0, 0), (x1, y1, 0), (x1, y1, h), (x1, ym, top), (x1, y0, h)],
            const _V3(1, 0, 0),
            false),
        _Face([(x0, y0, h), (x1, y0, h), (x1, ym, top), (x0, ym, top)],
            _V3(0, -_roof, run).normalized(), true),
        _Face([(x1, y1, h), (x0, y1, h), (x0, ym, top), (x1, ym, top)],
            _V3(0, _roof, run).normalized(), true),
      ];
    }
    final xm = (x0 + x1) / 2;
    final run = xm - x0;
    return [
      _Face([(x0, y1, 0), (x0, y0, 0), (x0, y0, h), (x0, y1, h)],
          const _V3(-1, 0, 0), false),
      _Face([(x1, y0, 0), (x1, y1, 0), (x1, y1, h), (x1, y0, h)],
          const _V3(1, 0, 0), false),
      _Face([(x0, y0, 0), (x1, y0, 0), (x1, y0, h), (xm, y0, top), (x0, y0, h)],
          const _V3(0, -1, 0), false),
      _Face([(x1, y1, 0), (x0, y1, 0), (x0, y1, h), (xm, y1, top), (x1, y1, h)],
          const _V3(0, 1, 0), false),
      _Face([(x0, y1, h), (x0, y0, h), (xm, y0, top), (xm, y1, top)],
          _V3(-_roof, 0, run).normalized(), true),
      _Face([(x1, y0, h), (x1, y1, h), (xm, y1, top), (xm, y0, top)],
          _V3(_roof, 0, run).normalized(), true),
    ];
  }

  Iterable<_Face> visible(double g) =>
      faces(g).where((f) => f.normal.dot(_IsoProjection.toCamera) > 0.001);

  Path outline(_IsoProjection p, double g) {
    final path = Path();
    for (final f in visible(g)) {
      path.addPolygon([for (final (x, y, z) in f.points) p.p(x, y, z)], true);
    }
    return path;
  }

  Offset labelAnchor(_IsoProjection p, double g) =>
      p.p(lot.x + lot.w / 2, lot.y + lot.d / 2, (_wall + _roof) * g + 0.15);
}

Color _shade(Color c, _V3 n) {
  final lit = n.dot(_IsoProjection.light).clamp(0.0, 1.0);
  final f = 0.62 + 0.38 * lit;
  return Color.from(alpha: 1, red: c.r * f, green: c.g * f, blue: c.b * f);
}

// --------------------------------------------------------------- pintores

class _GeometryPainter extends CustomPainter {
  _GeometryPainter(this.proj, this.palette, this.grow) : super(repaint: grow);

  final _IsoProjection proj;
  final _IsoPalette palette;
  final Animation<double> grow;

  @override
  void paint(Canvas canvas, Size size) {
    final p = proj;
    final fill = Paint()..isAntiAlias = true;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.5, p.k * 0.035)
      ..color = palette.yardLine;

    // Chão da quadra e calçadas
    canvas.drawPath(
      p.quad(-0.8, -0.8, p.worldW + 1.6, p.worldH + 1.6),
      fill..color = palette.ground,
    );
    canvas.drawPath(
        p.quad(0, 0, p.worldW, p.worldH), fill..color = palette.sidewalk);

    // Áreas livres (praça, escola, igreja)
    for (final a in p.areas) {
      final park = a.kind == AceIsoAreaKind.park;
      canvas.drawPath(p.quad(a.x, a.y, a.w, a.h),
          fill..color = park ? palette.park : palette.ground);
      if (park) {
        _trees(canvas, a, g: grow.value);
      } else {
        _building(canvas, a, g: grow.value);
      }
    }

    // Quintais (o chão do lote já mostra a cor da situação)
    for (final h in p.houses) {
      final yard = Color.lerp(
          palette.sidewalk, h.lot.status.color, palette.dark ? 0.32 : 0.22)!;
      final q = p.quad(h.lot.x, h.lot.y, h.lot.w, h.lot.d);
      canvas.drawPath(q, fill..color = yard);
      canvas.drawPath(q, line);
    }

    // Casas, de trás para a frente
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = math.max(0.4, p.k * 0.03);
    for (final h in p.houses) {
      final g = h.growAt(grow.value);
      if (g <= 0.01) continue;
      final base = h.lot.status.color;
      final roof = Color.lerp(base, Colors.black, 0.18)!;
      final wall = Color.lerp(base, Colors.white, 0.22)!;
      for (final f in h.visible(g)) {
        final poly = Path()
          ..addPolygon([for (final (x, y, z) in f.points) p.p(x, y, z)], true);
        canvas.drawPath(
            poly, fill..color = _shade(f.isRoof ? roof : wall, f.normal));
        canvas.drawPath(
            poly,
            edge
              ..color = Color.lerp(base, Colors.black, 0.45)!
                  .withValues(alpha: 0.55));
      }
    }
  }

  void _trees(Canvas canvas, AceIsoArea a, {required double g}) {
    final p = proj;
    final rnd = math.Random(a.label.hashCode);
    final canopy = Paint()..color = palette.tree;
    final shadow = Paint()..color = Colors.black.withValues(alpha: 0.12);
    final pts = <Offset>[];
    for (var i = 0; i < (a.w * a.h / 6).round(); i++) {
      pts.add(Offset(a.x + 0.8 + rnd.nextDouble() * (a.w - 1.6),
          a.y + 0.8 + rnd.nextDouble() * (a.h - 1.6)));
    }
    pts.sort((m, n) => (m.dx * _IsoProjection._sa + m.dy * _IsoProjection._ca)
        .compareTo(n.dx * _IsoProjection._sa + n.dy * _IsoProjection._ca));
    for (final t in pts) {
      final r = p.k * (0.45 + rnd.nextDouble() * 0.25);
      canvas.drawOval(
          Rect.fromCenter(
              center: p.p(t.dx + 0.3, t.dy + 0.2, 0),
              width: r * 2,
              height: r * 1.2),
          shadow);
      final c = p.p(t.dx, t.dy, 1.1 * g);
      canvas.drawCircle(c, r, canopy..color = palette.tree);
      canvas.drawCircle(c - Offset(r * 0.3, r * 0.3), r * 0.45,
          canopy..color = Color.lerp(palette.tree, Colors.white, 0.18)!);
    }
  }

  void _building(Canvas canvas, AceIsoArea a, {required double g}) {
    final p = proj;
    final lot = AceIsoLot(
      id: a.label,
      x: a.x + 1,
      y: a.y + 1,
      w: a.w - 2,
      d: a.h - 2,
      status: AceLotStatus.semAcesso,
      label: '',
    );
    final house = _House(lot);
    final fill = Paint();
    for (final f in house.visible(g * 1.4)) {
      final poly = Path()
        ..addPolygon([for (final (x, y, z) in f.points) p.p(x, y, z)], true);
      canvas.drawPath(poly, fill..color = _shade(palette.building, f.normal));
    }
  }

  @override
  bool shouldRepaint(_GeometryPainter old) =>
      old.proj != proj || old.palette.dark != palette.dark;
}

/// Números, nomes das alamedas e destaque do lote escolhido.
/// Repinta a cada zoom; desenha só o que está na tela.
class _OverlayPainter extends CustomPainter {
  _OverlayPainter(this.proj, this.palette, this.transform, this.grow,
      this.selectedId, this.groups, this.text, this.viewport)
      : super(repaint: Listenable.merge([transform, grow]));

  final _IsoProjection proj;
  final _IsoPalette palette;
  final TransformationController transform;
  final Animation<double> grow;
  final String? selectedId;
  final List<AceIsoGroup> groups;
  final TextTheme text;
  final Size viewport;

  static final _cache = <String, TextPainter>{};

  TextPainter _tp(String s, TextStyle style) {
    final key = '$s|${style.fontSize}|${style.color}|${style.fontWeight}';
    return _cache.putIfAbsent(
      key,
      () => TextPainter(
        text: TextSpan(text: s, style: style),
        textDirection: TextDirection.ltr,
      )..layout(),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_cache.length > 2000) _cache.clear();
    final zoom = transform.value.getMaxScaleOnAxis();
    final pxPerLot = proj.k * zoom;
    final inv = Matrix4.inverted(transform.value);
    // área visível em coordenadas do mapa (com folga)
    final offset = Offset(
      (viewport.width - size.width) / 2,
      (viewport.height - size.height) / 2,
    );
    final tl = MatrixUtils.transformPoint(inv, Offset.zero) - offset;
    final br =
        MatrixUtils.transformPoint(inv, viewport.bottomRight(Offset.zero)) -
            offset;
    final view = Rect.fromPoints(tl, br).inflate(40);

    final g = grow.value;

    // Destaque do lote escolhido
    if (selectedId != null) {
      final h = proj.houses.where((h) => h.lot.id == selectedId).firstOrNull;
      if (h != null) {
        final stroke = Paint()
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = 3 / zoom
          ..color = palette.ink;
        canvas.drawPath(proj.quad(h.lot.x, h.lot.y, h.lot.w, h.lot.d), stroke);
        canvas.drawPath(h.outline(proj, h.growAt(g)), stroke);
      }
    }

    // Números das casas: só com o mapa aproximado
    if (pxPerLot >= 20 && g > 0.6) {
      final style = (text.labelSmall ?? const TextStyle()).copyWith(
        fontSize: 11 / zoom * math.min(1.6, pxPerLot / 24),
        color: palette.ink,
        fontWeight: FontWeight.w700,
        height: 1,
      );
      final bg = Paint()..color = palette.labelBg;
      for (final h in proj.houses) {
        final a = h.labelAnchor(proj, h.growAt(g));
        if (!view.contains(a)) continue;
        final tp = _tp(h.lot.label, style);
        final r = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: a - Offset(0, tp.height * 0.6),
            width: tp.width + 8 / zoom,
            height: tp.height + 5 / zoom,
          ),
          Radius.circular(4 / zoom),
        );
        canvas.drawRRect(r, bg);
        tp.paint(canvas, r.center - Offset(tp.width / 2, tp.height / 2));
      }
    }

    // Nomes das alamedas: com o mapa afastado ou médio
    if (pxPerLot >= 9 && pxPerLot < 60) {
      final style = (text.labelSmall ?? const TextStyle()).copyWith(
        fontSize: 10.5 / zoom,
        color: palette.ink,
        fontWeight: FontWeight.w600,
        height: 1,
      );
      final bg = Paint()..color = palette.labelBg;
      for (final grp in groups) {
        final a = proj.p(grp.x + grp.w / 2, grp.y + grp.h + 0.55, 0);
        if (!view.contains(a)) continue;
        final tp = _tp(grp.label.replaceFirst('Alameda ', 'Al. '), style);
        final r = RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: a,
              width: tp.width + 8 / zoom,
              height: tp.height + 5 / zoom),
          Radius.circular(AceRadius.sm / zoom),
        );
        canvas.drawRRect(r, bg);
        tp.paint(canvas, r.center - Offset(tp.width / 2, tp.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(_OverlayPainter old) =>
      old.selectedId != selectedId ||
      old.proj != proj ||
      old.palette.dark != palette.dark;
}

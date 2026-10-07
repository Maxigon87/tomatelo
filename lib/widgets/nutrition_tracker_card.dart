import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tomatelo/models/nutrition_habit.dart';
import 'package:tomatelo/theme/app_theme.dart';

class NutritionTrackerCard extends StatefulWidget {
  const NutritionTrackerCard({
    super.key,
    required this.today,
    required this.goals,
    required this.completed,
    required this.totalGoal,
    required this.onAddHabit,
    required this.onOpenGoals,
    this.yesterdayData,
    this.weeklyData,
    this.consumedToday = const [],
    this.consumedYesterday = const [],
    this.onAddFood,
    this.onRemoveFood,
  });

  final Map<String, int> today;
  final Map<String, int> goals;
  final int completed;
  final int totalGoal;
  final ValueChanged<NutritionHabit> onAddHabit;
  final VoidCallback onOpenGoals;
  final Map<String, int>? yesterdayData;
  final List<int>? weeklyData;
  final List<Map<String, dynamic>> consumedToday;
  final List<Map<String, dynamic>> consumedYesterday;
  final ValueChanged<CatalogFoodItem>? onAddFood;
  final ValueChanged<int>? onRemoveFood;

  @override
  State<NutritionTrackerCard> createState() => _NutritionTrackerCardState();
}

class _NutritionTrackerCardState extends State<NutritionTrackerCard> {
  bool _isDropdownOpen = true;
  String _selectedCategory = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  List<CatalogFoodItem> _allFoodItems = List.from(catalogFoodItems);

  @override
  void initState() {
    super.initState();
    _loadFoodsFromJson();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFoodsFromJson() async {
    try {
      String jsonString;
      try {
        jsonString = await rootBundle.loadString('assets/json/alimentos.json');
      } catch (_) {
        jsonString = await rootBundle.loadString('assets/json/alimnetos.json');
      }
      final List<dynamic> list = jsonDecode(jsonString) as List<dynamic>;
      final parsed = <CatalogFoodItem>[];
      for (final raw in list) {
        if (raw is! Map<String, dynamic>) continue;
        final id = raw['id']?.toString() ?? '';
        final name = raw['nombre']?.toString() ?? '';
        final emoji = raw['icono']?.toString() ?? '🍎';
        final habitId = _inferHabitId(id, name);
        final (label, color, portion) = _inferCategoryDetails(habitId, id);

        parsed.add(
          CatalogFoodItem(
            id: id,
            name: name,
            habitId: habitId,
            categoryLabel: label,
            portion: portion,
            emoji: emoji,
            color: color,
          ),
        );
      }
      if (parsed.isNotEmpty && mounted) {
        setState(() {
          _allFoodItems = parsed;
        });
      }
    } catch (_) {
      // Fallback to static catalogFoodItems
    }
  }

  String _inferHabitId(String id, String name) {
    final text = '$id $name'.toLowerCase();
    if (text.contains('te_') || text.contains('té') || text.contains('mate') ||
        text.contains('infusion') || text.contains('infusión') ||
        text.contains('cafe') || text.contains('café') || text.contains('agua')) {
      return 'tea';
    }
    if (text.contains('yogur') || text.contains('leche') ||
        text.contains('queso') || text.contains('huevo')) {
      return 'yogurt';
    }
    if (text.contains('nuez') || text.contains('nueces') ||
        text.contains('almendra') || text.contains('mani') || text.contains('maní') ||
        text.contains('caju') || text.contains('cajú') || text.contains('pistacho') ||
        text.contains('semilla') || text.contains('avena') || text.contains('granola') ||
        text.contains('tostada') || text.contains('galleta') ||
        text.contains('chocolate') || text.contains('zanahoria') ||
        text.contains('cherry') || text.contains('snack')) {
      return 'snack';
    }
    return 'fruit';
  }

  (String label, Color color, String portion) _inferCategoryDetails(String habitId, String id) {
    switch (habitId) {
      case 'tea':
        return ('+1 Infusión', AppTheme.tertiaryMint, '1 taza / vaso');
      case 'yogurt':
        return ('+1 Yogurt', AppTheme.primaryAqua, '1 porción');
      case 'snack':
        return ('+1 Snack', const Color(0xFFFBBF24), '1 puñado / porción');
      case 'fruit':
      default:
        return ('+1 Fruta', AppTheme.secondaryCoral, '1 porción fresca');
    }
  }

  List<CatalogFoodItem> get _filteredFoods {
    return _allFoodItems.where((item) {
      if (_selectedCategory != 'all' && item.habitId != _selectedCategory) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return item.name.toLowerCase().contains(query) ||
            item.categoryLabel.toLowerCase().contains(query);
      }
      return true;
    }).toList();
  }

  double get _progress {
    if (widget.totalGoal <= 0) return 0;
    return (widget.completed / widget.totalGoal).clamp(0.0, 1.0);
  }

  String get _message {
    if (widget.completed == 0) return 'Un hábito pequeño para empezar ✨';
    if (_progress < 0.5) return 'Vas sumando cuidado suave 🌱';
    if (_progress < 1) return '¡Buen equilibrio hoy! ✨';
    return 'Día liviano y completo 🎉';
  }

  List<Map<String, dynamic>> get _filteredConsumedToday {
    if (_selectedCategory == 'all') {
      return widget.consumedToday;
    }
    return widget.consumedToday.where((item) {
      final habitId = item['habitId']?.toString() ?? '';
      final category = item['category']?.toString().toLowerCase() ?? '';
      final name = item['name']?.toString().toLowerCase() ?? '';
      if (_selectedCategory == 'fruit') {
        return habitId == 'fruit' || category.contains('fruta') || name.contains('fruta') || name.contains('manzana') || name.contains('banana');
      }
      if (_selectedCategory == 'tea') {
        return habitId == 'tea' || category.contains('infusión') || category.contains('té') || name.contains('té') || name.contains('mate') || name.contains('café');
      }
      if (_selectedCategory == 'yogurt') {
        return habitId == 'yogurt' || category.contains('yogur') || category.contains('lácteo') || name.contains('yogur') || name.contains('leche');
      }
      if (_selectedCategory == 'snack') {
        return habitId == 'snack' || category.contains('snack') || name.contains('snack') || name.contains('nuez') || name.contains('almendra');
      }
      return habitId == _selectedCategory;
    }).toList();
  }

  void _handleFoodTap(CatalogFoodItem item) {
    widget.onAddFood?.call(item);
    final habit = nutritionHabits.firstWhere(
      (h) => h.id == item.habitId,
      orElse: () => nutritionHabits.first,
    );
    widget.onAddHabit(habit);

    setState(() {
      _searchQuery = '';
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final consumedList = _filteredConsumedToday;

    return Column(
      children: [
        // TARJETA PRINCIPAL DE HÁBITOS DIARIOS CON SELECTOR DESPLEGABLE
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainer,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.cardBorder,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.cardShadow,
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.completed} / ${widget.totalGoal} hábitos',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _message,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Progress Bar
              Container(
                width: double.infinity,
                height: 10,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLowest,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _progress,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppTheme.tertiaryMint,
                          AppTheme.tertiaryMintBright,
                          AppTheme.primaryAqua,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.tertiaryMint.withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Botón Rediseñado CTA: "Registrar alimento" (Stitch Design)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    colors: AppTheme.isLightMode
                        ? const [
                            Color(0xFF10B981),
                            Color(0xFF34D399),
                            Color(0xFF6EE7B7),
                          ]
                        : const [
                            AppTheme.tertiaryMint,
                            AppTheme.primaryAqua,
                            AppTheme.secondaryCoral,
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.isLightMode
                          ? const Color(0xFF10B981).withValues(alpha: 0.2)
                          : AppTheme.tertiaryMint.withValues(alpha: 0.22),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(1.2),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _isDropdownOpen = !_isDropdownOpen;
                      });
                    },
                    borderRadius: BorderRadius.circular(16.8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.8),
                        gradient: LinearGradient(
                          colors: AppTheme.isLightMode
                              ? const [
                                  Color(0xFFECFDF5),
                                  Color(0xFFD1FAE5),
                                ]
                              : const [
                                  Color(0xFF172E29),
                                  Color(0xFF122329),
                                ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                colors: AppTheme.isLightMode
                                    ? const [
                                        Color(0xFF10B981),
                                        Color(0xFF059669),
                                      ]
                                    : const [
                                        Color(0xFF10B981),
                                        Color(0xFF2DD4BF),
                                      ],
                                begin: Alignment.bottomLeft,
                                end: Alignment.topRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.add_rounded,
                              color: AppTheme.isLightMode ? Colors.white : const Color(0xFF06231C),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Registrar alimento',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.isLightMode ? const Color(0xFF064E3B) : Colors.white,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Selecciona de tus saludables favoritos',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.isLightMode ? const Color(0xFF047857) : const Color(0xFF6EE7B7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.isLightMode
                                  ? const Color(0xFFA7F3D0).withValues(alpha: 0.5)
                                  : const Color(0xFF042F2E).withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppTheme.isLightMode
                                    ? const Color(0xFF059669).withValues(alpha: 0.3)
                                    : const Color(0xFF14B8A6).withValues(alpha: 0.4),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Catálogo',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.isLightMode ? const Color(0xFF047857) : const Color(0xFF5EEAD4),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                AnimatedRotation(
                                  turns: _isDropdownOpen ? 0.5 : 0.0,
                                  duration: const Duration(milliseconds: 250),
                                  child: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 16,
                                    color: AppTheme.isLightMode ? const Color(0xFF047857) : const Color(0xFF5EEAD4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Lista Desplegable de Alimentos (ExpandedFoodList - Stitch)
              AnimatedCrossFade(
                firstChild: const SizedBox(width: double.infinity),
                secondChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Container(
                      height: 1,
                      color: AppTheme.cardBorder,
                    ),
                    const SizedBox(height: 12),
                    // Buscador de alimentos
                    Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.cardBorder,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val.trim();
                          });
                        },
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Buscar entre los 60+ alimentos (ej: Banana)...',
                          hintStyle: TextStyle(
                            fontSize: 12,
                            color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 16,
                            color: AppTheme.onSurfaceVariant,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                    color: AppTheme.onSurfaceVariant,
                                  ),
                                )
                              : null,
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 9),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Si hay búsqueda activa o filtro de categoría, mostrar catálogo filtrado
                    if (_searchQuery.isNotEmpty || _selectedCategory != 'all') ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'RESULTADOS DEL CATÁLOGO (${_filteredFoods.length})',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _selectedCategory = 'all';
                              });
                            },
                            child: const Text(
                              'Limpiar',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.tertiaryMint,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_filteredFoods.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: Column(
                            children: [
                              const Text('🔍', style: TextStyle(fontSize: 24)),
                              const SizedBox(height: 6),
                              Text(
                                'No se encontraron alimentos para "$_searchQuery"',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _filteredFoods.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = _filteredFoods[index];
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _handleFoodTap(item),
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.isLightMode
                                        ? Colors.white
                                        : const Color(0xFF16242B).withValues(alpha: 0.75),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: item.color.withValues(alpha: 0.25),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: item.color.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: item.color.withValues(alpha: 0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            item.emoji,
                                            style: const TextStyle(fontSize: 18),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    item.name,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 12.5,
                                                      fontWeight: FontWeight.w700,
                                                      color: AppTheme.onSurface,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: item.color.withValues(alpha: 0.2),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    item.categoryLabel,
                                                    style: TextStyle(
                                                      fontSize: 9.5,
                                                      fontWeight: FontWeight.w700,
                                                      color: item.color,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              item.portion,
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w500,
                                                color: AppTheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: item.color.withValues(alpha: 0.18),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: item.color.withValues(alpha: 0.4),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.add_rounded,
                                              size: 14,
                                              color: item.color,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              'Agregar',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: item.color,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 16),
                      Container(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // SECCIÓN PRINCIPAL: COSAS QUE COMÍ HOY
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'COSAS QUE COMÍ HOY',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${widget.consumedToday.length}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF6EE7B7),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${widget.completed}/${widget.totalGoal} hábitos',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    if (widget.consumedToday.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.isLightMode ? Colors.white : AppTheme.surfaceLow.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.cardBorder),
                          boxShadow: [BoxShadow(color: AppTheme.cardShadow, blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Column(
                          children: [
                            const Text('🍽️', style: TextStyle(fontSize: 28)),
                            const SizedBox(height: 8),
                            Text(
                              'Aún no has registrado alimentos hoy',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Busca arriba (ej. Banana, Manzana, Té verde) para sumarlo aquí y avanzar en tus hábitos.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.onSurfaceVariant.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (consumedList.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.isLightMode ? Colors.white : AppTheme.surfaceLow.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.cardBorder),
                          boxShadow: [BoxShadow(color: AppTheme.cardShadow, blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Center(
                          child: Text(
                            'No hay alimentos consumidos hoy en esta categoría',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: consumedList.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = consumedList[index];
                          final name = item['name']?.toString() ?? 'Alimento';
                          final emoji = item['emoji']?.toString() ?? '🍎';
                          final category = item['category']?.toString() ?? '';
                          final portion = item['portion']?.toString() ?? '';
                          final time = item['time']?.toString() ?? '';

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.isLightMode ? Colors.white : const Color(0xFF16242B).withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppTheme.cardBorder,
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(color: AppTheme.cardShadow, blurRadius: 8, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      emoji,
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.onSurface,
                                              ),
                                            ),
                                          ),
                                          if (category.isNotEmpty) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                category,
                                                style: const TextStyle(
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF6EE7B7),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        [portion, time].where((s) => s.isNotEmpty).join(' · '),
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (widget.onRemoveFood != null)
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline_rounded,
                                      size: 18,
                                      color: AppTheme.onSurfaceVariant,
                                    ),
                                    onPressed: () => widget.onRemoveFood!(index),
                                    tooltip: 'Eliminar de hoy',
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
                crossFadeState: _isDropdownOpen
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 280),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // TARJETA ASISTENTE INTELIGENTE
        _IntelligentAssistantCard(
          completed: widget.completed,
          totalGoal: widget.totalGoal,
        ),
        const SizedBox(height: 14),
        // TARJETA "ALIMENTOS DE AYER"
        _YesterdayHabitsCard(
          yesterdayData: widget.yesterdayData,
          goals: widget.goals,
          consumedYesterday: widget.consumedYesterday,
        ),
        const SizedBox(height: 14),
        // TARJETA "TU SEMANA"
        _WeeklyHabitsCard(weeklyData: widget.weeklyData),
      ],
    );
  }
}

class _IntelligentAssistantCard extends StatelessWidget {
  final int completed;
  final int totalGoal;

  const _IntelligentAssistantCard({
    required this.completed,
    required this.totalGoal,
  });

  double get _currentHourFraction {
    final now = DateTime.now();
    final hour = now.hour + (now.minute / 60.0);
    return hour.clamp(7.0, 23.0);
  }

  @override
  Widget build(BuildContext context) {
    final pct = totalGoal <= 0 ? 0 : ((completed / totalGoal) * 100).toInt().clamp(0, 100);
    final target = totalGoal > 0 ? totalGoal : 5;

    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (pct >= 100) {
      statusText = '¡Meta nutricional cumplida! Excelente balance de hábitos 🎉';
      statusColor = AppTheme.tertiaryMint;
      statusIcon = Icons.stars_rounded;
    } else if (pct >= 50) {
      statusText = '¡Buen equilibrio hoy! Vas sumando frescura y vitalidad a tu día 🌱';
      statusColor = AppTheme.tertiaryMint;
      statusIcon = Icons.check_circle_outline_rounded;
    } else if (pct > 0) {
      statusText = 'Progreso suave. Sumar una fruta o infusión elevará tu energía 🍵';
      statusColor = AppTheme.primaryAqua;
      statusIcon = Icons.schedule_rounded;
    } else {
      statusText = 'Aún no has sumado alimentos. Un snack saludable o fruta es un gran comienzo ✨';
      statusColor = AppTheme.secondaryCoral;
      statusIcon = Icons.lightbulb_outline_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.cardBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.cardShadow,
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado con Icono y Título
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.tertiaryMint.withValues(alpha: 0.16),
                  border: Border.all(
                    color: AppTheme.tertiaryMint.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppTheme.tertiaryMint,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Guía Nutricional',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Camino ideal vs. tu progreso actual',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '$pct%',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Leyenda de Caminos (Objetivo vs Real)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.tertiaryMint.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Camino Ideal',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 4,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.6),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Tu Progreso Real',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Gráfico Canvas
          CustomPaint(
            size: const Size(double.infinity, 120),
            painter: _NutritionTimelineChartPainter(
              targetGoal: target,
              actualCompleted: completed,
              currentHourFraction: _currentHourFraction,
              startHour: 7,
              endHour: 23,
              actualColor: statusColor,
            ),
          ),
          const SizedBox(height: 10),

          // Pie de estado amigable
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainer.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Icon(statusIcon, size: 18, color: statusColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.onSurface,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NutritionTimelineChartPainter extends CustomPainter {
  final int targetGoal;
  final int actualCompleted;
  final double currentHourFraction;
  final int startHour;
  final int endHour;
  final Color actualColor;

  _NutritionTimelineChartPainter({
    required this.targetGoal,
    required this.actualCompleted,
    required this.currentHourFraction,
    required this.startHour,
    required this.endHour,
    required this.actualColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paddingBottom = 22.0;
    final paddingTop = 10.0;
    final chartHeight = size.height - paddingBottom - paddingTop;
    final chartWidth = size.width;

    if (chartWidth <= 0 || chartHeight <= 0) return;

    final hourRange = endHour - startHour;
    double hourToX(double hour) {
      final ratio = ((hour - startHour) / hourRange).clamp(0.0, 1.0);
      return ratio * chartWidth;
    }

    double countToY(double val) {
      final ratio = (val / (targetGoal > 0 ? targetGoal : 5)).clamp(0.0, 1.2);
      return size.height - paddingBottom - (ratio * chartHeight);
    }

    // Cuadrícula horizontal
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;

    for (int step = 0; step <= 3; step++) {
      final y = size.height - paddingBottom - (chartHeight * step / 3);
      canvas.drawLine(Offset(0, y), Offset(chartWidth, y), gridPaint);
    }

    // 1. Línea Ideal ("Dónde debería estar")
    final idealPaint = Paint()
      ..color = AppTheme.tertiaryMint.withValues(alpha: 0.35)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final idealFillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.tertiaryMint.withValues(alpha: 0.12),
          AppTheme.tertiaryMint.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, paddingTop, chartWidth, chartHeight));

    final idealPath = Path();
    idealPath.moveTo(0, countToY(0));

    final stepsCount = 20;
    for (int i = 1; i <= stepsCount; i++) {
      final t = i / stepsCount;
      final hour = startHour + (hourRange * t);
      final currentIdeal = targetGoal * t;
      final x = hourToX(hour);
      final y = countToY(currentIdeal);
      idealPath.lineTo(x, y);
    }

    final idealFillPath = Path.from(idealPath)
      ..lineTo(chartWidth, size.height - paddingBottom)
      ..lineTo(0, size.height - paddingBottom)
      ..close();

    canvas.drawPath(idealFillPath, idealFillPaint);
    canvas.drawPath(idealPath, idealPaint);

    // 2. Línea Real ("Tu progreso real")
    final nowX = hourToX(currentHourFraction);
    final actualY = countToY(actualCompleted.toDouble());

    final actualPath = Path();
    actualPath.moveTo(0, countToY(0));

    final currentHourRatio = ((currentHourFraction - startHour) / hourRange).clamp(0.0, 1.0);
    final pointsCount = 10;
    for (int i = 1; i <= pointsCount; i++) {
      final t = (i / pointsCount) * currentHourRatio;
      final hour = startHour + (hourRange * t);
      final x = hourToX(hour);
      final currentVal = actualCompleted * (t / (currentHourRatio > 0 ? currentHourRatio : 1.0));
      final y = countToY(currentVal);
      actualPath.lineTo(x, y);
    }

    final actualGlowPaint = Paint()
      ..color = actualColor.withValues(alpha: 0.6)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);

    final actualLinePaint = Paint()
      ..color = actualColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final actualFillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          actualColor.withValues(alpha: 0.25),
          actualColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, paddingTop, nowX, chartHeight));

    final actualFillPath = Path.from(actualPath)
      ..lineTo(nowX, size.height - paddingBottom)
      ..lineTo(0, size.height - paddingBottom)
      ..close();

    canvas.drawPath(actualFillPath, actualFillPaint);
    canvas.drawPath(actualPath, actualGlowPaint);
    canvas.drawPath(actualPath, actualLinePaint);

    // 3. Indicador Vertical "Ahora"
    final nowLinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(nowX, paddingTop),
      Offset(nowX, size.height - paddingBottom),
      nowLinePaint,
    );

    final dotOuterPaint = Paint()
      ..color = actualColor
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 6);

    final dotInnerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(nowX, actualY), 6, dotOuterPaint);
    canvas.drawCircle(Offset(nowX, actualY), 3.5, dotInnerPaint);

    // 4. Eje de Horas
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final hoursToShow = [startHour, 11, 15, 19, endHour];

    for (final hour in hoursToShow) {
      if (hour < startHour || hour > endHour) continue;
      final x = hourToX(hour.toDouble());
      final timeStr = '${hour.toString().padLeft(2, '0')}:00';

      textPainter.text = TextSpan(
        text: timeStr,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: (hour == currentHourFraction.round()) ? FontWeight.w800 : FontWeight.w500,
          color: (hour == currentHourFraction.round())
              ? AppTheme.tertiaryMint
              : AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - (textPainter.width / 2), size.height - 14),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NutritionTimelineChartPainter oldDelegate) {
    return oldDelegate.actualCompleted != actualCompleted ||
        oldDelegate.targetGoal != targetGoal ||
        oldDelegate.currentHourFraction != currentHourFraction;
  }
}

class _YesterdayHabitsCard extends StatelessWidget {
  final Map<String, int>? yesterdayData;
  final Map<String, int> goals;
  final List<Map<String, dynamic>> consumedYesterday;

  const _YesterdayHabitsCard({
    required this.yesterdayData,
    required this.goals,
    this.consumedYesterday = const [],
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final yesterdayDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));

    final validConsumedYesterday = consumedYesterday.where((item) {
      final tsStr = item['timestamp']?.toString();
      if (tsStr == null) return true;
      final ts = DateTime.tryParse(tsStr);
      if (ts == null) return true;
      return ts.year == yesterdayDate.year &&
          ts.month == yesterdayDate.month &&
          ts.day == yesterdayDate.day;
    }).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.cardBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(color: AppTheme.cardShadow, blurRadius: 14, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.restaurant_menu_rounded,
                color: AppTheme.tertiaryMint,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Alimentos de ayer',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                ),
              ),
              const Spacer(),
              if (validConsumedYesterday.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceHigh,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${validConsumedYesterday.length} consumidos',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.tertiaryMint,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (validConsumedYesterday.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: validConsumedYesterday.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = validConsumedYesterday[index];
                final name = item['name']?.toString() ?? 'Alimento';
                final emoji = item['emoji']?.toString() ?? '🍎';
                final category = item['category']?.toString() ?? '';
                final portion = item['portion']?.toString() ?? '';
                final time = item['time']?.toString() ?? '';

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.isLightMode ? Colors.white : AppTheme.surfaceLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.cardBorder,
                    ),
                    boxShadow: [
                      BoxShadow(color: AppTheme.cardShadow, blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceHigh,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.onSurface,
                              ),
                            ),
                            if (category.isNotEmpty)
                              Text(
                                [category, portion].where((s) => s.isNotEmpty).join(' · '),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (time.isNotEmpty)
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                );
              },
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text('🍽️', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No se registraron alimentos ayer.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _WeeklyHabitsCard extends StatelessWidget {
  final List<int>? weeklyData;

  const _WeeklyHabitsCard({required this.weeklyData});

  @override
  Widget build(BuildContext context) {
    const days = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    final safeData = (weeklyData != null && weeklyData!.length == 7)
        ? weeklyData!
        : List.filled(7, 0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.cardBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(color: AppTheme.cardShadow, blurRadius: 14, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bar_chart_rounded,
                color: AppTheme.tertiaryMint,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Tu semana',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                ),
              ),
              const Spacer(),
              const Text(
                'Ritmo constante',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.tertiaryMint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (index) {
              final val = safeData[index];
              final ratio = val == 0 ? 0.0 : (val / 5).clamp(0.15, 1.0);
              final isToday = index == (DateTime.now().weekday - 1);

              return Column(
                children: [
                  Container(
                    width: 14,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceHighest,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: ratio,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isToday
                              ? AppTheme.tertiaryMint
                              : AppTheme.secondaryCoral,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    days[index],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                      color: isToday
                          ? AppTheme.tertiaryMint
                          : AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

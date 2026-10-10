import 'package:flutter/material.dart';
import '../config/premium_theme.dart';
import '../widgets/workspace_components.dart';

class AllToolsScreen extends StatefulWidget {
  final Function(ToolItem tool)? onSelectTool;

  const AllToolsScreen({
    super.key,
    this.onSelectTool,
  });

  @override
  State<AllToolsScreen> createState() => _AllToolsScreenState();
}

class _AllToolsScreenState extends State<AllToolsScreen> {
  ToolCategory _selectedCategory = ToolCategory.all;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleToolSelected(ToolItem tool) {
    if (widget.onSelectTool != null) {
      widget.onSelectTool!(tool);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => tool.screenBuilder()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;

    int columns = 4;
    if (width < 600) {
      columns = 2;
    } else if (width < 960) {
      columns = 3;
    }

    final tools = ToolItem.allTools.where((tool) {
      if (_selectedCategory != ToolCategory.all &&
          tool.category != _selectedCategory) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        return tool.title.toLowerCase().contains(_searchQuery) ||
            tool.description.toLowerCase().contains(_searchQuery) ||
            tool.category.label.toLowerCase().contains(_searchQuery);
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: isDark
          ? PremiumColors.darkBg
          : PremiumColors.lightBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: width < 600 ? 16 : 24,
            vertical: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'All Tools',
                style: TextStyle(
                  fontSize: width < 600 ? 20 : 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: isDark ? Colors.white : const Color(0xFF1E1E1E),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Explore all offline PDF workflows, editing, and conversion features',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? Colors.grey.shade400
                      : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              // Search input
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? PremiumColors.darkSurfacePrimary
                      : PremiumColors.lightSurfacePrimary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? PremiumColors.darkDivider
                        : PremiumColors.lightDivider,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: PremiumColors.brandRed,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Filter tools by name, action, or format...',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                          filled: false,
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () => _searchController.clear(),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Category filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ToolCategory.values.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              cat.icon,
                              size: 14,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade700),
                            ),
                            const SizedBox(width: 6),
                            Text(cat.label),
                          ],
                        ),
                        onSelected: (_) {
                          setState(() => _selectedCategory = cat);
                        },
                        backgroundColor: isDark
                            ? PremiumColors.darkSurfacePrimary
                            : PremiumColors.lightSurfacePrimary,
                        selectedColor: PremiumColors.brandRed,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                  ? Colors.grey.shade300
                                  : Colors.grey.shade800),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? Colors.transparent
                                : (isDark
                                    ? PremiumColors.darkDivider
                                    : PremiumColors.lightDivider),
                          ),
                        ),
                        showCheckmark: false,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              if (tools.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No tools found matching "${_searchController.text}"',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Try searching for another keyword or switch category',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tools.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: width < 600 ? 1.05 : 1.35,
                  ),
                  itemBuilder: (context, index) {
                    final tool = tools[index];
                    return ToolCard(
                      tool: tool,
                      onTap: () => _handleToolSelected(tool),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

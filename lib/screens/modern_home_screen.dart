import 'package:flutter/material.dart';
import 'package:openpdf_tools/config/premium_theme.dart';
import 'package:openpdf_tools/utils/animation_utils.dart';
import 'package:openpdf_tools/widgets/premium_components.dart';
import 'package:openpdf_tools/widgets/premium_navigation.dart';

/// Modern premium home screen with feature cards and smooth animations
class ModernHomeScreen extends StatefulWidget {
  const ModernHomeScreen({super.key});

  @override
  State<ModernHomeScreen> createState() => _ModernHomeScreenState();
}

class _ModernHomeScreenState extends State<ModernHomeScreen>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _headerFadeController;
  bool _showHeader = true;
  
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _headerFadeController = AnimationController(
      duration: AnimationUtils.standard,
      vsync: this,
    );
    
    _scrollController.addListener(_onScroll);
  }
  
  void _onScroll() {
    if (_scrollController.offset > 50) {
      if (_showHeader) {
        setState(() => _showHeader = false);
        _headerFadeController.reverse();
      }
    } else {
      if (!_showHeader) {
        setState(() => _showHeader = true);
        _headerFadeController.forward();
      }
    }
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _headerFadeController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark
          ? PremiumColors.darkBg
          : PremiumColors.lightBg,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Animated header
          SliverAppBar(
            backgroundColor: isDark
                ? PremiumColors.darkSurfacePrimary
                : PremiumColors.lightSurfacePrimary,
            elevation: 0,
            pinned: true,
            expandedHeight: 220,
            flexibleSpace: FlexibleSpaceBar(
              background: FadeTransition(
                opacity: _headerFadeController.drive(
                  Tween(begin: 1.0, end: 0.3),
                ),
                child: _buildHeaderSection(isDark),
              ),
            ),
          ),
          
          // Main content
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: PremiumSpacing.lg,
              vertical: PremiumSpacing.lg,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Quick access section
                _buildQuickAccessSection(context, isDark),
                const SizedBox(height: PremiumSpacing.xl),
                
                // Feature cards grid
                _buildFeatureCardsGrid(context, isDark),
                const SizedBox(height: PremiumSpacing.xl),
                
                // Recent files section
                _buildRecentFilesSection(context, isDark),
                const SizedBox(height: PremiumSpacing.xl),
              ]),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeaderSection(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            PremiumColors.luxuryRed,
            PremiumColors.luxuryRed.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(PremiumSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome Back',
                style: PremiumTypography.displaySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: PremiumSpacing.sm),
              Text(
                'Manage your PDFs with ease',
                style: PremiumTypography.bodyMedium.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: PremiumSpacing.lg),
              // Search bar in header
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(PremiumSpacing.radiusMd),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search files...',
                    hintStyle: PremiumTypography.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.6),
                    ),
                    border: InputBorder.none,
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: PremiumSpacing.lg,
                      vertical: PremiumSpacing.md,
                    ),
                  ),
                  style: PremiumTypography.bodyMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildQuickAccessSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Access',
          style: PremiumTypography.headlineMedium.copyWith(
            color: isDark
                ? PremiumColors.darkText
                : PremiumColors.lightText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: PremiumSpacing.lg),
        SizedBox(
          height: 140,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildQuickActionCard(
                context,
                icon: Icons.picture_as_pdf,
                label: 'View PDF',
                color: const Color(0xFF5B7BAB),
              ),
              const SizedBox(width: PremiumSpacing.md),
              _buildQuickActionCard(
                context,
                icon: Icons.compress,
                label: 'Compress',
                color: const Color(0xFF6B8E47),
              ),
              const SizedBox(width: PremiumSpacing.md),
              _buildQuickActionCard(
                context,
                icon: Icons.transform,
                label: 'Convert',
                color: const Color(0xFFD4AF37),
              ),
              const SizedBox(width: PremiumSpacing.md),
              _buildQuickActionCard(
                context,
                icon: Icons.edit,
                label: 'Edit PDF',
                color: const Color(0xFF9B59B6),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return CardAnimations.slideInAnimation(
      offset: const Offset(0.2, 0.2),
      child: PremiumGradientCard(
        colors: [color, color.withOpacity(0.8)],
        padding: const EdgeInsets.all(PremiumSpacing.lg),
        onTap: () {
          // Handle tap
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: PremiumSpacing.iconXLarge,
              color: Colors.white,
            ),
            const SizedBox(height: PremiumSpacing.md),
            Text(
              label,
              textAlign: TextAlign.center,
              style: PremiumTypography.labelMedium.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFeatureCardsGrid(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Features',
          style: PremiumTypography.headlineMedium.copyWith(
            color: isDark
                ? PremiumColors.darkText
                : PremiumColors.lightText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: PremiumSpacing.lg),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: PremiumSpacing.lg,
          crossAxisSpacing: PremiumSpacing.lg,
          childAspectRatio: 1.0,
          children: [
            _buildFeatureCard(
              context,
              icon: Icons.auto_awesome,
              title: 'Compress',
              description: 'Reduce file size',
              index: 0,
            ),
            _buildFeatureCard(
              context,
              icon: Icons.picture_as_pdf,
              title: 'Convert',
              description: 'Change formats',
              index: 1,
            ),
            _buildFeatureCard(
              context,
              icon: Icons.edit_document,
              title: 'Edit',
              description: 'Modify PDFs',
              index: 2,
            ),
            _buildFeatureCard(
              context,
              icon: Icons.image,
              title: 'From Image',
              description: 'Create PDFs',
              index: 3,
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required int index,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return CardAnimations.slideInAnimation(
      duration: Duration(
        milliseconds: 300 + (index * 100),
      ),
      offset: const Offset(0.0, 0.5),
      child: PremiumCard(
        enableGlassmorphism: true,
        onTap: () {
          // Handle tap
        },
        backgroundColor: isDark
            ? PremiumColors.darkSurfaceSecondary
            : PremiumColors.lightSurfacePrimary,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(PremiumSpacing.lg),
              decoration: BoxDecoration(
                color: PremiumColors.luxuryRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(PremiumSpacing.radiusLg),
              ),
              child: Icon(
                icon,
                size: PremiumSpacing.iconLarge,
                color: PremiumColors.luxuryRed,
              ),
            ),
            const SizedBox(height: PremiumSpacing.md),
            Text(
              title,
              style: PremiumTypography.labelLarge.copyWith(
                color: isDark
                    ? PremiumColors.darkText
                    : PremiumColors.lightText,
              ),
            ),
            const SizedBox(height: PremiumSpacing.xs),
            Text(
              description,
              style: PremiumTypography.bodySmall.copyWith(
                color: isDark
                    ? PremiumColors.darkTextTertiary
                    : PremiumColors.lightTextTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRecentFilesSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Files',
          style: PremiumTypography.headlineMedium.copyWith(
            color: isDark
                ? PremiumColors.darkText
                : PremiumColors.lightText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: PremiumSpacing.lg),
        ...List.generate(
          3,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: PremiumSpacing.md),
            child: CardAnimations.slideInAnimation(
              duration: Duration(
                milliseconds: 300 + (index * 100),
              ),
              offset: const Offset(0.2, 0.0),
              child: PremiumListTile(
                title: 'Document_${index + 1}.pdf',
                subtitle: '${(index + 1) * 2.5} MB • ${DateTime.now().toString().split(' ')[0]}',
                leadingIcon: Icons.picture_as_pdf_rounded,
                trailingIcon: Icons.more_vert,
                backgroundColor: isDark
                    ? PremiumColors.darkSurfaceSecondary
                    : PremiumColors.lightSurfaceSecondary,
                onTap: () {
                  // Handle file tap
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

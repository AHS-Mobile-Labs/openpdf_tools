# Quick Import Reference Guide

## 🎯 Common Import Patterns

### Theme & Colors
```dart
import 'package:openpdf_tools/config/premium_theme.dart';

// Access colors
PremiumColors.luxuryRed
PremiumColors.darkText
PremiumColors.lightBg

// Access typography
PremiumTypography.displayLarge
PremiumTypography.bodyMedium

// Access spacing
PremiumSpacing.lg  // 16px
PremiumSpacing.md  // 12px

// Create themes
ThemeData lightTheme = createLightTheme();
ThemeData darkTheme = createDarkTheme();
```

---

### Animations
```dart
import 'package:openpdf_tools/utils/animation_utils.dart';

// Page transitions
Navigator.push(context, PageTransitions.slideAndFadeTransition(page));
Navigator.push(context, PageTransitions.fadeTransition(page));
Navigator.push(context, PageTransitions.scaleTransition(page));

// Button animations
ButtonAnimations.scaleOnPress(child: widget, onPressed: () {})
ButtonAnimations.rippleEffect(child: widget, onPressed: () {})

// Card animations
CardAnimations.elevationOnTap(child: card, onTap: () {})
CardAnimations.floatingEffect(child: card)
CardAnimations.slideInAnimation(child: card)

// Loading animations
LoadingAnimations.shimmer(child: skeleton)
LoadingAnimations.pulse(child: widget)

// Animation constants
AnimationUtils.standard    // 300ms
AnimationUtils.smoothCurve // Easing curve
```

---

### UI Components
```dart
import 'package:openpdf_tools/widgets/premium_components.dart';

// Buttons
PremiumButton(
  label: 'Click Me',
  icon: Icons.check,
  onPressed: () {},
)

PremiumOutlinedButton(
  label: 'Cancel',
  onPressed: () {},
)

// Cards
PremiumCard(
  enableGlassmorphism: true,
  child: content,
)

PremiumGradientCard(
  colors: [Color1, Color2],
  child: content,
)

// Input
PremiumTextField(
  label: 'Name',
  hint: 'Enter name',
)

// Selection
PremiumChip(
  label: 'Filter',
  selected: false,
  onSelected: () {},
)

// Loading
SkeletonLoader(width: 100, height: 100)
SkeletonCardLoader(lines: 3)

// Status
PremiumBadge(
  label: 'New',
  icon: Icons.star,
)

// Layout
PremiumDivider(label: 'Or')
PremiumListTile(
  title: 'Item',
  subtitle: 'Subtitle',
)
```

---

### Navigation
```dart
import 'package:openpdf_tools/widgets/premium_navigation.dart';

// Bottom navigation
PremiumBottomNavigation(
  currentIndex: index,
  onTap: (i) => setState(() => index = i),
  items: [
    BottomNavItem(icon: Icons.home, label: 'Home'),
    BottomNavItem(icon: Icons.settings, label: 'Settings'),
  ],
)

// App bar
PremiumAppBar(
  title: 'My Screen',
  showBackButton: true,
  actions: [
    PremiumIconButton(icon: Icons.search, onPressed: () {}),
  ],
)

// Icon button
PremiumIconButton(
  icon: Icons.favorites,
  onPressed: () {},
  color: PremiumColors.luxuryRed,
)
```

---

### Modals & Dialogs
```dart
import 'package:openpdf_tools/utils/modal_manager.dart';

// Alert dialog
PremiumModalManager.showPremiumDialog(
  context,
  child: PremiumAlertDialog(
    title: 'Confirm',
    message: 'Are you sure?',
    confirmLabel: 'Yes',
    onConfirm: () {},
  ),
)

// Bottom sheet
PremiumModalManager.showPremiumBottomSheet(
  context,
  builder: (_) => PremiumBottomSheet(
    title: 'Options',
    child: Column(children: [...]),
  ),
)

// Snackbar
PremiumModalManager.showPremiumSnackBar(
  context,
  message: 'Success!',
  type: SnackBarType.success,
)

// Loading dialog
showDialog(
  context: context,
  builder: (_) => PremiumLoadingDialog(message: 'Loading...'),
)
```

---

## 📦 Complete Import Block

For a new screen containing all elements:

```dart
import 'package:flutter/material.dart';
import 'package:openpdf_tools/config/premium_theme.dart';
import 'package:openpdf_tools/utils/animation_utils.dart';
import 'package:openpdf_tools/widgets/premium_components.dart';
import 'package:openpdf_tools/widgets/premium_navigation.dart';
import 'package:openpdf_tools/utils/modal_manager.dart';

class MyScreen extends StatefulWidget {
  const MyScreen({super.key});

  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: PremiumAppBar(title: 'My Screen'),
      backgroundColor: isDark ? PremiumColors.darkBg : PremiumColors.lightBg,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(PremiumSpacing.lg),
          child: Column(
            children: [
              // Your content here
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## 🔍 Component Import Map

| Component | File | Import |
|-----------|------|--------|
| PremiumButton | premium_components.dart | `import 'package:openpdf_tools/widgets/premium_components.dart';` |
| PremiumCard | premium_components.dart | Same as above |
| PremiumTextField | premium_components.dart | Same as above |
| PremiumBottomNavigation | premium_navigation.dart | `import 'package:openpdf_tools/widgets/premium_navigation.dart';` |
| PageTransitions | animation_utils.dart | `import 'package:openpdf_tools/utils/animation_utils.dart';` |
| PremiumModalManager | modal_manager.dart | `import 'package:openpdf_tools/utils/modal_manager.dart';` |
| PremiumColors | premium_theme.dart | `import 'package:openpdf_tools/config/premium_theme.dart';` |

---

## ⚡ Quick Setup for New Screen

Copy this template:

```dart
import 'package:flutter/material.dart';
import 'package:openpdf_tools/config/premium_theme.dart';
import 'package:openpdf_tools/utils/animation_utils.dart';
import 'package:openpdf_tools/widgets/premium_components.dart';
import 'package:openpdf_tools/widgets/premium_navigation.dart';
import 'package:openpdf_tools/utils/modal_manager.dart';

class NewScreen extends StatefulWidget {
  const NewScreen({super.key});

  @override
  State<NewScreen> createState() => _NewScreenState();
}

class _NewScreenState extends State<NewScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: PremiumAppBar(
        title: 'New Screen',
        showBackButton: true,
      ),
      backgroundColor: isDark ? PremiumColors.darkBg : PremiumColors.lightBg,
      body: _isLoading
          ? Center(child: SkeletonCardLoader())
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.all(PremiumSpacing.lg),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      PremiumCard(
                        child: Column(
                          children: [
                            Text(
                              'Welcome',
                              style: PremiumTypography.headlineSmall,
                            ),
                            SizedBox(height: PremiumSpacing.lg),
                            PremiumButton(
                              label: 'Start',
                              onPressed: () {},
                              fullWidth: true,
                            ),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }
}
```

---

## 🎯 Most Common Import Combinations

### Option 1: Theme Only
```dart
import 'package:openpdf_tools/config/premium_theme.dart';
// For color constants and typography
```

### Option 2: Components Only
```dart
import 'package:openpdf_tools/widgets/premium_components.dart';
import 'package:openpdf_tools/config/premium_theme.dart'; // Always include for spacing
```

### Option 3: Navigation Only
```dart
import 'package:openpdf_tools/widgets/premium_navigation.dart';
import 'package:openpdf_tools/config/premium_theme.dart'; // For colors
```

### Option 4: Full Featured Screen
```dart
import 'package:flutter/material.dart';
import 'package:openpdf_tools/config/premium_theme.dart';
import 'package:openpdf_tools/widgets/premium_components.dart';
import 'package:openpdf_tools/widgets/premium_navigation.dart';
import 'package:openpdf_tools/utils/animation_utils.dart';
import 'package:openpdf_tools/utils/modal_manager.dart';
```

---

## 📝 Import Organization Best Practice

**Recommended order** of imports:

```dart
// 1. Dart imports
import 'dart:async';
import 'dart:io';

// 2. Flutter imports
import 'package:flutter/material.dart';

// 3. Package imports (external)
import 'package:some_package/some_package.dart';

// 4. Project imports (config)
import 'package:openpdf_tools/config/premium_theme.dart';

// 5. Project imports (utils)
import 'package:openpdf_tools/utils/animation_utils.dart';
import 'package:openpdf_tools/utils/modal_manager.dart';

// 6. Project imports (widgets)
import 'package:openpdf_tools/widgets/premium_components.dart';
import 'package:openpdf_tools/widgets/premium_navigation.dart';

// 7. Project imports (screens)
import 'package:openpdf_tools/screens/other_screen.dart';
```

---

## ✅ Pre-Migration Checklist

Before starting screen migration:

- [ ] All imports organized
- [ ] `premium_theme.dart` added to config
- [ ] `animation_utils.dart` added to utils
- [ ] `modal_manager.dart` added to utils
- [ ] `premium_components.dart` added to widgets
- [ ] `premium_navigation.dart` added to widgets
- [ ] `modern_home_screen.dart` reference for examples
- [ ] IDE properly configured
- [ ] Project builds without errors

---

## 🚀 First Screen Migration

To migrate your first screen:

1. Copy template from above
2. Update screen name and imports
3. Replace standard widgets with premium versions
4. Test on device
5. Add animations to lists (optional)
6. Test dark mode
7. Repeat for other screens

---

## 📚 Further Reading

- **Design System**: `PREMIUM_UI_DESIGN_GUIDE.md`
- **Architecture**: `PREMIUM_UI_ARCHITECTURE.md`
- **Checklist**: `PREMIUM_UI_IMPLEMENTATION_CHECKLIST.md`
- **Summary**: `PREMIUM_UI_SUMMARY.md`

---

**Version**: 1.0  
**Date**: February 22, 2026


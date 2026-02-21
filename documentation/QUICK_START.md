# 🚀 Quick Start Guide - Premium UI System

**Time to First Screen**: ~30 minutes  
**Difficulty**: Beginner to Intermediate  

---

## 5-Minute Setup

### Step 1: Theme Integration (5 minutes)

Update `lib/main.dart`:

```dart
import 'package:openpdf_tools/config/premium_theme.dart';

// In OpenPDFToolsApp.build()
return MaterialApp(
  // Replace existing theme with:
  theme: createLightTheme(),
  darkTheme: createDarkTheme(),
  themeMode: ThemeMode.system,
  
  // Keep existing settings
  title: 'OpenPDF Tools',
  debugShowCheckedModeBanner: false,
  home: const ResponsiveHomeScreen(),
);
```

**Done!** Your app now has the premium theme applied globally.

---

## First Component - 10 Minutes

### Replace a Standard Button

**Before:**
```dart
ElevatedButton(
  onPressed: () {},
  child: Text('Compress'),
)
```

**After:**
```dart
import 'package:openpdf_tools/widgets/premium_components.dart';

PremiumButton(
  label: 'Compress',
  icon: Icons.compress,
  onPressed: () {},
)
```

**That's it!** You now have:
- ✅ Smooth scale animation on press
- ✅ Professional gradient
- ✅ Icon support
- ✅ Loading state capability
- ✅ Dark mode support

---

## First Screen - 20 Minutes

### Migrate CompressPdfScreen

**Step 1: Add Imports**
```dart
import 'package:openpdf_tools/config/premium_theme.dart';
import 'package:openpdf_tools/widgets/premium_components.dart';
import 'package:openpdf_tools/widgets/premium_navigation.dart';
```

**Step 2: Replace AppBar**
```dart
// OLD
AppBar(title: Text('Compress PDF'))

// NEW
PremiumAppBar(title: 'Compress PDF', showBackButton: false)
```

**Step 3: Replace Buttons**
```dart
// OLD
ElevatedButton(onPressed: compress, child: Text('Start'))

// NEW
PremiumButton(label: 'Start', icon: Icons.check, onPressed: compress, fullWidth: true)
```

**Step 4: Replace Cards (if any)**
```dart
// OLD
Card(child: content)

// NEW
PremiumCard(child: content, enableGlassmorphism: true)
```

**Step 5: Test**
```bash
flutter run
```

---

## Component Reference (Copy-Paste Ready)

### Button Examples
```dart
// Solid button
PremiumButton(
  label: 'Submit',
  icon: Icons.send,
  onPressed: () {},
  fullWidth: true,
)

// Outlined button
PremiumOutlinedButton(
  label: 'Cancel',
  icon: Icons.close,
  onPressed: () {},
)

// Loading state
PremiumButton(
  label: 'Processing',
  onPressed: () {},
  isLoading: _isProcessing,
)
```

### Card Examples
```dart
// Simple card
PremiumCard(
  padding: EdgeInsets.all(16),
  child: Text('Content'),
)

// Card with tap
PremiumCard(
  onTap: () => Navigator.push(context, ...),
  child: Text('Tap me'),
)

// Gradient card
PremiumGradientCard(
  colors: [Colors.blue, Colors.purple],
  child: Text('Fancy Card'),
)
```

### Input Examples
```dart
// Text field
PremiumTextField(
  label: 'File Path',
  hint: 'Enter PDF path',
  prefixIcon: Icons.folder,
)

// Chip selection
PremiumChip(
  label: 'PDF',
  selected: isSelected,
  onSelected: () => toggleSelection(),
)
```

### Loading Examples
```dart
// Skeleton loader
SkeletonLoader(width: 100, height: 20)

// Card skeleton
SkeletonCardLoader(lines: 3)

// While loading
_isLoading
    ? SkeletonCardLoader()
    : actualContent
```

---

## Color Usage

### Quick Colors Reference
```dart
// Primary (luxury red)
PremiumColors.luxuryRed

// Theme-aware backgrounds
PremiumColors.lightBg      // Light mode
PremiumColors.darkBg       // Dark mode

// Text colors
PremiumColors.lightText        // Primary text
PremiumColors.lightTextSecondary   // Secondary text

// Semantic colors
PremiumColors.success      // Green ✓
PremiumColors.error        // Red ✗
PremiumColors.warning      // Orange ⚠
PremiumColors.info         // Blue ℹ
```

### Theme-Aware Usage
```dart
final isDark = Theme.of(context).brightness == Brightness.dark;

final bgColor = isDark
    ? PremiumColors.darkBg
    : PremiumColors.lightBg;
```

---

## Spacing Cheat Sheet

```dart
// Consistent spacing (4pt grid)
SizedBox(height: PremiumSpacing.xs)       // 4px - tiny gaps
SizedBox(height: PremiumSpacing.sm)       // 8px - small gaps
SizedBox(height: PremiumSpacing.md)       // 12px - medium (inputs)
SizedBox(height: PremiumSpacing.lg)       // 16px - main padding
SizedBox(height: PremiumSpacing.xl)       // 24px - section gap
SizedBox(height: PremiumSpacing.xxl)      // 32px - large sections

// Button height
height: PremiumSpacing.buttonHeight       // 48px

// Border radius
borderRadius: BorderRadius.circular(
  PremiumSpacing.radiusMd                 // 12px
)
```

---

## Animation Quick Reference

### Page Transitions
```dart
// Simple fade
Navigator.push(context, PageTransitions.fadeTransition(page))

// Slide from right
Navigator.push(context, PageTransitions.slideTransition(page))

// Scale from center
Navigator.push(context, PageTransitions.scaleTransition(page))

// Professional (slide + fade)
Navigator.push(context, PageTransitions.slideAndFadeTransition(page))
```

### Widget Animations
```dart
// Button press animation
ButtonAnimations.scaleOnPress(
  child: myButton,
  onPressed: handleTap,
)

// Card elevation on tap
CardAnimations.elevationOnTap(
  child: myCard,
  onTap: handleTap,
)

// Slide-in animation for list
CardAnimations.slideInAnimation(
  duration: Duration(milliseconds: 300 + (index * 100)),
  child: listItem,
)
```

### Loading & Status
```dart
// Shimmer effect
LoadingAnimations.shimmer(child: skeleton)

// Pulsing animation
LoadingAnimations.pulse(child: widget)
```

---

## Dialog & Notification Examples

### Success Message
```dart
PremiumModalManager.showPremiumSnackBar(
  context,
  message: 'PDF compressed successfully!',
  type: SnackBarType.success,
)
```

### Confirmation Dialog
```dart
PremiumModalManager.showPremiumDialog(
  context,
  child: PremiumAlertDialog(
    title: 'Delete?',
    message: 'Are you sure?',
    confirmLabel: 'Delete',
    onConfirm: deleteItem,
  ),
)
```

### Loading Indicator
```dart
showDialog(
  context: context,
  barrierDismissible: false,
  builder: (_) => PremiumLoadingDialog(message: 'Processing...'),
)
```

---

## Typography Quick Reference

```dart
// Headings
Text('Title', style: PremiumTypography.displayLarge)      // 32px, bold
Text('Section', style: PremiumTypography.headlineSmall)   // 16px, semibold

// Body text
Text('Content', style: PremiumTypography.bodyLarge)       // 16px, regular
Text('Caption', style: PremiumTypography.bodySmall)       // 12px, regular

// Labels
Text('Button', style: PremiumTypography.labelLarge)       // 14px, semibold
Text('Chip', style: PremiumTypography.labelSmall)         // 11px, semibold
```

---

## Complete Screen Example

```dart
import 'package:flutter/material.dart';
import 'package:openpdf_tools/config/premium_theme.dart';
import 'package:openpdf_tools/widgets/premium_components.dart';
import 'package:openpdf_tools/widgets/premium_navigation.dart';

class CompressExampleScreen extends StatefulWidget {
  const CompressExampleScreen({super.key});

  @override
  State<CompressExampleScreen> createState() => _CompressExampleScreenState();
}

class _CompressExampleScreenState extends State<CompressExampleScreen> {
  String? _selectedFile;
  bool _isProcessing = false;

  Future<void> _compress() async {
    setState(() => _isProcessing = true);
    
    try {
      // Do compression work
      await Future.delayed(Duration(seconds: 2));
      
      // Show success
      PremiumModalManager.showPremiumSnackBar(
        context,
        message: 'Compressed successfully!',
        type: SnackBarType.success,
      );
    } catch (e) {
      PremiumModalManager.showPremiumSnackBar(
        context,
        message: 'Error: $e',
        type: SnackBarType.error,
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: PremiumAppBar(
        title: 'Compress PDF',
        showBackButton: true,
      ),
      backgroundColor: isDark 
          ? PremiumColors.darkBg 
          : PremiumColors.lightBg,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(PremiumSpacing.lg),
          child: Column(
            children: [
              // File selector
              PremiumCard(
                onTap: () {
                  // File selection logic
                  setState(() => _selectedFile = 'document.pdf');
                },
                child: Padding(
                  padding: EdgeInsets.all(PremiumSpacing.lg),
                  child: Column(
                    children: [
                      Icon(
                        Icons.picture_as_pdf,
                        size: 48,
                        color: PremiumColors.luxuryRed,
                      ),
                      SizedBox(height: PremiumSpacing.md),
                      Text(
                        _selectedFile ?? 'No file selected',
                        style: PremiumTypography.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: PremiumSpacing.xl),
              
              // Compression level selector
              Text(
                'Quality Level',
                style: PremiumTypography.labelLarge,
              ),
              SizedBox(height: PremiumSpacing.md),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  PremiumChip(
                    label: 'High',
                    selected: true,
                    onSelected: () {},
                  ),
                  PremiumChip(
                    label: 'Medium',
                    selected: false,
                    onSelected: () {},
                  ),
                  PremiumChip(
                    label: 'Low',
                    selected: false,
                    onSelected: () {},
                  ),
                ],
              ),
              
              SizedBox(height: PremiumSpacing.xl),
              
              // Action buttons
              PremiumButton(
                label: 'Compress PDF',
                icon: Icons.compress,
                onPressed: _compress,
                isLoading: _isProcessing,
                fullWidth: true,
              ),
              
              SizedBox(height: PremiumSpacing.md),
              
              PremiumOutlinedButton(
                label: 'Cancel',
                onPressed: () => Navigator.pop(context),
                fullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## Troubleshooting

### Issue: Widgets not showing color
**Solution**: Make sure you're inside a `Scaffold` with proper `backgroundColor`

### Issue: Animations look janky
**Solution**: Check animation durations in `AnimationUtils` match your app's performance

### Issue: Dark mode not working
**Solution**: Ensure `themeMode: ThemeMode.system` in MaterialApp

### Issue: Import errors
**Solution**: Check files exist in correct paths:
- `lib/config/premium_theme.dart`
- `lib/utils/animation_utils.dart`
- `lib/widgets/premium_components.dart`
- `lib/widgets/premium_navigation.dart`

---

## Next Steps

1. ✅ **Integrate theme** (5 min)
2. ✅ **Replace one button** (5 min)
3. ✅ **Migrate one screen** (20 min)
4. ➡️ **Progressively migrate remaining screens**
5. ➡️ **Add animations to lists**
6. ➡️ **Polish and refine**

---

## Documentation Reference

Need more details? Check these:

- **Colors & Fonts**: [PREMIUM_UI_DESIGN_GUIDE.md](PREMIUM_UI_DESIGN_GUIDE.md)
- **Architecture**: [PREMIUM_UI_ARCHITECTURE.md](PREMIUM_UI_ARCHITECTURE.md)
- **Full Checklist**: [PREMIUM_UI_IMPLEMENTATION_CHECKLIST.md](PREMIUM_UI_IMPLEMENTATION_CHECKLIST.md)
- **Import Guide**: [IMPORT_REFERENCE.md](IMPORT_REFERENCE.md)
- **Complete Summary**: [PREMIUM_UI_SUMMARY.md](PREMIUM_UI_SUMMARY.md)

---

## 🎉 You're Ready!

You now have everything needed to transform your app into a premium, modern experience. Start with Step 1 above and migrate one screen at a time.

**Happy coding!** 🚀

---

**Version**: 1.0  
**Date**: February 22, 2026


#!/bin/bash

# Script de migration ForUi API 0.10
# Remplace automatiquement les patterns connus

echo "🔧 Starting ForUi 0.10 API Migration..."
echo ""

# Compteurs
TOTAL_FILES=0
TOTAL_REPLACEMENTS=0

# 1. Fix FText → Text (simple replacement, safe)
echo "📝 Step 1/4: Replacing FText with Text..."
FILES_FTEXT=$(grep -rl "FText(" lib/features/ 2>/dev/null | wc -l)
if [ "$FILES_FTEXT" -gt 0 ]; then
    find lib/features/ -type f -name "*.dart" -exec sed -i 's/FText(/Text(/g' {} \;
    echo "✅ Replaced FText in $FILES_FTEXT files"
    TOTAL_REPLACEMENTS=$((TOTAL_REPLACEMENTS + FILES_FTEXT))
else
    echo "✅ No FText found"
fi
echo ""

# 2. Fix FBadge label parameter (String → Text(String))
echo "📝 Step 2/4: Fixing FBadge label parameter..."
# This is more complex, showing manual fix needed
FILES_FBADGE=$(grep -rl "FBadge(" lib/features/ 2>/dev/null | wc -l)
if [ "$FILES_FBADGE" -gt 0 ]; then
    echo "⚠️  Found $FILES_FBADGE files with FBadge - MANUAL FIX REQUIRED"
    echo "   Pattern: FBadge(label: 'text') → FBadge(label: Text('text'))"
    grep -n "FBadge(" lib/features/**/*.dart 2>/dev/null | head -5
else
    echo "✅ No FBadge found"
fi
echo ""

# 3. Fix Responsive(context) → Static calls
echo "📝 Step 3/4: Fixing Responsive calls..."
FILES_RESP=$(grep -rl "Responsive(context)" lib/ 2>/dev/null | wc -l)
if [ "$FILES_RESP" -gt 0 ]; then
    echo "⚠️  Found $FILES_RESP files with Responsive(context) - MANUAL FIX REQUIRED"
    echo "   Files to fix:"
    grep -l "Responsive(context)" lib/**/*.dart 2>/dev/null
    echo ""
    echo "   Patterns to replace:"
    echo "   • responsive.spacing(4) → Responsive.spacing(context, multiplier: 4)"
    echo "   • responsive.isMobile → Responsive.isMobile(context)"
    echo "   • responsive.iconSize(24) → Responsive.iconSize(context, base: 24)"
else
    echo "✅ No Responsive(context) found"
fi
echo ""

# 4. Report FCard and FButton issues
echo "📝 Step 4/4: Analyzing FCard and FButton usage..."
FILES_FCARD=$(grep -rl "FCard(" lib/features/ 2>/dev/null | wc -l)
FILES_FBUTTON=$(grep -rl "FButton(" lib/features/ 2>/dev/null | wc -l)

echo "⚠️  Found $FILES_FCARD files with FCard - MANUAL FIX REQUIRED"
echo "   Common fixes:"
echo "   • FCard(padding: ...) → FCard.raw(child: Padding(...))"
echo "   • FCard(decoration: ...) → Remove decoration, use FCard.raw with Container"
echo ""

echo "⚠️  Found $FILES_FBUTTON files with FButton - MANUAL FIX REQUIRED"
echo "   Common fixes:"
echo "   • style: FButtonStyle.primary → style: Variant.primary"
echo "   • Remove 'design: FButtonCustomStyle(...)' parameter"
echo "   • label: Widget with icon → Use prefix: Icon(...)"
echo ""

# Summary
echo "========================================="
echo "📊 MIGRATION SUMMARY"
echo "========================================="
echo "✅ Automatic fixes applied: $TOTAL_REPLACEMENTS"
echo ""
echo "⚠️  Manual fixes needed:"
echo "  • Responsive calls: $FILES_RESP files"
echo "  • FBadge parameters: $FILES_FBADGE files"
echo "  • FCard API: $FILES_FCARD files"
echo "  • FButton API: $FILES_FBUTTON files"
echo ""
echo "📖 See FORUI_MIGRATION_REPORT.md for detailed instructions"
echo ""
echo "🎯 Next steps:"
echo "  1. Review changes: git diff"
echo "  2. Fix remaining manual issues using the report"
echo "  3. Run: flutter analyze"
echo "  4. Run: flutter build apk --debug"
echo ""

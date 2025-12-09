#!/bin/bash

# Script pour corriger automatiquement tous les fichiers pour Forui 0.16.0
# Ce script applique les corrections suivantes:
# 1. Supprime les imports FluentUI Icons
# 2. Remplace FluentIcons par FIcons (Material Icons fallback)
# 3. Corrige theme.colorScheme -> theme.colors
# 4. Corrige theme.borderRadius -> theme.style.borderRadius
# 5. Corrige Responsive
# 6. Corrige FButton (onPress -> onPressed, label -> child)
# 7. Corrige FBadge (label -> child)
# 8. Corrige FScaffold (content doit être List<Widget>)
# 9. Corrige IconButton (onPress -> onPressed)

# Dossier contenant les fichiers à corriger
TARGET_DIR="C:/Users/clems/Desktop/Code/mobile/lib/features"

# Fonction pour appliquer les corrections sur un fichier
fix_file() {
    local file="$1"
    echo "Correction de: $file"

    # 1. Supprimer les imports FluentUI
    sed -i "/import 'package:fluentui_icons\/fluentui_icons.dart';/d" "$file"

    # 2. Remplacer FluentIcons par FIcons (mappings courants)
    sed -i 's/FluentIcons\.arrow_left_24_regular/FIcons.arrowLeft/g' "$file"
    sed -i 's/FluentIcons\.arrow_right_24_regular/FIcons.arrowRight/g' "$file"
    sed -i 's/FluentIcons\.sign_out_24_regular/FIcons.logOut/g' "$file"
    sed -i 's/FluentIcons\.drawer_24_filled/FIcons.package/g' "$file"
    sed -i 's/FluentIcons\.person_24_filled/FIcons.user/g' "$file"
    sed -i 's/FluentIcons\.person_24_regular/FIcons.user/g' "$file"
    sed -i 's/FluentIcons\.tablet_24_filled/FIcons.tablet/g' "$file"
    sed -i 's/FluentIcons\.checkmark_circle_24_filled/FIcons.checkCircle/g' "$file"
    sed -i 's/FluentIcons\.checkmark_24_filled/FIcons.check/g' "$file"
    sed -i 's/FluentIcons\.dismiss_24_regular/FIcons.x/g' "$file"
    sed -i 's/FluentIcons\.add_24_filled/FIcons.plus/g' "$file"
    sed -i 's/FluentIcons\.add_24_regular/FIcons.plus/g' "$file"
    sed -i 's/FluentIcons\.subtract_24_regular/FIcons.minus/g' "$file"
    sed -i 's/FluentIcons\.search_24_regular/FIcons.search/g' "$file"
    sed -i 's/FluentIcons\.box_24_regular/FIcons.package/g' "$file"
    sed -i 's/FluentIcons\.box_24_filled/FIcons.package/g' "$file"
    sed -i 's/FluentIcons\.shopping_bag_24_regular/FIcons.shoppingBag/g' "$file"
    sed -i 's/FluentIcons\.shopping_bag_24_filled/FIcons.shoppingBag/g' "$file"
    sed -i 's/FluentIcons\.cart_24_filled/FIcons.shoppingCart/g' "$file"
    sed -i 's/FluentIcons\.people_24_regular/FIcons.users/g' "$file"
    sed -i 's/FluentIcons\.people_24_filled/FIcons.users/g' "$file"
    sed -i 's/FluentIcons\.edit_24_regular/FIcons.edit/g' "$file"
    sed -i 's/FluentIcons\.delete_24_regular/FIcons.trash2/g' "$file"
    sed -i 's/FluentIcons\.more_vertical_24_regular/FIcons.moreVertical/g' "$file"
    sed -i 's/FluentIcons\.settings_24_regular/FIcons.settings/g' "$file"
    sed -i 's/FluentIcons\.settings_24_filled/FIcons.settings/g' "$file"
    sed -i 's/FluentIcons\.info_24_filled/FIcons.info/g' "$file"
    sed -i 's/FluentIcons\.error_circle_24_regular/FIcons.alertCircle/g' "$file"
    sed -i 's/FluentIcons\.arrow_sync_24_regular/FIcons.refreshCw/g' "$file"
    sed -i 's/FluentIcons\.arrow_sync_checkmark_24_regular/FIcons.refreshCw/g' "$file"
    sed -i 's/FluentIcons\.wifi_1_24_filled/FIcons.wifi/g' "$file"
    sed -i 's/FluentIcons\.wifi_off_24_regular/FIcons.wifiOff/g' "$file"
    sed -i 's/FluentIcons\.navigation_24_regular/FIcons.menu/g' "$file"
    sed -i 's/FluentIcons\.building_retail_24_filled/FIcons.store/g' "$file"
    sed -i 's/FluentIcons\.wallet_24_regular/FIcons.wallet/g' "$file"
    sed -i 's/FluentIcons\.wallet_24_filled/FIcons.wallet/g' "$file"
    sed -i 's/FluentIcons\.cube_24_regular/FIcons.box/g' "$file"
    sed -i 's/FluentIcons\.cube_24_filled/FIcons.box/g' "$file"
    sed -i 's/FluentIcons\.document_data_24_regular/FIcons.fileText/g' "$file"
    sed -i 's/FluentIcons\.document_data_24_filled/FIcons.fileText/g' "$file"
    sed -i 's/FluentIcons\.chevron_right_24_regular/FIcons.chevronRight/g' "$file"
    sed -i 's/FluentIcons\.chevron_up_24_regular/FIcons.chevronUp/g' "$file"
    sed -i 's/FluentIcons\.chevron_down_24_regular/FIcons.chevronDown/g' "$file"
    sed -i 's/FluentIcons\.arrow_undo_24_regular/FIcons.cornerUpLeft/g' "$file"
    sed -i 's/FluentIcons\.arrow_clockwise_24_regular/FIcons.refreshCw/g' "$file"
    sed -i 's/FluentIcons\.money_24_filled/FIcons.dollarSign/g' "$file"
    sed -i 's/FluentIcons\.money_24_regular/FIcons.dollarSign/g' "$file"
    sed -i 's/FluentIcons\.receipt_24_regular/FIcons.receipt/g' "$file"
    sed -i 's/FluentIcons\.mail_24_regular/FIcons.mail/g' "$file"
    sed -i 's/FluentIcons\.phone_24_regular/FIcons.phone/g' "$file"
    sed -i 's/FluentIcons\.location_24_regular/FIcons.mapPin/g' "$file"
    sed -i 's/FluentIcons\.filter_24_filled/FIcons.filter/g' "$file"
    sed -i 's/FluentIcons\.filter_24_regular/FIcons.filter/g' "$file"
    sed -i 's/FluentIcons\.lock_closed_24_filled/FIcons.lock/g' "$file"
    sed -i 's/FluentIcons\.document_bullet_list_24_filled/FIcons.list/g' "$file"
    sed -i 's/FluentIcons\.arrow_circle_up_24_regular/FIcons.arrowUpCircle/g' "$file"
    sed -i 's/FluentIcons\.money_hand_24_regular/FIcons.dollarSign/g' "$file"
    sed -i 's/FluentIcons\.arrow_trending_down_24_filled/FIcons.trendingDown/g' "$file"
    sed -i 's/FluentIcons\.arrow_trending_up_24_filled/FIcons.trendingUp/g' "$file"
    sed -i 's/FluentIcons\.warning_24_filled/FIcons.alertTriangle/g' "$file"
    sed -i 's/FluentIcons\.paint_brush_24_filled/FIcons.palette/g' "$file"
    sed -i 's/FluentIcons\.weather_moon_24_filled/FIcons.moon/g' "$file"
    sed -i 's/FluentIcons\.weather_sunny_24_filled/FIcons.sun/g' "$file"
    sed -i 's/FluentIcons\.local_language_24_filled/FIcons.globe/g' "$file"
    sed -i 's/FluentIcons\.arrow_sync_circle_24_regular/FIcons.refreshCw/g' "$file"
    sed -i 's/FluentIcons\.timer_24_regular/FIcons.clock/g' "$file"
    sed -i 's/FluentIcons\.building_shop_24_filled/FIcons.store/g' "$file"
    sed -i 's/FluentIcons\.code_24_regular/FIcons.code/g' "$file"
    sed -i 's/FluentIcons\.document_text_24_regular/FIcons.fileText/g' "$file"
    sed -i 's/FluentIcons\.shield_checkmark_24_regular/FIcons.shield/g' "$file"
    sed -i 's/FluentIcons\.food_24_filled/FIcons.coffee/g' "$file"
    sed -i 's/FluentIcons\.shifts_add_24_filled/FIcons.plus/g' "$file"
    sed -i 's/FluentIcons\.laptop_24_filled/FIcons.laptop/g' "$file"
    sed -i 's/FluentIcons\.shirt_24_filled/Icons.checkroom/g' "$file"
    sed -i 's/FluentIcons\.apps_24_filled/FIcons.grid/g' "$file"
    sed -i 's/FluentIcons\.circle_24_regular/FIcons.circle/g' "$file"
    sed -i 's/FluentIcons\.text_description_24_regular/FIcons.fileText/g' "$file"
    sed -i 's/FluentIcons\.barcode_scanner_24_regular/FIcons.maximize/g' "$file"
    sed -i 's/FluentIcons\.barcode_scanner_24_filled/FIcons.maximize/g' "$file"
    sed -i 's/FluentIcons\.box_checkmark_24_filled/FIcons.packageCheck/g' "$file"
    sed -i 's/FluentIcons\.camera_add_24_regular/FIcons.camera/g' "$file"

    # 3. Corriger theme.colorScheme -> theme.colors
    sed -i 's/theme\.colorScheme\./theme.colors./g' "$file"

    # 4. Corriger theme.borderRadius -> theme.style.borderRadius
    sed -i 's/theme\.borderRadius/theme.style.borderRadius/g' "$file"

    # 5. Corriger IconButton onPress -> onPressed
    sed -i 's/IconButton(\([^)]*\)onPress:/IconButton(\1onPressed:/g' "$file"

    # Notifier
    echo "✓ Fichier corrigé: $file"
}

# Parcourir tous les fichiers .dart dans le dossier features
find "$TARGET_DIR" -name "*.dart" -type f | while read -r file; do
    fix_file "$file"
done

echo ""
echo "======================================"
echo "Toutes les corrections ont été appliquées!"
echo "======================================"
echo ""
echo "ATTENTION: Corrections manuelles restantes à effectuer:"
echo "1. FButton: remplacer 'label:' par 'child:' et 'onPress:' par 'onPressed:'"
echo "2. FBadge: remplacer 'label:' par 'child:'"
echo "3. FScaffold: 'content:' doit être une List<Widget>, pas un Widget unique"
echo "4. FCard: utiliser FCard.raw(child: ...) au lieu de paramètres complexes"
echo "5. FTextField: vérifier et enlever paramètres non supportés"
echo "6. Responsive: utiliser Responsive.spacing(context, multiplier: x)"
echo ""

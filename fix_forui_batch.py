#!/usr/bin/env python3
"""
Script de correction automatique pour ForUi 0.15
Corrige tous les fichiers features/*.dart pour API ForUi 0.15
"""

import os
import re
from pathlib import Path

# Chemin de base
BASE_DIR = Path(__file__).parent / "lib" / "features"

# Compteurs
files_modified = 0
total_changes = 0

def fix_fbutton_onpressed(content):
    """Corrige onPressed → onPress"""
    count = content.count("onPressed:")
    content = content.replace("onPressed:", "onPress:")
    return content, count

def fix_fbuttonstyle(content):
    """Corrige FButtonStyle → Variant"""
    count = 0
    replacements = [
        (r'FButtonStyle\.primary', 'Variant.primary'),
        (r'FButtonStyle\.outline', 'Variant.outline'),
        (r'FButtonStyle\.destructive', 'Variant.destructive'),
    ]
    for pattern, replacement in replacements:
        matches = len(re.findall(pattern, content))
        count += matches
        content = re.sub(pattern, replacement, content)
    return content, count

def remove_design_parameter(content):
    """Supprime le paramètre design: de FButton"""
    # Pattern pour trouver design: FButtonCustomStyle(...)
    pattern = r',\s*design:\s*FButtonCustomStyle\([^)]*\)'
    count = len(re.findall(pattern, content))
    content = re.sub(pattern, '', content)
    return content, count

def fix_fbutton_label_string(content):
    """Corrige label: 'text' → label: const Text('text')"""
    # Pattern: label: 'something'
    pattern = r"label:\s*'([^']+)'"
    matches = re.findall(pattern, content)
    count = len(matches)

    def replace_label(match):
        text = match.group(1)
        return f"label: const Text('{text}')"

    content = re.sub(pattern, replace_label, content)
    return content, count

def fix_ftextfield_label_string(content):
    """Corrige FTextField label: 'text' → label: const Text('text')"""
    # Chercher FTextField avec label String
    # Pattern plus complexe pour éviter les faux positifs
    lines = content.split('\n')
    modified_lines = []
    changes = 0
    in_ftextfield = False

    for line in lines:
        if 'FTextField(' in line:
            in_ftextfield = True

        if in_ftextfield and re.search(r"label:\s*'([^']+)'", line):
            match = re.search(r"label:\s*'([^']+)'", line)
            if match:
                text = match.group(1)
                line = re.sub(r"label:\s*'[^']+'", f"label: const Text('{text}')", line)
                changes += 1

        if in_ftextfield and ')' in line:
            in_ftextfield = False

        modified_lines.append(line)

    return '\n'.join(modified_lines), changes

def process_file(filepath):
    """Traite un fichier Dart"""
    global files_modified, total_changes

    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        original_content = content
        file_changes = 0

        # Appliquer les corrections
        content, count = fix_fbutton_onpressed(content)
        file_changes += count

        content, count = fix_fbuttonstyle(content)
        file_changes += count

        content, count = remove_design_parameter(content)
        file_changes += count

        content, count = fix_fbutton_label_string(content)
        file_changes += count

        content, count = fix_ftextfield_label_string(content)
        file_changes += count

        # Sauvegarder si modifié
        if content != original_content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)

            files_modified += 1
            total_changes += file_changes
            print(f"✅ {filepath.relative_to(BASE_DIR.parent.parent)}: {file_changes} corrections")

    except Exception as e:
        print(f"❌ Erreur sur {filepath}: {e}")

def main():
    print("🔧 Correction automatique ForUi 0.15")
    print(f"📁 Dossier: {BASE_DIR}")
    print("-" * 60)

    # Trouver tous les fichiers .dart
    dart_files = list(BASE_DIR.rglob("*.dart"))

    if not dart_files:
        print("❌ Aucun fichier .dart trouvé")
        return

    print(f"📝 {len(dart_files)} fichiers à traiter\n")

    for filepath in sorted(dart_files):
        process_file(filepath)

    print("\n" + "=" * 60)
    print(f"✅ Terminé!")
    print(f"📊 Fichiers modifiés: {files_modified}/{len(dart_files)}")
    print(f"🔧 Total corrections: {total_changes}")
    print("\n⚠️  Corrections manuelles restantes:")
    print("  - FCard(padding:...) → FCard.raw(child: Padding(...))")
    print("  - Supprimer decoration: sur FTextField")
    print("  - Vérifier FBadge text → label")
    print("\n🚀 Exécuter: flutter analyze")

if __name__ == "__main__":
    main()

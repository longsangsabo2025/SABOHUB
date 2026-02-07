#!/usr/bin/env python3
"""
SABOHUB Codebase Restructuring Script
Reorganizes lib/ into business_types/ architecture for multi-company scalability.

Usage: python migrate_codebase.py
Rollback: git checkout -- sabohub-app/SABOHUB/lib/
"""

import os
import re
import sys
from pathlib import Path

LIB = Path(r"d:\0.PROJECTS\02-SABO-ECOSYSTEM\sabo-hub\sabohub-app\SABOHUB\lib")
PACKAGE_NAME = "flutter_sabohub"

# Regex to match import/export/part statements
IMPORT_RE = re.compile(
    r"""^(\s*(?:import|export|part)\s+['"])([^'"]+)(['"].*)$""",
    re.MULTILINE
)


def all_dart_files():
    """Discover all .dart files under lib/, return paths relative to lib/"""
    files = []
    for root, _, filenames in os.walk(LIB):
        for f in filenames:
            if f.endswith('.dart'):
                rel = os.path.relpath(os.path.join(root, f), LIB).replace('\\', '/')
                files.append(rel)
    return sorted(files)


def classify(p):
    """
    Classify a file path (relative to lib/) into a business type category.
    Returns: 'distribution', 'entertainment', 'manufacturing', or None (shared/platform)
    """
    name = p.split('/')[-1]
    lo = p.lower()

    # ==================== DISTRIBUTION ====================

    # Distribution layout files (distribution_*_layout.dart)
    if lo.startswith('layouts/distribution_'):
        return 'distribution'

    # Distribution subdirectories in layouts/
    for d in ['layouts/sales/', 'layouts/warehouse/', 'layouts/cskh/', 'layouts/manager/']:
        if lo.startswith(d):
            return 'distribution'

    # Distribution page directories
    dist_page_dirs = [
        'pages/distribution_manager/',
        'pages/driver/',
        'pages/sales/',
        'pages/finance/',
        'pages/deliveries/',
        'pages/receivables/',
    ]
    for d in dist_page_dirs:
        if lo.startswith(d):
            return 'distribution'

    # Odori screens
    if lo.startswith('screens/odori/') or lo.startswith('screens/dms/'):
        return 'distribution'

    # Odori-prefixed models
    if lo.startswith('models/') and name.startswith('odori_'):
        return 'distribution'

    # Product sample model (distribution feature)
    if lo == 'models/product_sample.dart':
        return 'distribution'

    # Odori-prefixed services
    if lo.startswith('services/') and name.startswith('odori_'):
        return 'distribution'

    # Specific distribution services
    dist_services = {
        'sales_route_service.dart',
        'sell_in_sell_out_service.dart',
        'sales_features_service.dart',
        'sales_features_integration.dart',
        'store_visit_service.dart',
    }
    if lo.startswith('services/') and name in dist_services:
        return 'distribution'

    # Distribution providers
    if lo == 'providers/odori_providers.dart':
        return 'distribution'

    # Distribution widgets
    if lo.startswith('widgets/') and name.startswith('sales_features_widgets'):
        return 'distribution'

    # Specific distribution pages in shared directories
    dist_specific_pages = {
        'pages/products/odori_products_page.dart',
        'pages/products/product_samples_page.dart',
        'pages/customers/odori_customers_page.dart',
        'pages/orders/odori_orders_page.dart',
    }
    if lo in dist_specific_pages:
        return 'distribution'

    # ==================== ENTERTAINMENT ====================

    for d in ['pages/tables/', 'pages/sessions/', 'pages/menu/']:
        if lo.startswith(d):
            return 'entertainment'

    ent_models = {'table.dart', 'table_new.dart', 'session.dart', 'menu_item.dart',
                  'bill.dart', 'bill_commission.dart'}
    if lo.startswith('models/') and name in ent_models:
        return 'entertainment'

    ent_services = {'table_service.dart', 'session_service.dart', 'menu_service.dart',
                    'bill_service.dart'}
    if lo.startswith('services/') and name in ent_services:
        return 'entertainment'

    ent_providers = {'table_provider.dart', 'session_provider.dart', 'menu_provider.dart'}
    if lo.startswith('providers/') and name in ent_providers:
        return 'entertainment'

    # ==================== MANUFACTURING ====================

    if lo.startswith('pages/manufacturing/'):
        return 'manufacturing'
    if lo == 'models/manufacturing_models.dart':
        return 'manufacturing'
    if lo == 'services/manufacturing_service.dart':
        return 'manufacturing'

    return None  # Shared / Platform


def compute_new_path(p, cat):
    """Compute the new path for a classified file"""
    if cat is None:
        return p  # No move

    prefix = f'business_types/{cat}/'

    # Special: distribution_manager → manager
    if cat == 'distribution' and p.startswith('pages/distribution_manager/'):
        return prefix + p.replace('pages/distribution_manager/', 'pages/manager/', 1)

    # Special: screens/odori/ → screens/ (flatten odori)
    if cat == 'distribution' and p.startswith('screens/odori/'):
        return prefix + p.replace('screens/odori/', 'screens/', 1)

    # Default: prepend business_types/{cat}/
    return prefix + p


def build_move_map(files):
    """Build {old_rel: new_rel} mapping for files that need to move"""
    moves = {}
    for f in files:
        cat = classify(f)
        np = compute_new_path(f, cat)
        if np != f:
            moves[f] = np
    return moves


def fix_imports(content, old_dir, new_dir, abs_move_map):
    """
    Fix import/export/part paths in file content.
    
    old_dir: absolute directory where the file CURRENTLY lives
    new_dir: absolute directory where the file WILL live
    abs_move_map: {old_abs_path_norm: new_abs_path_norm} for moved files
    """

    def replacer(m):
        pre, path, suf = m.group(1), m.group(2), m.group(3)

        # Skip external package and dart SDK imports
        if path.startswith('dart:'):
            return m.group(0)

        # Handle same-package package: imports
        pkg_prefix = f'package:{PACKAGE_NAME}/'
        if path.startswith(pkg_prefix):
            # Resolve to absolute path
            pkg_rel = path[len(pkg_prefix):]
            target = os.path.normpath(str(LIB / pkg_rel))
            target_new = abs_move_map.get(target, target)
            # Compute new package-relative path
            new_pkg_rel = os.path.relpath(target_new, LIB).replace('\\', '/')
            return pre + pkg_prefix + new_pkg_rel + suf

        # Skip other package: imports
        if path.startswith('package:'):
            return m.group(0)

        # Relative import — resolve to absolute using OLD directory
        target = os.path.normpath(os.path.join(old_dir, path))

        # Get target's new location (or unchanged if not moved)
        target_new = abs_move_map.get(target, target)

        # Compute new relative path from NEW directory to new target
        rel = os.path.relpath(target_new, new_dir).replace('\\', '/')

        return pre + rel + suf

    return IMPORT_RE.sub(replacer, content)


def main():
    print("=" * 60)
    print("  SABOHUB Codebase Restructuring")
    print("  business_types/ architecture migration")
    print("=" * 60)
    print()

    # Step 1: Discover all files
    files = all_dart_files()
    print(f"[1/5] Found {len(files)} .dart files")

    # Step 2: Build move map
    moves = build_move_map(files)
    dist = sum(1 for v in moves.values() if '/distribution/' in v)
    ent = sum(1 for v in moves.values() if '/entertainment/' in v)
    mfg = sum(1 for v in moves.values() if '/manufacturing/' in v)
    print(f"[2/5] Planning {len(moves)} file moves:")
    print(f"       Distribution: {dist}")
    print(f"       Entertainment: {ent}")
    print(f"       Manufacturing: {mfg}")
    print()

    # Print move plan
    print("--- MOVE PLAN ---")
    for old, new in sorted(moves.items()):
        print(f"  {old}")
        print(f"    → {new}")
    print()

    # Build absolute path move map
    abs_move_map = {}
    for old_rel, new_rel in moves.items():
        old_abs = os.path.normpath(str(LIB / old_rel))
        new_abs = os.path.normpath(str(LIB / new_rel))
        abs_move_map[old_abs] = new_abs

    # Step 3: Read all files, fix imports, prepare contents
    print(f"[3/5] Fixing imports in all files...")
    file_contents = {}  # {new_abs_norm: updated_content}
    import_updates = 0

    for f in files:
        old_abs = os.path.normpath(str(LIB / f))
        new_rel = moves.get(f, f)
        new_abs = os.path.normpath(str(LIB / new_rel))

        old_dir = os.path.dirname(old_abs)
        new_dir = os.path.dirname(new_abs)

        try:
            with open(old_abs, 'r', encoding='utf-8') as fh:
                content = fh.read()
        except UnicodeDecodeError:
            with open(old_abs, 'r', encoding='latin-1') as fh:
                content = fh.read()

        new_content = fix_imports(content, old_dir, new_dir, abs_move_map)
        file_contents[new_abs] = new_content

        if content != new_content:
            import_updates += 1

    print(f"       Updated imports in {import_updates} files")

    # Step 4: Write all files to new locations
    print(f"[4/5] Writing files...")
    written = 0

    # Create directories and write files
    for new_abs, content in file_contents.items():
        os.makedirs(os.path.dirname(new_abs), exist_ok=True)
        with open(new_abs, 'w', encoding='utf-8') as fh:
            fh.write(content)
        written += 1

    # Delete old files that moved (only if old != new)
    removed = 0
    for old_rel, new_rel in moves.items():
        old_abs = os.path.normpath(str(LIB / old_rel))
        new_abs = os.path.normpath(str(LIB / new_rel))
        if old_abs != new_abs and os.path.exists(old_abs):
            os.remove(old_abs)
            removed += 1

    print(f"       Wrote {written} files, removed {removed} old files")

    # Step 5: Clean up empty directories
    print(f"[5/5] Cleaning empty directories...")
    cleaned = 0
    for root, dirs, filenames in os.walk(str(LIB), topdown=False):
        for d in dirs:
            dp = os.path.join(root, d)
            try:
                if not os.listdir(dp):
                    os.rmdir(dp)
                    cleaned += 1
            except OSError:
                pass

    print(f"       Removed {cleaned} empty directories")

    # Summary
    print()
    print("=" * 60)
    print(f"  ✅ Migration complete!")
    print(f"  Moved: {len(moves)} files")
    print(f"  Import updates: {import_updates} files")
    print(f"  Empty dirs removed: {cleaned}")
    print()
    print(f"  Verify: cd sabohub-app/SABOHUB && flutter build web --no-tree-shake-icons")
    print(f"  Rollback: git checkout -- sabohub-app/SABOHUB/lib/")
    print("=" * 60)


if __name__ == '__main__':
    main()

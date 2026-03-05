import os

def fix_imports(path):
    for root, _, files in os.walk(path):
        for file in files:
            if file.endswith('.dart'):
                p = os.path.join(root, file)
                with open(p, 'r', encoding='utf-8') as f:
                    content = f.read()
                if 'AppColors.' in content and 'app_colors.dart' not in content:
                    import_stmt = "import 'package:flutter_sabohub/core/theme/app_colors.dart';\n"
                    content = import_stmt + content
                    with open(p, 'w', encoding='utf-8') as f:
                        f.write(content)

fix_imports('lib')
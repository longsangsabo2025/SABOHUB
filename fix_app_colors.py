content = open('lib/core/theme/app_colors.dart', encoding='utf-8').read()
content = content.replace('import \'package:flutter_sabohub/core/theme/app_colors.dart\';\n', '')
open('lib/core/theme/app_colors.dart', 'w', encoding='utf-8').write(content)

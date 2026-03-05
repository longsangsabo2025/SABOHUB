content = open('lib/models/management_task.dart', encoding='utf-8').read()
content = content.replace('import \'package:flutter_sabohub/core/theme/app_colors.dart\';\n', '')
content = content.replace('library;\n', 'library;\nimport \'package:flutter_sabohub/core/theme/app_colors.dart\';\n')
open('lib/models/management_task.dart', 'w', encoding='utf-8').write(content)

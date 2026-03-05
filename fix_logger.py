content = open('lib/business_types/service/services/reservation_service.dart', encoding='utf-8').read()
content = content.replace('AppLogger.warning', 'AppLogger.info')
open('lib/business_types/service/services/reservation_service.dart', 'w', encoding='utf-8').write(content)

import re
content = "const Color(0xFF0F172A), AppColors.primary"
hex_map = {'0xFF0F172A': 'AppColors.backgroundDark'}
def hex_replacer(match):
    hex_str = match.group(1).upper()
    if hex_str in hex_map:
        return hex_map[hex_str]
    return match.group(0)

# Replace 'const Color(..)' to 'Color(..)' if it maps
def const_replacer(match):
    hex_str = match.group(1).upper()
    if hex_str in hex_map:
        return f"{hex_map[hex_str]}"
    return match.group(0)

content = re.sub(r'const\s+Color\((0x[A-Fa-f0-9]{8})\)', const_replacer, content)
content = re.sub(r'Color\((0x[A-Fa-f0-9]{8})\)', hex_replacer, content)
print(content)

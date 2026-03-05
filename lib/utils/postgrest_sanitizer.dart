/// PostgREST filter sanitizer
/// Prevents filter injection when user input is interpolated into `.or()` strings.
/// Strips characters meaningful in PostgREST filter syntax: , ( ) .
class PostgrestSanitizer {
  /// Sanitize a user search string for safe use in PostgREST `.or()` filters.
  /// Removes commas, parentheses, and consecutive dots that could inject predicates.
  static String sanitizeSearch(String input) {
    // Remove PostgREST filter-meaningful characters
    return input
        .replaceAll(',', '')
        .replaceAll('(', '')
        .replaceAll(')', '')
        .replaceAll(RegExp(r'\.{2,}'), '.') // collapse consecutive dots
        .trim();
  }
}

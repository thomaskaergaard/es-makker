/// Firebase Realtime Database stores JSON arrays as maps with sequential
/// integer keys (e.g. `{0: {...}, 1: {...}}`). This helper converts such
/// maps back to a [List] while also handling normal [List] values and nulls.
///
/// Used in `fromJson` factories to safely deserialise data that may come
/// from either `jsonDecode` (returns [List]) or Firebase (returns [Map]).
List<dynamic> firebaseToList(dynamic value) {
  if (value == null) return const [];
  if (value is List) return value;
  if (value is Map) {
    // Firebase integer keys may arrive as int or String depending on the
    // SDK version and platform.  Parse both safely.
    final entries = value.entries.toList();
    entries.sort((a, b) {
      final ka = a.key is int ? a.key as int : int.parse(a.key.toString());
      final kb = b.key is int ? b.key as int : int.parse(b.key.toString());
      return ka.compareTo(kb);
    });
    return entries.map((e) => e.value).toList();
  }
  return const [];
}

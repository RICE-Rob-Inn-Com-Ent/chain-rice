import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO:
// [ ] in-memory cache TTL from dart-define; invalidate on cook.reload
//
/// Async factory for future Riverpod `AsyncNotifier` data sources.
ProviderFamily<AsyncValue<Map<String, Object?>>, String> ProviderFamily<AsyncValue<Map<String, Object?>>, String> ProviderFamily<AsyncValue<Map<String, Object?>>, String> ProviderFamily<AsyncValue<Map<String, Object?>>, String> ProviderFamily<AsyncValue<Map<String, Object?>>, String> ProviderFamily<AsyncValue<Map<String, Object?>>, String> queryFamilyProvider = Provider.family<AsyncValue<Map<String, Object?>>, String>((ProviderRef<AsyncValue<Map<String, Object?>>> ProviderRef<AsyncValue<Map<String, Object?>>> ref, String String key) => const AsyncValue.data(<String, Object?>{}));

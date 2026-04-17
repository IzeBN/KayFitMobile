// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journal_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$journalDayMealsHash() => r'56373f2a86eda0d7e79aae1798321053a8bfb26c';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [journalDayMeals].
@ProviderFor(journalDayMeals)
const journalDayMealsProvider = JournalDayMealsFamily();

/// See also [journalDayMeals].
class JournalDayMealsFamily extends Family<AsyncValue<List<Meal>>> {
  /// See also [journalDayMeals].
  const JournalDayMealsFamily();

  /// See also [journalDayMeals].
  JournalDayMealsProvider call(String date) {
    return JournalDayMealsProvider(date);
  }

  @override
  JournalDayMealsProvider getProviderOverride(
    covariant JournalDayMealsProvider provider,
  ) {
    return call(provider.date);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'journalDayMealsProvider';
}

/// See also [journalDayMeals].
class JournalDayMealsProvider extends AutoDisposeFutureProvider<List<Meal>> {
  /// See also [journalDayMeals].
  JournalDayMealsProvider(String date)
    : this._internal(
        (ref) => journalDayMeals(ref as JournalDayMealsRef, date),
        from: journalDayMealsProvider,
        name: r'journalDayMealsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$journalDayMealsHash,
        dependencies: JournalDayMealsFamily._dependencies,
        allTransitiveDependencies:
            JournalDayMealsFamily._allTransitiveDependencies,
        date: date,
      );

  JournalDayMealsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.date,
  }) : super.internal();

  final String date;

  @override
  Override overrideWith(
    FutureOr<List<Meal>> Function(JournalDayMealsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: JournalDayMealsProvider._internal(
        (ref) => create(ref as JournalDayMealsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        date: date,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Meal>> createElement() {
    return _JournalDayMealsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is JournalDayMealsProvider && other.date == date;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, date.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin JournalDayMealsRef on AutoDisposeFutureProviderRef<List<Meal>> {
  /// The parameter `date` of this provider.
  String get date;
}

class _JournalDayMealsProviderElement
    extends AutoDisposeFutureProviderElement<List<Meal>>
    with JournalDayMealsRef {
  _JournalDayMealsProviderElement(super.provider);

  @override
  String get date => (origin as JournalDayMealsProvider).date;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

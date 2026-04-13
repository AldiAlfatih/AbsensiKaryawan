// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$pendingReportsHash() => r'4393416a3643144cdccbb6850cc53fc041ab3f5a';

/// Stream of all pending reports intended for admins.
///
/// Copied from [pendingReports].
@ProviderFor(pendingReports)
final pendingReportsProvider = AutoDisposeStreamProvider<List<Report>>.internal(
  pendingReports,
  name: r'pendingReportsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pendingReportsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PendingReportsRef = AutoDisposeStreamProviderRef<List<Report>>;
String _$reportControllerHash() => r'9475c58efefd717bbca8be67dc44308fda9cb55c';

/// Notifier to handle submitting and resolving reports.
///
/// Copied from [ReportController].
@ProviderFor(ReportController)
final reportControllerProvider =
    AutoDisposeNotifierProvider<ReportController, AsyncValue<void>>.internal(
      ReportController.new,
      name: r'reportControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$reportControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ReportController = AutoDisposeNotifier<AsyncValue<void>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leave_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$pendingLeavesHash() => r'cf32b4fa1ab2128607867b926c4e468feccb163b';

/// See also [pendingLeaves].
@ProviderFor(pendingLeaves)
final pendingLeavesProvider = AutoDisposeStreamProvider<List<Leave>>.internal(
  pendingLeaves,
  name: r'pendingLeavesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pendingLeavesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PendingLeavesRef = AutoDisposeStreamProviderRef<List<Leave>>;
String _$myLeavesHash() => r'48dab8b25f037a8adf46170710a48229233fb2bf';

/// See also [myLeaves].
@ProviderFor(myLeaves)
final myLeavesProvider = AutoDisposeStreamProvider<List<Leave>>.internal(
  myLeaves,
  name: r'myLeavesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$myLeavesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MyLeavesRef = AutoDisposeStreamProviderRef<List<Leave>>;
String _$leaveControllerHash() => r'b9c5f4786186c0d38e385721480d3bd589630d78';

/// See also [LeaveController].
@ProviderFor(LeaveController)
final leaveControllerProvider =
    AutoDisposeAsyncNotifierProvider<LeaveController, void>.internal(
      LeaveController.new,
      name: r'leaveControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$leaveControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$LeaveController = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

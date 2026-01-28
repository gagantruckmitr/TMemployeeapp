import 'package:flutter_riverpod/flutter_riverpod.dart';

class BankDetails {
  final String accountHolderName;
  final String accountNumber;
  final String ifscCode;
  final String bankName;
  final String upiId;

  const BankDetails({
    this.accountHolderName = '',
    this.accountNumber = '',
    this.ifscCode = '',
    this.bankName = '',
    this.upiId = '',
  });

  BankDetails copyWith({
    String? accountHolderName,
    String? accountNumber,
    String? ifscCode,
    String? bankName,
    String? upiId,
  }) {
    return BankDetails(
      accountHolderName: accountHolderName ?? this.accountHolderName,
      accountNumber: accountNumber ?? this.accountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      bankName: bankName ?? this.bankName,
      upiId: upiId ?? this.upiId,
    );
  }

  bool get isValid =>
      accountNumber.isNotEmpty &&
      ifscCode.isNotEmpty &&
      accountHolderName.isNotEmpty &&
      bankName.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'accountHolderName': accountHolderName,
      'accountNumber': accountNumber,
      'ifscCode': ifscCode,
      'bankName': bankName,
      'upiId': upiId,
    };
  }
}

class ProfileState {
  final bool isLoading;
  final BankDetails bankDetails;
  final String? error;

  const ProfileState({
    this.isLoading = false,
    this.bankDetails = const BankDetails(),
    this.error,
  });

  ProfileState copyWith({
    bool? isLoading,
    BankDetails? bankDetails,
    String? error,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      bankDetails: bankDetails ?? this.bankDetails,
      error: error,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier() : super(const ProfileState());

  // Simulate loading initial data
  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true);
    try {
      // Simulate API delay
      await Future.delayed(const Duration(seconds: 1));

      // Mock data - in real app, fetch from API
      state = state.copyWith(
        isLoading: false,
        bankDetails: const BankDetails(
          accountHolderName: 'Margdarshak User',
          accountNumber: '1234567890',
          ifscCode: 'HDFC0001234',
          bankName: 'HDFC Bank',
          upiId: 'user@hdfc',
        ),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateBankDetails(BankDetails details) async {
    state = state.copyWith(isLoading: true);
    try {
      // Simulate API delay
      await Future.delayed(const Duration(seconds: 1));

      state = state.copyWith(isLoading: false, bankDetails: details);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((
  ref,
) {
  return ProfileNotifier();
});

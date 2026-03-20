class AccountModel {
  final String accountName;
  final String accountNumber;
  final int balance;
  final String type;

  const AccountModel({required this.accountName, required this.accountNumber, required this.balance,required this.type});

  factory AccountModel.empty() => const AccountModel(accountName: '', accountNumber: '', balance: 0,type: '');

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      accountName: json['bankName'] ?? '',
      accountNumber: json['accountNumber'] ?? '',
      balance: json['balance'] ?? 0,
      type: json['type'] ?? 0,
    );
  }
}
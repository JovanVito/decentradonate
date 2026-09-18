/// Riwayat transaksi donasi dari blockchain.
class TransactionHistory {
  final int campaignId;
  final String donor;
  final double amount;
  final DateTime timestamp;
  final String txHash;

  const TransactionHistory({
    required this.campaignId,
    required this.donor,
    required this.amount,
    required this.timestamp,
    required this.txHash,
  });
}

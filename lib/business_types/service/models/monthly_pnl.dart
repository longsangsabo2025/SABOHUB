/// Monthly P&L (Profit & Loss) Model - Báo cáo kết quả hoạt động kinh doanh
class MonthlyPnl {
  final String id;
  final String companyId;
  final String? branchId;
  final String? branchName;
  final DateTime reportMonth;

  // Revenue
  final double grossRevenue;
  final double revenueDeductions;
  final double invoiceDiscounts;
  final double returnsValue;
  final double netRevenue;

  // Costs & Profit
  final double cogs;
  final double grossProfit;

  // Operating Expenses
  final double totalExpenses;
  final double deliveryFees;
  final double qrTransactionFees;
  final double destroyedGoods;
  final double pointsPayment;
  final double salaryExpenses;
  final double operatingProfit;

  // Monthly Expense Categories (New)
  final double rentExpense;        // Mặt bằng
  final double electricityExpense; // Điện
  final double advertisingExpense; // Quảng Cáo
  final double invoicedPurchases;  // Nhập hàng có hóa đơn
  final double otherPurchases;     // Mua hàng hóa/vật dụng khác

  // Other
  final double otherIncome;
  final double returnFees;
  final double salaryRefunds;
  final double otherExpenses;
  final double netProfit;

  // Metadata
  final String? sourceFile;
  final String? importedBy;
  final String? notes;
  final Map<String, dynamic>? rawData;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MonthlyPnl({
    required this.id,
    required this.companyId,
    this.branchId,
    this.branchName,
    required this.reportMonth,
    this.grossRevenue = 0,
    this.revenueDeductions = 0,
    this.invoiceDiscounts = 0,
    this.returnsValue = 0,
    this.netRevenue = 0,
    this.cogs = 0,
    this.grossProfit = 0,
    this.totalExpenses = 0,
    this.deliveryFees = 0,
    this.qrTransactionFees = 0,
    this.destroyedGoods = 0,
    this.pointsPayment = 0,
    this.salaryExpenses = 0,
    this.operatingProfit = 0,
    this.rentExpense = 0,
    this.electricityExpense = 0,
    this.advertisingExpense = 0,
    this.invoicedPurchases = 0,
    this.otherPurchases = 0,
    this.otherIncome = 0,
    this.returnFees = 0,
    this.salaryRefunds = 0,
    this.otherExpenses = 0,
    this.netProfit = 0,
    this.sourceFile,
    this.importedBy,
    this.notes,
    this.rawData,
    this.createdAt,
    this.updatedAt,
  });

  factory MonthlyPnl.fromJson(Map<String, dynamic> json) {
    return MonthlyPnl(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      branchId: json['branch_id'] as String?,
      branchName: json['branch_name'] as String?,
      reportMonth: DateTime.parse(json['report_month'] as String),
      grossRevenue: _toDouble(json['gross_revenue']),
      revenueDeductions: _toDouble(json['revenue_deductions']),
      invoiceDiscounts: _toDouble(json['invoice_discounts']),
      returnsValue: _toDouble(json['returns_value']),
      netRevenue: _toDouble(json['net_revenue']),
      cogs: _toDouble(json['cogs']),
      grossProfit: _toDouble(json['gross_profit']),
      totalExpenses: _toDouble(json['total_expenses']),
      deliveryFees: _toDouble(json['delivery_fees']),
      qrTransactionFees: _toDouble(json['qr_transaction_fees']),
      destroyedGoods: _toDouble(json['destroyed_goods']),
      pointsPayment: _toDouble(json['points_payment']),
      salaryExpenses: _toDouble(json['salary_expenses']),
      operatingProfit: _toDouble(json['operating_profit']),
      rentExpense: _toDouble(json['rent_expense']),
      electricityExpense: _toDouble(json['electricity_expense']),
      advertisingExpense: _toDouble(json['advertising_expense']),
      invoicedPurchases: _toDouble(json['invoiced_purchases']),
      otherPurchases: _toDouble(json['other_purchases']),
      otherIncome: _toDouble(json['other_income']),
      returnFees: _toDouble(json['return_fees']),
      salaryRefunds: _toDouble(json['salary_refunds']),
      otherExpenses: _toDouble(json['other_expenses']),
      netProfit: _toDouble(json['net_profit']),
      sourceFile: json['source_file'] as String?,
      importedBy: json['imported_by'] as String?,
      notes: json['notes'] as String?,
      rawData: json['raw_data'] as Map<String, dynamic>?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  static double _toDouble(dynamic v) => (v as num?)?.toDouble() ?? 0;

  /// Gross margin percentage
  double get grossMarginPct =>
      netRevenue > 0 ? (grossProfit / netRevenue) * 100 : 0;

  /// Net margin percentage
  double get netMarginPct =>
      netRevenue > 0 ? (netProfit / netRevenue) * 100 : 0;

  /// Operating margin percentage
  double get operatingMarginPct =>
      netRevenue > 0 ? (operatingProfit / netRevenue) * 100 : 0;

  /// Total categorized monthly expenses (new categories)
  double get totalCategorizedExpenses =>
      rentExpense + electricityExpense + advertisingExpense +
      invoicedPurchases + otherPurchases + salaryExpenses;

  /// Month label (e.g., "T3/2024")
  String get monthLabel => 'T${reportMonth.month}/${reportMonth.year}';

  /// Is profitable?
  bool get isProfitable => netProfit > 0;
}

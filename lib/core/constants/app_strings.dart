// lib/core/constants/app_strings.dart

class AppStrings {
  AppStrings._();

  // ── App ────────────────────────────────────────────────────
  static const String appName     = 'Laptop Rental';
  static const String appSubtitle = 'Admin Panel';

  // ── Auth ───────────────────────────────────────────────────
  static const String login           = 'Login';
  static const String logout          = 'Logout';
  static const String email           = 'Email';
  static const String password        = 'Password';
  static const String loginButton     = 'Sign In';
  static const String invalidCreds    = 'Invalid email or password';
  static const String networkError    = 'Network error. Please try again.';

  // ── Dashboard ──────────────────────────────────────────────
  static const String dashboard       = 'Dashboard';
  static const String activeCustomers = 'Active Customers';
  static const String totalLaptops    = 'Total Laptops';
  static const String rented          = 'Rented';
  static const String available       = 'Available';
  static const String overdueDues     = 'Overdue Dues';
  static const String totalRevenue    = 'Total Revenue';

  // ── Customers ──────────────────────────────────────────────
  static const String customers       = 'Customers';
  static const String addCustomer     = 'Add Customer';
  static const String customerName    = 'Full Name';
  static const String phone           = 'Phone Number';
  static const String address         = 'Address';
  static const String idProofType     = 'ID Proof Type';
  static const String idProofNumber   = 'ID Proof Number';
  static const String noCustomers     = 'No customers found';
  static const String searchCustomers = 'Search by name or phone';

  // ── Laptops ────────────────────────────────────────────────
  static const String laptops         = 'Laptops';
  static const String addLaptop       = 'Add Laptop';
  static const String laptopUUID      = 'Asset UUID';
  static const String serialNumber    = 'Serial Number';
  static const String model           = 'Model';
  static const String brand           = 'Brand';
  static const String noLaptops       = 'No laptops found';
  static const String noAvailableLaptops = 'No laptops available for rental';

  // ── Rental ─────────────────────────────────────────────────
  static const String rental          = 'Rental';
  static const String rentalType      = 'Rental Type';
  static const String weekly          = 'Weekly';
  static const String monthly         = 'Monthly';
  static const String manual          = 'Manual';
  static const String startDate       = 'Start Date';
  static const String endDate         = 'End Date';
  static const String rentAmount      = 'Rent Amount (per cycle)';
  static const String depositAmount   = 'Security Deposit';
  static const String durationCount   = 'Duration';
  static const String weeks           = 'Weeks';
  static const String months          = 'Months';
  static const String markComplete    = 'Mark Complete';
  static const String returnDeposit   = 'Return Deposit';
  static const String completeRental  = 'Complete Rental';

  // ── Dues ───────────────────────────────────────────────────
  static const String dues            = 'Dues';
  static const String allClear        = 'All dues are clear!';
  static const String fullPay         = 'Full Pay';
  static const String partialPay      = 'Partial Pay';
  static const String paymentMode     = 'Payment Mode';
  static const String referenceNumber = 'Reference Number (optional)';
  static const String cash            = 'Cash';
  static const String upi             = 'UPI';
  static const String bankTransfer    = 'Bank Transfer';
  static const String other           = 'Other';
  static const String daysOverdue     = 'days overdue';
  static const String dueOn           = 'Due on';

  // ── Common ─────────────────────────────────────────────────
  static const String save            = 'Save';
  static const String cancel          = 'Cancel';
  static const String confirm         = 'Confirm';
  static const String delete          = 'Delete';
  static const String edit            = 'Edit';
  static const String next            = 'Next';
  static const String back            = 'Back';
  static const String loading         = 'Loading...';
  static const String retry           = 'Retry';
  static const String success         = 'Success';
  static const String error           = 'Something went wrong';
  static const String noData          = 'No data available';
  static const String all             = 'All';
  static const String notes           = 'Notes (optional)';
  static const String rupeeSymbol     = '₹';
}
import 'locale_tracker.dart';

class S {
  static String _t(String vi, String en) =>
      activeLocale == 'en' ? en : vi;

  // Auth
  static String get appName => 'My Moneyyy!!!';
  static String get signOut => _t('Đăng xuất', 'Sign Out');
  static String get signOutConfirm =>
      _t('Đăng xuất khỏi tài khoản?', 'Sign out of your account?');
  static String get tagline => _t('Chi tiêu thông minh 🐝', 'Smart spending 🐝');
  static String get email => 'Email';
  static String get password => _t('Mật khẩu', 'Password');
  static String get yourName => _t('Tên', 'Name');
  static String get signIn => _t('Đăng nhập', 'Sign In');
  static String get createAccount => _t('Đăng ký', 'Create Account');
  static String get noAccount =>
      _t('Chưa có tài khoản? Đăng ký', 'No account? Sign Up');
  static String get haveAccount =>
      _t('Đã có tài khoản? Đăng nhập', 'Have an account? Sign In');

  // Household
  static String get householdSetup => _t('Thiết lập', 'Setup');
  static String get householdSubtitle =>
      _t('Tạo mới hoặc tham gia cùng người bạn đời',
          'Create new or join with your partner');
  static String get createHousehold => _t('Tạo mới', 'Create New');
  static String get joinWithCode => _t('Tham gia bằng mã', 'Join with Code');
  static String get householdCreated => _t('Xong!', 'Done!');
  static String get shareCodeHint =>
      _t('Chia sẻ mã với người bạn đời', 'Share code with your partner');
  static String get codeCopied => _t('Đã sao chép!', 'Copied!');
  static String get inviteCodeHint => _t('Nhập mã mời', 'Enter invite code');
  static String get joinBtn => _t('Tham gia', 'Join');
  static String get allSet =>
      _t('Chia sẻ mã rồi mời người bạn đời vào app.',
          'Share the code and invite your partner to the app.');

  // Tabs
  static String get tabHome => _t('Tài chính', 'Finance');
  static String get tabTransactions => _t('Giao dịch', 'Transactions');
  static String get tabBudget => _t('Ngân sách', 'Budget');
  static String get tabSavings => _t('Tiết kiệm', 'Savings');
  static String get tabReports => _t('Báo cáo', 'Reports');
  static String get tabHousehold => _t('Hộ gia đình', 'Household');

  // Transactions
  static String get addTransaction => _t('Giao dịch mới', 'New Transaction');
  static String get expense => _t('Chi tiêu', 'Expense');
  static String get income => _t('Thu nhập', 'Income');
  static String get amount => _t('Số tiền', 'Amount');
  static String get category => _t('Danh mục', 'Category');
  static String get date => _t('Ngày', 'Date');
  static String get notes => _t('Ghi chú', 'Notes');
  static String get save => _t('Lưu', 'Save');
  static String get update => _t('Cập nhật', 'Update');
  static String get noTransactions => _t('Chưa có giao dịch', 'No transactions');
  static String get noTransactionsHint => _t('Nhấn + để thêm', 'Tap + to add');
  static String get selectCategory => _t('Chọn danh mục', 'Select category');
  static String get invalidAmount =>
      _t('Nhập số tiền hợp lệ', 'Enter a valid amount');
  static String get spendingByCategory =>
      _t('Chi tiêu theo danh mục', 'Spending by category');
  static String get last6Months => _t('6 tháng gần đây', 'Last 6 months');
  static String get somethingWrong =>
      _t('Có lỗi xảy ra', 'Something went wrong');
  static String get income2 => _t('thu nhập', 'income');
  static String get expense2 => _t('chi tiêu', 'expense');

  // Budget
  static String get noBudgets => _t('Chưa có ngân sách', 'No budgets');
  static String get noBudgetsHint =>
      _t('Nhấn vào danh mục để đặt hạn mức', 'Tap a category to set a limit');
  static String get monthlyLimit => _t('Hạn mức tháng', 'Monthly limit');
  static String get setBudgetTitle => _t('Ngân sách', 'Budget');

  // Savings
  static String get addGoal => _t('Thêm mục tiêu', 'Add Goal');
  static String get noGoals => _t('Chưa có mục tiêu', 'No goals');
  static String get noGoalsHint => _t('Nhấn + để tạo', 'Tap + to create');
  static String get goalName => _t('Tên mục tiêu', 'Goal name');
  static String get targetAmount => _t('Số tiền mục tiêu', 'Target amount');
  static String get deadline => _t('Hạn chót', 'Deadline');
  static String get noDeadline => _t('Không có hạn chót', 'No deadline');
  static String get contribute => _t('Nạp', 'Add');
  static String get withdrawExceedsBalance =>
      _t('Số tiền rút vượt quá số dư hiện tại',
          'Withdrawal exceeds current balance');
  static String get withdraw => _t('Rút', 'Withdraw');
  static String get contributeAmount => _t('Số tiền', 'Amount');

  // Reports
  static String get noReports => _t('Chưa có dữ liệu', 'No data');
  static String get noSpendingData =>
      _t('Chưa có chi tiêu tháng này', 'No spending this month');
  static String get totalIncome => _t('Thu nhập', 'Income');
  static String get totalExpense => _t('Chi tiêu', 'Expense');
  static String get netSaved => _t('Còn lại', 'Remaining');

  // Budget card
  static String get budgetOf => _t('của', 'of');
  static String get budgetPercentUsed => _t('% đã dùng', '% used');
  static String get budgetLeft => _t('còn lại', 'left');
  static String get budgetOver => _t('vượt ngân sách', 'over budget');

  // Goal card
  static String get goalDaysLeft => _t('ngày còn lại', 'days left');
  static String get goalDueToday => _t('Đến hạn hôm nay!', 'Due today!');
  static String get goalOverdueDays => _t('ngày quá hạn', 'days overdue');
  static String get goalReached =>
      _t('Đã đạt mục tiêu! 🎉', 'Goal reached! 🎉');
  static String get goalSavedProgress => _t('% đã tiết kiệm', '% saved');
  static String get goalToGo => _t('còn thiếu', 'to go');

  // Delete confirmation
  static String get deleteBudgetTitle => _t('Xoá ngân sách?', 'Delete budget?');
  static String deleteBudgetContent(String name) =>
      _t('Xoá ngân sách "$name" vĩnh viễn.', 'Delete "$name" budget permanently.');
  static String get deleteGoalTitle => _t('Xoá mục tiêu?', 'Delete goal?');
  static String deleteGoalContent(String name) =>
      _t('Xoá "$name" vĩnh viễn.', 'Delete "$name" permanently.');
  static String get deleteTransactionTitle =>
      _t('Xoá giao dịch?', 'Delete transaction?');
  static String get deleteTransactionContent =>
      _t('Giao dịch sẽ bị xoá vĩnh viễn.',
          'Transaction will be permanently deleted.');
  static String get editTransaction =>
      _t('Sửa giao dịch', 'Edit transaction');

  // Category fallback
  static String get otherCategory => _t('Khác', 'Other');

  // Profile
  static String get tabProfile => _t('Hồ sơ', 'Profile');
  static String get profileTitle => _t('Tài khoản', 'Account');
  static String get memberSince => _t('Thành viên từ', 'Member since');
  static String get householdLabel => _t('Hộ gia đình', 'Household');
  static String get inviteCodeLabel => _t('Mã mời', 'Invite code');
  static String get tabSettings => _t('Cài đặt', 'Settings');
  static String get settingsAppVersion => _t('Phiên bản', 'Version');
  static String get settingsAbout => _t('Về ứng dụng', 'About');
  static String get appVersionValue => '1.0.0';
  static String get darkMode => _t('Chế độ tối', 'Dark mode');

  // Appearance & language settings
  static String get settingsAppearance => _t('Giao diện', 'Appearance');
  static String get themeSystem => _t('Hệ thống', 'System');
  static String get themeLight => _t('Sáng', 'Light');
  static String get themeDark => _t('Tối', 'Dark');
  static String get settingsLanguage => _t('Ngôn ngữ', 'Language');
  static String get languageVietnamese => 'Tiếng Việt';
  static String get languageEnglish => 'English';

  // Household screen
  static String get householdMembers => _t('Thành viên', 'Members');
  static String get editHouseholdName =>
      _t('Sửa tên hộ', 'Edit household name');
  static String get householdNameHint =>
      _t('Tên hộ gia đình', 'Household name');
  static String get youSuffix => _t('(bạn)', '(you)');
  static String get inviteBannerTitle =>
      _t('Mời người bạn đời', 'Invite your partner');
  static String get inviteBannerSubtitle =>
      _t('Chia sẻ mã mời để cùng quản lý tài chính',
          'Share invite code to manage finances together');
  static String get shareInviteBtn =>
      _t('Chia sẻ mã mời', 'Share invite code');
  static String get joiningHousehold =>
      _t('Đang tham gia hộ gia đình...', 'Joining household...');
  static String shareInviteText(String code) => _t(
        'Tham gia hộ gia đình của mình trên My Moneyyy!!!\n'
        'Nhấn vào đây để tự động vào: https://mymoneyyy.pages.dev/join/$code\n'
        'Hoặc nhập mã thủ công: $code',
        'Join my household on My Moneyyy!!!\n'
        'Tap here to join automatically: https://mymoneyyy.pages.dev/join/$code\n'
        'Or enter the code manually: $code',
      );

  // Household management
  static String get removeMemberTitle =>
      _t('Xoá thành viên?', 'Remove member?');
  static String removeMemberContent(String name) => _t(
        'Xoá "$name" khỏi hộ gia đình vĩnh viễn.',
        'Remove "$name" from the household permanently.',
      );
  static String get removeMember => _t('Xoá', 'Remove');

  // Category management
  static String get manageCategories =>
      _t('Quản lý danh mục', 'Manage categories');
  static String get addCategory => _t('Thêm danh mục', 'Add category');
  static String get editCategory => _t('Sửa danh mục', 'Edit category');
  static String get categoryNameHint => _t('Tên danh mục', 'Category name');
  static String get categoryIconHint =>
      _t('Biểu tượng (1 emoji)', 'Icon (1 emoji)');
  static String get categoryIconTab => 'Icon';
  static String get categoryEmojiTab => 'Emoji';
  static String get deleteCategoryTitle =>
      _t('Xoá danh mục?', 'Delete category?');
  static String deleteCategoryContent(String name) => _t(
        'Xoá danh mục "$name" vĩnh viễn.',
        'Delete category "$name" permanently.',
      );
  static String get categoryTypeIncome => _t('Thu nhập', 'Income');
  static String get categoryTypeExpense => _t('Chi tiêu', 'Expense');
  static String get categoryTypeBoth => _t('Cả hai', 'Both');

  // Avatar picker
  static String get avatarPickerTitle => _t('Chọn avatar', 'Choose avatar');

  // Household switcher
  static String get switchHouseholdTitle => _t('Chuyển hộ gia đình', 'Switch household');
  static String get leaveHousehold => _t('Rời khỏi', 'Leave');
  static String get leaveHouseholdTitle => _t('Rời khỏi hộ gia đình?', 'Leave household?');
  static String leaveHouseholdContent(String name) => _t(
        'Bạn sẽ không còn truy cập dữ liệu của "$name".',
        'You will lose access to "$name" data.',
      );
  static String get joinAnotherHousehold =>
      _t('Tham gia hộ gia đình khác', 'Join another household');
  static String get createNewHousehold =>
      _t('Tạo hộ gia đình mới', 'Create new household');
  static String get activeHousehold => _t('Đang hoạt động', 'Active');
  static String get householdSwitchRow => _t('Hộ gia đình', 'Household');

  // Money sources (wallets)
  static String get tabWallets => _t('Ví', 'Wallets');
  static String get addMoneySource => _t('Thêm ví', 'Add Wallet');
  static String get editMoneySource => _t('Sửa ví', 'Edit Wallet');
  static String get noMoneySource => _t('Chưa có ví', 'No wallets');
  static String get noMoneySourceHint =>
      _t('Nhấn + để thêm ví', 'Tap + to add a wallet');
  static String get sourceName => _t('Tên ví', 'Wallet name');
  static String get sourceType => _t('Loại', 'Type');
  static String get sourceInitialBalance =>
      _t('Số dư ban đầu', 'Initial balance');
  static String get sourceBalance => _t('Số dư', 'Balance');
  static String get sourceTypeCash => _t('Tiền mặt', 'Cash');
  static String get sourceTypeBank => _t('Ngân hàng', 'Bank');
  static String get sourceTypeProperty => _t('Tài sản', 'Property');
  static String get sourceTypeInvestment => _t('Đầu tư', 'Investment');
  static String get sourceTypeOther => _t('Khác', 'Other');
  static String get selectSource => _t('Chọn ví', 'Select wallet');
  static String get noSource => _t('Không có ví', 'No wallet');
  static String get deleteSourceTitle => _t('Xoá ví?', 'Delete wallet?');
  static String deleteSourceContent(String name) => _t(
        'Xoá ví "$name" vĩnh viễn.',
        'Delete wallet "$name" permanently.',
      );
  static String get totalBalance => _t('Tổng số dư', 'Total balance');
  static String get sourceColor => _t('Màu', 'Color');

  // Search & filter
  static String get searchTransactions => _t('Tìm kiếm...', 'Search...');
  static String get filterAll => _t('Tất cả', 'All');
  static String get clearFilter => _t('Xoá', 'Clear');

  // Common
  static String get retry => _t('Thử lại', 'Retry');
  static String get cancel => _t('Huỷ', 'Cancel');
  static String get delete => _t('Xoá', 'Delete');
  static String get copyCode => _t('Sao chép', 'Copy');
  static String get done => _t('Xong', 'Done');
  static String get today => _t('Hôm nay', 'Today');
  static String get yesterday => _t('Hôm qua', 'Yesterday');
  static String get clearDate => _t('Xoá ngày', 'Clear date');
}

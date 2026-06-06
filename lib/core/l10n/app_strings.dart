class S {
  // Auth
  static const appName = 'My Moneyyy!!!';
  static const signOut = 'Đăng xuất';
  static const signOutConfirm = 'Đăng xuất khỏi tài khoản?';
  static const tagline = 'Chi tiêu thông minh 🐝';
  static const email = 'Email';
  static const password = 'Mật khẩu';
  static const yourName = 'Tên';
  static const signIn = 'Đăng nhập';
  static const createAccount = 'Đăng ký';
  static const noAccount = 'Chưa có tài khoản? Đăng ký';
  static const haveAccount = 'Đã có tài khoản? Đăng nhập';

  // Household
  static const householdSetup = 'Thiết lập';
  static const householdSubtitle = 'Tạo mới hoặc tham gia cùng người bạn đời';
  static const createHousehold = 'Tạo mới';
  static const joinWithCode = 'Tham gia bằng mã';
  static const householdCreated = 'Xong!';
  static const shareCodeHint = 'Chia sẻ mã với người bạn đời';
  static const codeCopied = 'Đã sao chép!';
  static const inviteCodeHint = 'Nhập mã mời';
  static const joinBtn = 'Tham gia';
  static const allSet = 'Chia sẻ mã rồi mời người bạn đời vào app.';

  // Tabs
  static const tabHome = 'Tài chính';
  static const tabTransactions = 'Giao dịch';
  static const tabBudget = 'Ngân sách';
  static const tabSavings = 'Tiết kiệm';
  static const tabReports = 'Báo cáo';
  static const tabHousehold = 'Hộ gia đình';

  // Transactions
  static const addTransaction = 'Giao dịch mới';
  static const expense = 'Chi tiêu';
  static const income = 'Thu nhập';
  static const amount = 'Số tiền';
  static const category = 'Danh mục';
  static const date = 'Ngày';
  static const notes = 'Ghi chú';
  static const save = 'Lưu';
  static const update = 'Cập nhật';
  static const noTransactions = 'Chưa có giao dịch';
  static const noTransactionsHint = 'Nhấn + để thêm';
  static const selectCategory = 'Chọn danh mục';
  static const invalidAmount = 'Nhập số tiền hợp lệ';
  static const spendingByCategory = 'Chi tiêu theo danh mục';
  static const last6Months = '6 tháng gần đây';
  static const somethingWrong = 'Có lỗi xảy ra';
  static const income2 = 'thu nhập';
  static const expense2 = 'chi tiêu';

  // Budget
  static const noBudgets = 'Chưa có ngân sách';
  static const noBudgetsHint = 'Nhấn vào danh mục để đặt hạn mức';
  static const monthlyLimit = 'Hạn mức tháng';
  static const setBudgetTitle = 'Ngân sách';

  // Savings
  static const addGoal = 'Thêm mục tiêu';
  static const noGoals = 'Chưa có mục tiêu';
  static const noGoalsHint = 'Nhấn + để tạo';
  static const goalName = 'Tên mục tiêu';
  static const targetAmount = 'Số tiền mục tiêu';
  static const deadline = 'Hạn chót';
  static const noDeadline = 'Không có hạn chót';
  static const contribute = 'Nạp';
  static const withdrawExceedsBalance = 'Số tiền rút vượt quá số dư hiện tại';
  static const withdraw = 'Rút';
  static const contributeAmount = 'Số tiền';

  // Reports
  static const noReports = 'Chưa có dữ liệu';
  static const noSpendingData = 'Chưa có chi tiêu tháng này';
  static const totalIncome = 'Thu nhập';
  static const totalExpense = 'Chi tiêu';
  static const netSaved = 'Còn lại';

  // Budget card
  static const budgetOf = 'của';
  static const budgetPercentUsed = '% đã dùng';
  static const budgetLeft = 'còn lại';
  static const budgetOver = 'vượt ngân sách';

  // Goal card
  static const goalDaysLeft = 'ngày còn lại';
  static const goalDueToday = 'Đến hạn hôm nay!';
  static const goalOverdueDays = 'ngày quá hạn';
  static const goalReached = 'Đã đạt mục tiêu! 🎉';
  static const goalSavedProgress = '% đã tiết kiệm';
  static const goalToGo = 'còn thiếu';

  // Delete confirmation
  static const deleteGoalTitle = 'Xoá mục tiêu?';
  static String deleteGoalContent(String name) => 'Xoá "$name" vĩnh viễn.';
  static const deleteTransactionTitle = 'Xoá giao dịch?';
  static const deleteTransactionContent = 'Giao dịch sẽ bị xoá vĩnh viễn.';
  static const editTransaction = 'Sửa giao dịch';

  // Category fallback
  static const otherCategory = 'Khác';

  // Profile
  static const tabProfile = 'Hồ sơ';
  static const profileTitle = 'Tài khoản';
  static const memberSince = 'Thành viên từ';
  static const householdLabel = 'Hộ gia đình';
  static const inviteCodeLabel = 'Mã mời';
  static const tabSettings = 'Cài đặt';
  static const settingsAppVersion = 'Phiên bản';
  static const settingsAbout = 'Về ứng dụng';
  static const appVersionValue = '1.0.0';
  static const darkMode = 'Chế độ tối';

  // Household screen
  static const householdMembers = 'Thành viên';
  static const editHouseholdName = 'Sửa tên hộ';
  static const householdNameHint = 'Tên hộ gia đình';
  static const youSuffix = '(bạn)';
  static const inviteBannerTitle = 'Mời người bạn đời';
  static const inviteBannerSubtitle = 'Chia sẻ mã mời để cùng quản lý tài chính';
  static const shareInviteBtn = 'Chia sẻ mã mời';
  static const joiningHousehold = 'Đang tham gia hộ gia đình...';
  static String shareInviteText(String code) =>
      'Tham gia hộ gia đình của mình trên My Moneyyy!!!\n'
      'Nhấn vào đây để tự động vào: https://mymoneyyy.pages.dev/join/$code\n'
      'Hoặc nhập mã thủ công: $code';

  // Household management
  static const removeMemberTitle = 'Xoá thành viên?';
  static String removeMemberContent(String name) =>
      'Xoá "$name" khỏi hộ gia đình vĩnh viễn.';
  static const removeMember = 'Xoá';

  // Category management
  static const manageCategories = 'Quản lý danh mục';
  static const addCategory = 'Thêm danh mục';
  static const editCategory = 'Sửa danh mục';
  static const categoryNameHint = 'Tên danh mục';
  static const categoryIconHint = 'Biểu tượng (1 emoji)';
  static const categoryIconTab = 'Icon';
  static const categoryEmojiTab = 'Emoji';
  static const deleteCategoryTitle = 'Xoá danh mục?';
  static String deleteCategoryContent(String name) =>
      'Xoá danh mục "$name" vĩnh viễn.';
  static const categoryTypeIncome = 'Thu nhập';
  static const categoryTypeExpense = 'Chi tiêu';
  static const categoryTypeBoth = 'Cả hai';

  // Common
  static const retry = 'Thử lại';
  static const cancel = 'Huỷ';
  static const delete = 'Xoá';
  static const copyCode = 'Sao chép';
  static const done = 'Xong';
}

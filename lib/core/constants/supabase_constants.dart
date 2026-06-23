// Values are injected at build time via --dart-define-from-file=.env.json
// Copy .env.example.json → .env.json and fill in your Supabase credentials.
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

// Table names
const tableHouseholds = 'households';
const tableProfiles = 'profiles';
const tableCategories = 'categories';
const tableTransactions = 'transactions';
const tableBudgets = 'budgets';
const tableSavingsGoals = 'savings_goals';
const tableSavingsContributions = 'savings_contributions';
const tableProfileHouseholdMemberships = 'profile_household_memberships';
const tableMoneySource = 'money_sources';
const tablePushSubscriptions = 'push_subscriptions';

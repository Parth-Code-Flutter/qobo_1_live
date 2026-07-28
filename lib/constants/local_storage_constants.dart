const String kStorageIsLoggedIn = 'is_logged_in';
const String kStorageIsAdmin = 'is_admin_in';
const String kStorageIsEmployee = 'is_employee_in';
const String kStorageIsClient = 'is_client_in';

const String kStorageToken = 'token';
/// Separate JWT for coin-seller portal (`/api/admin/login` → `seller_admin`).
const String kStorageSellerToken = 'seller_token';
const String kStorageSellerAdmin = 'seller_admin_data';
/// Local flag: user submitted coins-seller apply and awaits admin approval.
const String kStorageCoinsSellerApplyPending = 'coins_seller_apply_pending';
const String kStorageUserData = 'user_data';
const String kStorageAdminUserData = 'admin_user_data';
const String kStorageEmployeeUserData = 'employee_user_data';
const String kStorageClientUserData = 'client_user_data';

/// Cached response from GET organization-user (called once after login; cleared on logout).
const String kStorageCachedOrganizationUserList = 'cached_organization_user_list';

/// Pending / last agency owner application (until approved and agency session is set).
const String kStorageAgencyOwnerApplication = 'agency_owner_application';

/// Approved agency owner session (id, code, commission) for cold-start restore.
const String kStorageApprovedAgency = 'agency_approved_session';

/// Local chat message cache (until POST /api/chat/send is available).
const String kStorageChatMessages = 'chat_messages_cache';

/// Local inbox thread previews from unsynced sends.
const String kStorageChatInboxThreads = 'chat_inbox_threads_cache';

/// Local call log cache per room (shows in chat thread immediately).
const String kStorageChatCallHistory = 'chat_call_history_cache';

/// Partners for whom `POST /api/chat/send` succeeded (one-time thread bootstrap).
const String kStorageChatSendInit = 'chat_send_init_targets';

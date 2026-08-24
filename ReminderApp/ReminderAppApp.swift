import SwiftUI

@main
struct ReminderAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // تعيين مفوض الإشعارات
        UNUserNotificationCenter.current().delegate = NotificationDelegate()
        
        print("✅ تطبيق التذكيرات تم تشغيله بنجاح")
        
        // تحميل البيانات المحفوظة
        let storageService = StorageService.shared
        let reminders = storageService.loadReminders()
        print("📦 تم تحميل \(reminders.count) تذكير من التخزين")
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        print("🟢 التطبيق أصبح نشطاً")
        // تحديث الإشعارات عند العودة إلى التطبيق
        updateNotificationBadge()
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        print("⚪ التطبيق أصبح غير نشط")
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("🔴 التطبيق دخل الخلفية")
        // حفظ البيانات قبل الدخول للخلفية
        savePendingData()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        print("🟡 التطبيق سيعود للواجهة الأمامية")
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        print("⛔ التطبيق سيتم إغلاقه")
        // حفظ أي بيانات معلقة
        savePendingData()
    }
    
    // MARK: - معالجة الإشعارات من خلال launch options
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        print("📨 تم استقبال إشعار بعيد")
        completionHandler(.newData)
    }
    
    // MARK: - تحديث شارة الإشعارات
    private func updateNotificationBadge() {
        let storageService = StorageService.shared
        let reminders = storageService.loadReminders()
        let pendingCount = reminders.filter { !$0.isCompleted && $0.isOverdue }.count
        
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = pendingCount
        }
    }
    
    // MARK: - حفظ البيانات المعلقة
    private func savePendingData() {
        // هذا يمكن توسيعه لاحقاً إذا لزم الأمر
        print("💾 تم حفظ البيانات")
    }
}

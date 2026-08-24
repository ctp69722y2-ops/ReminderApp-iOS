import Foundation

// MARK: - خدمة الإشعارات
class NotificationService {
    static let shared = NotificationService()
    
    private init() {}
    
    // MARK: - طلب صلاحيات الإشعارات
    func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ خطأ في طلب صلاحيات الإشعارات: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("✅ تم \(granted ? "منح" : "رفض") صلاحيات الإشعارات")
                    completion(granted)
                }
            }
        }
    }
    
    // MARK: - التحقق من صلاحيات الإشعارات
    func checkNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus == .authorized)
            }
        }
    }
    
    // MARK: - جدولة إشعار للتذكير
    func scheduleReminder(_ reminder: Reminder) {
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.description.isEmpty ? "موعدك الآن!" : reminder.description
        content.sound = .default
        content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
        
        // إضافة بيانات مخصصة
        content.userInfo = [
            "reminderId": reminder.id.uuidString,
            "category": reminder.category.rawValue
        ]
        
        // تعيين اللون والأيقونة
        content.launchImageName = "AppIcon"
        
        // حساب الفرق الزمني
        let timeInterval = max(1, reminder.fullDateTime.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        
        let request = UNNotificationRequest(identifier: reminder.id.uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ خطأ في جدولة الإشعار: \(error.localizedDescription)")
            } else {
                print("✅ تم جدولة إشعار للتذكير: \(reminder.title)")
            }
        }
    }
    
    // MARK: - تحديث إشعار موجود
    func updateReminder(_ reminder: Reminder) {
        // إلغاء الإشعار القديم
        cancelReminder(reminder.id)
        
        // جدولة إشعار جديد
        if reminder.notificationEnabled {
            scheduleReminder(reminder)
        }
    }
    
    // MARK: - إلغاء إشعار
    func cancelReminder(_ reminderId: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminderId.uuidString])
        print("✅ تم إلغاء الإشعار: \(reminderId.uuidString)")
    }
    
    // MARK: - إلغاء جميع الإشعارات
    func cancelAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("✅ تم إلغاء جميع الإشعارات")
    }
    
    // MARK: - الحصول على الإشعارات المعلقة
    func getPendingNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            completion(requests)
        }
    }
    
    // MARK: - تحديث شارة التطبيق
    func updateBadge(count: Int) {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = count
        }
    }
}

// MARK: - مفوض الإشعارات
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    
    // MARK: - معالجة الإشعارات عندما يكون التطبيق نشطاً
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        
        if let reminderId = userInfo["reminderId"] as? String {
            print("📬 تم استقبال إشعار للتذكير: \(reminderId)")
        }
        
        // عرض الإشعار حتى لو كان التطبيق نشطاً
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }
    
    // MARK: - معالجة نقر المستخدم على الإشعار
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        if let reminderId = userInfo["reminderId"] as? String {
            print("👆 تم النقر على الإشعار: \(reminderId)")
            // يمكن إضافة منطق إضافي هنا
        }
        
        completionHandler()
    }
}

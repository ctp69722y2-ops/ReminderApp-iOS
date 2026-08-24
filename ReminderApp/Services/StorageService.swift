import Foundation

// MARK: - خدمة التخزين المحلي
class StorageService {
    static let shared = StorageService()
    
    private let remindersKey = "reminders_key"
    private let userDefaults = UserDefaults.standard
    
    private init() {}
    
    // MARK: - حفظ التذكيرات
    func saveReminders(_ reminders: [Reminder]) {
        do {
            let encoded = try JSONEncoder().encode(reminders)
            userDefaults.set(encoded, forKey: remindersKey)
            print("✅ تم حفظ \(reminders.count) تذكيرات بنجاح")
        } catch {
            print("❌ خطأ في حفظ التذكيرات: \(error.localizedDescription)")
        }
    }
    
    // MARK: - تحميل التذكيرات
    func loadReminders() -> [Reminder] {
        do {
            guard let data = userDefaults.data(forKey: remindersKey) else {
                print("لا توجد تذكيرات محفوظة")
                return []
            }
            
            let reminders = try JSONDecoder().decode([Reminder].self, from: data)
            print("✅ تم تحميل \(reminders.count) تذكيرات بنجاح")
            return reminders
        } catch {
            print("❌ خطأ في تحميل التذكيرات: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - حذف جميع البيانات
    func clearAllData() {
        userDefaults.removeObject(forKey: remindersKey)
        print("✅ تم حذف جميع البيانات")
    }
    
    // MARK: - تصدير البيانات (JSON)
    func exportReminders() -> Data? {
        let reminders = loadReminders()
        do {
            let encoded = try JSONEncoder().encode(reminders)
            return encoded
        } catch {
            print("❌ خطأ في تصدير البيانات: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - استيراد البيانات (JSON)
    func importReminders(from data: Data) -> Bool {
        do {
            let reminders = try JSONDecoder().decode([Reminder].self, from: data)
            saveReminders(reminders)
            print("✅ تم استيراد \(reminders.count) تذكيرات بنجاح")
            return true
        } catch {
            print("❌ خطأ في استيراد البيانات: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - الحصول على إحصائيات
    func getStatistics() -> ReminderStatistics {
        let reminders = loadReminders()
        
        let totalCount = reminders.count
        let completedCount = reminders.filter { $0.isCompleted }.count
        let overdueCount = reminders.filter { $0.isOverdue }.count
        let upcomingCount = reminders.filter { !$0.isCompleted && !$0.isOverdue }.count
        
        return ReminderStatistics(
            totalCount: totalCount,
            completedCount: completedCount,
            overdueCount: overdueCount,
            upcomingCount: upcomingCount
        )
    }
}

// MARK: - إحصائيات التذكيرات
struct ReminderStatistics: Codable {
    let totalCount: Int
    let completedCount: Int
    let overdueCount: Int
    let upcomingCount: Int
    
    var completionPercentage: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount) * 100
    }
}

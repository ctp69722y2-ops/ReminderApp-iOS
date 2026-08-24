import Foundation

// MARK: - نموذج التذكير (Reminder Model)
struct Reminder: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var description: String
    var date: Date
    var time: Date
    var isCompleted: Bool = false
    var createdAt: Date = Date()
    var category: ReminderCategory = .personal
    var notificationEnabled: Bool = true
    
    enum ReminderCategory: String, Codable, CaseIterable {
        case work = "عمل"
        case personal = "شخصي"
        case health = "صحة"
        case shopping = "تسوق"
        case other = "آخر"
    }
    
    // MARK: - خاصية مساعدة للحصول على التاريخ والوقت معاً
    var fullDateTime: Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        
        var components = DateComponents()
        components.year = dateComponents.year
        components.month = dateComponents.month
        components.day = dateComponents.day
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        
        return calendar.date(from: components) ?? Date()
    }
    
    // MARK: - التحقق مما إذا كان الموعد قد مضى
    var isOverdue: Bool {
        !isCompleted && fullDateTime < Date()
    }
    
    // MARK: - الحصول على الفرق الزمني من الآن
    var timeUntilReminder: String {
        let now = Date()
        let components = Calendar.current.dateComponents([.day, .hour, .minute], from: now, to: fullDateTime)
        
        if let day = components.day, day > 0 {
            return "\(day) يوم"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour) ساعة"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute) دقيقة"
        } else {
            return "حالاً"
        }
    }
    
    // MARK: - تنسيق التاريخ للعرض
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        formatter.locale = Locale(identifier: "ar_SA")
        return formatter.string(from: date)
    }
    
    // MARK: - تنسيق الوقت للعرض
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "ar_SA")
        return formatter.string(from: time)
    }
    
    // MARK: - تنسيق شامل
    var formattedDateTime: String {
        return "\(formattedDate) الساعة \(formattedTime)"
    }
}

// MARK: - حالة التذكير
enum ReminderStatus {
    case upcoming
    case overdue
    case completed
    
    var displayName: String {
        switch self {
        case .upcoming:
            return "القادمة"
        case .overdue:
            return "المتأخرة"
        case .completed:
            return "المكتملة"
        }
    }
}

// MARK: - مدير التذكيرات (ViewModel)
class ReminderManager: ObservableObject {
    @Published var reminders: [Reminder] = []
    @Published var selectedCategory: Reminder.ReminderCategory = .personal
    
    private let storageService = StorageService.shared
    private let notificationService = NotificationService.shared
    
    init() {
        loadReminders()
    }
    
    // MARK: - تحميل التذكيرات
    func loadReminders() {
        reminders = storageService.loadReminders()
    }
    
    // MARK: - إضافة تذكير جديد
    func addReminder(_ reminder: Reminder) {
        reminders.append(reminder)
        saveReminders()
        
        if reminder.notificationEnabled {
            notificationService.scheduleReminder(reminder)
        }
    }
    
    // MARK: - حذف تذكير
    func deleteReminder(_ reminder: Reminder) {
        reminders.removeAll { $0.id == reminder.id }
        saveReminders()
        notificationService.cancelReminder(reminder.id)
    }
    
    // MARK: - تحديث تذكير
    func updateReminder(_ reminder: Reminder) {
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders[index] = reminder
            saveReminders()
            
            if reminder.notificationEnabled {
                notificationService.updateReminder(reminder)
            } else {
                notificationService.cancelReminder(reminder.id)
            }
        }
    }
    
    // MARK: - وضع علامة على تذكير كمكتمل
    func markAsCompleted(_ reminder: Reminder) {
        var updatedReminder = reminder
        updatedReminder.isCompleted = true
        updateReminder(updatedReminder)
    }
    
    // MARK: - الحصول على التذكيرات حسب الحالة
    func getReminders(by status: ReminderStatus) -> [Reminder] {
        switch status {
        case .upcoming:
            return reminders.filter { !$0.isCompleted && !$0.isOverdue }
                .sorted { $0.fullDateTime < $1.fullDateTime }
        case .overdue:
            return reminders.filter { $0.isOverdue }
                .sorted { $0.fullDateTime < $1.fullDateTime }
        case .completed:
            return reminders.filter { $0.isCompleted }
                .sorted { $0.createdAt > $1.createdAt }
        }
    }
    
    // MARK: - البحث عن التذكيرات
    func searchReminders(query: String) -> [Reminder] {
        guard !query.isEmpty else { return reminders }
        return reminders.filter { reminder in
            reminder.title.localizedCaseInsensitiveContains(query) ||
            reminder.description.localizedCaseInsensitiveContains(query)
        }
    }
    
    // MARK: - حفظ التذكيرات
    private func saveReminders() {
        storageService.saveReminders(reminders)
    }
    
    // MARK: - حذف جميع التذكيرات
    func deleteAllReminders() {
        reminders.removeAll()
        saveReminders()
        notificationService.cancelAllReminders()
    }
}

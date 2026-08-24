import SwiftUI

// MARK: - الشاشة الرئيسية
struct ContentView: View {
    @StateObject private var reminderManager = ReminderManager()
    @State private var showAddReminder = false
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                // MARK: - تبويب المواعيد القادمة
                UpcomingRemindersView(reminderManager: reminderManager)
                    .tabItem {
                        Label("القادمة", systemImage: "clock")
                    }
                    .tag(0)
                
                // MARK: - تبويب المواعيد المتأخرة
                OverdueRemindersView(reminderManager: reminderManager)
                    .tabItem {
                        Label("المتأخرة", systemImage: "exclamationmark.circle")
                    }
                    .tag(1)
                
                // MARK: - تبويب المواعيد المكتملة
                CompletedRemindersView(reminderManager: reminderManager)
                    .tabItem {
                        Label("المكتملة", systemImage: "checkmark.circle")
                    }
                    .tag(2)
                
                // MARK: - تبويب الإعدادات
                SettingsView(reminderManager: reminderManager)
                    .tabItem {
                        Label("الإعدادات", systemImage: "gear")
                    }
                    .tag(3)
            }
            
            // MARK: - زر إضافة تذكير
            VStack {
                HStack {
                    Spacer()
                    Button(action: { showAddReminder = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 56))
                            .foregroundColor(.blue)
                            .shadow(radius: 4)
                    }
                    .padding()
                }
                Spacer()
            }
        }
        .sheet(isPresented: $showAddReminder) {
            AddReminderView(reminderManager: reminderManager, isPresented: $showAddReminder)
        }
        .onAppear {
            setupNotifications()
        }
    }
    
    // MARK: - إعداد الإشعارات
    private func setupNotifications() {
        let notificationService = NotificationService.shared
        notificationService.checkNotificationPermission { granted in
            if !granted {
                notificationService.requestNotificationPermission { _ in }
            }
        }
        
        // تعيين المفوض
        UNUserNotificationCenter.current().delegate = NotificationDelegate()
    }
}

// MARK: - شاشة المواعيد القادمة
struct UpcomingRemindersView: View {
    @ObservedObject var reminderManager: ReminderManager
    @State private var showEditReminder = false
    @State private var selectedReminder: Reminder?
    
    var upcomingReminders: [Reminder] {
        reminderManager.getReminders(by: .upcoming)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                if upcomingReminders.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("لا توجد مواعيد قادمة")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("أضف موعد جديد للبدء")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                } else {
                    List {
                        ForEach(upcomingReminders) { reminder in
                            ReminderRowView(reminder: reminder)
                                .onTapGesture {
                                    selectedReminder = reminder
                                    showEditReminder = true
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        reminderManager.deleteReminder(reminder)
                                    } label: {
                                        Label("حذف", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        reminderManager.markAsCompleted(reminder)
                                    } label: {
                                        Label("إكمال", systemImage: "checkmark")
                                    }
                                    .tint(.green)
                                }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("المواعيد القادمة")
            .sheet(isPresented: $showEditReminder) {
                if let reminder = selectedReminder {
                    EditReminderView(
                        reminderManager: reminderManager,
                        reminder: reminder,
                        isPresented: $showEditReminder
                    )
                }
            }
        }
    }
}

// MARK: - شاشة المواعيد المتأخرة
struct OverdueRemindersView: View {
    @ObservedObject var reminderManager: ReminderManager
    
    var overdueReminders: [Reminder] {
        reminderManager.getReminders(by: .overdue)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                if overdueReminders.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        Text("ممتاز! لا توجد مواعيد متأخرة")
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                } else {
                    List {
                        ForEach(overdueReminders) { reminder in
                            ReminderRowView(reminder: reminder)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        reminderManager.deleteReminder(reminder)
                                    } label: {
                                        Label("حذف", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        reminderManager.markAsCompleted(reminder)
                                    } label: {
                                        Label("إكمال", systemImage: "checkmark")
                                    }
                                    .tint(.green)
                                }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("المواعيد المتأخرة")
        }
    }
}

// MARK: - شاشة المواعيد المكتملة
struct CompletedRemindersView: View {
    @ObservedObject var reminderManager: ReminderManager
    
    var completedReminders: [Reminder] {
        reminderManager.getReminders(by: .completed)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                if completedReminders.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("لا توجد مواعيد مكتملة")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                } else {
                    List {
                        ForEach(completedReminders) { reminder in
                            ReminderRowView(reminder: reminder)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        reminderManager.deleteReminder(reminder)
                                    } label: {
                                        Label("حذف", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("المواعيد المكتملة")
        }
    }
}

// MARK: - صف التذكير
struct ReminderRowView: View {
    let reminder: Reminder
    
    var statusColor: Color {
        if reminder.isCompleted {
            return .green
        } else if reminder.isOverdue {
            return .red
        } else {
            return .blue
        }
    }
    
    var statusIcon: String {
        if reminder.isCompleted {
            return "checkmark.circle.fill"
        } else if reminder.isOverdue {
            return "exclamationmark.circle.fill"
        } else {
            return "clock.fill"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: statusIcon)
                            .foregroundColor(statusColor)
                        Text(reminder.title)
                            .font(.headline)
                            .lineLimit(1)
                    }
                    
                    Text(reminder.description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(reminder.formattedTime)
                        .font(.caption)
                        .foregroundColor(.blue)
                    Text(reminder.timeUntilReminder)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            
            HStack(spacing: 12) {
                Image(systemName: "tag.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                Text(reminder.category.rawValue)
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
}

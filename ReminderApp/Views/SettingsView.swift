import SwiftUI

// MARK: - شاشة الإعدادات
struct SettingsView: View {
    @ObservedObject var reminderManager: ReminderManager
    @State private var showClearAlert = false
    @State private var statistics: ReminderStatistics?
    
    var body: some View {
        NavigationView {
            List {
                // MARK: - قسم الإحصائيات
                Section(header: Text("الإحصائيات")) {
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("إجمالي التذكيرات")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text("\(statistics?.totalCount ?? 0)")
                                    .font(.headline)
                            }
                            Spacer()
                            Image(systemName: "square.stack.3d.up")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                        }
                        
                        Divider()
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("المكتملة")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text("\(statistics?.completedCount ?? 0)")
                                        .font(.headline)
                                        .foregroundColor(.green)
                                }
                                
                                HStack {
                                    Text("القادمة")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text("\(statistics?.upcomingCount ?? 0)")
                                        .font(.headline)
                                        .foregroundColor(.blue)
                                }
                                
                                HStack {
                                    Text("المتأخرة")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text("\(statistics?.overdueCount ?? 0)")
                                        .font(.headline)
                                        .foregroundColor(.red)
                                }
                            }
                            Spacer()
                        }
                        
                        // MARK: - شريط التقدم
                        if let stats = statistics, stats.totalCount > 0 {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("نسبة الإكمال")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                ProgressView(value: stats.completionPercentage / 100)
                                    .tint(.green)
                                
                                Text("\(String(format: "%.1f", stats.completionPercentage))%")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // MARK: - قسم الإخطارات
                Section(header: Text("الإخطارات والتذكيرات")) {
                    NavigationLink(destination: NotificationSettingsView()) {
                        HStack {
                            Image(systemName: "bell.badge")
                                .foregroundColor(.orange)
                            Text("إعدادات الإخطارات")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                // MARK: - قسم البيانات
                Section(header: Text("البيانات والتخزين")) {
                    NavigationLink(destination: DataManagementView(reminderManager: reminderManager)) {
                        HStack {
                            Image(systemName: "externaldrive")
                                .foregroundColor(.blue)
                            Text("إدارة البيانات")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                // MARK: - قسم الحول
                Section(header: Text("معلومات التطبيق")) {
                    HStack {
                        Text("الإصدار")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("المطور")
                        Spacer()
                        Text("ReminderApp Team")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("اللغة")
                        Spacer()
                        Text("العربية")
                            .foregroundColor(.gray)
                    }
                }
                
                // MARK: - قسم الخطورة
                Section {
                    Button(role: .destructive) {
                        showClearAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("حذف جميع التذكيرات")
                        }
                    }
                }
            }
            .navigationTitle("الإعدادات")
            .navigationBarTitleDisplayMode(.inline)
            .alert("تحذير", isPresented: $showClearAlert) {
                Button("إلغاء", role: .cancel) { }
                Button("حذف الجميع", role: .destructive) {
                    reminderManager.deleteAllReminders()
                }
            } message: {
                Text("هل أنت متأكد من حذف جميع التذكيرات؟ لا يمكن التراجع عن هذا الإجراء")
            }
            .onAppear {
                updateStatistics()
            }
        }
    }
    
    private func updateStatistics() {
        statistics = StorageService.shared.getStatistics()
    }
}

// MARK: - شاشة إعدادات الإخطارات
struct NotificationSettingsView: View {
    @State private var notificationsEnabled = true
    @State private var soundEnabled = true
    @State private var badgeEnabled = true
    
    var body: some View {
        List {
            Section(header: Text("الإخطارات")) {
                Toggle("تفعيل الإخطارات", isOn: $notificationsEnabled)
                Toggle("تشغيل الأصوات", isOn: $soundEnabled)
                Toggle("إظهار الشارة", isOn: $badgeEnabled)
            }
            
            Section(header: Text("الوقت والتكرار")) {
                NavigationLink(destination: Text("قريباً")) {
                    HStack {
                        Text("وقت التنبيه الافتراضي")
                        Spacer()
                        Text("5 دقائق قبل")
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Section {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    Text("التغييرات يتم حفظها تلقائياً")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .navigationTitle("إعدادات الإخطارات")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - شاشة إدارة البيانات
struct DataManagementView: View {
    @ObservedObject var reminderManager: ReminderManager
    @State private var showExportAlert = false
    @State private var showImportSheet = false
    
    var body: some View {
        List {
            Section(header: Text("خيارات التصدير والاستيراد")) {
                Button(action: { exportData() }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.blue)
                        Text("تصدير البيانات")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Button(action: { showImportSheet = true }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                            .foregroundColor(.blue)
                        Text("استيراد البيانات")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Section(header: Text("معلومات التخزين")) {
                HStack {
                    Text("عدد التذكيرات")
                    Spacer()
                    Text("\(reminderManager.reminders.count)")
                        .foregroundColor(.blue)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("آخر تحديث")
                    Spacer()
                    Text(getCurrentDate())
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
            
            Section(header: Text("نسخ احتياطية")) {
                HStack {
                    Image(systemName: "icloud.and.arrow.down")
                        .foregroundColor(.gray)
                    Text("النسخ الاحتياطية (قريباً)")
                        .foregroundColor(.gray)
                }
            }
        }
        .navigationTitle("إدارة البيانات")
        .navigationBarTitleDisplayMode(.inline)
        .alert("تم التصدير", isPresented: $showExportAlert) {
            Button("حسناً") { }
        } message: {
            Text("تم تصدير البيانات بنجاح")
        }
    }
    
    private func exportData() {
        if let _ = StorageService.shared.exportReminders() {
            showExportAlert = true
        }
    }
    
    private func getCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm"
        formatter.locale = Locale(identifier: "ar_SA")
        return formatter.string(from: Date())
    }
}

#Preview {
    SettingsView(reminderManager: ReminderManager())
}

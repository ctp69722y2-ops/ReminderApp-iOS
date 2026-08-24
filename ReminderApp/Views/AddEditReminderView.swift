import SwiftUI

// MARK: - شاشة إضافة تذكير جديد
struct AddReminderView: View {
    @ObservedObject var reminderManager: ReminderManager
    @Binding var isPresented: Bool
    
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var selectedDate = Date()
    @State private var selectedTime = Date()
    @State private var selectedCategory: Reminder.ReminderCategory = .personal
    @State private var notificationEnabled = true
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - قسم العنوان والوصف
                Section(header: Text("معلومات التذكير")) {
                    TextField("العنوان", text: $title)
                    TextField("الوصف (اختياري)", text: $description, axis: .vertical)
                        .lineLimit(3...5)
                }
                
                // MARK: - قسم التاريخ والوقت
                Section(header: Text("التاريخ والوقت")) {
                    DatePicker(
                        "التاريخ",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                    .environment(\.locale, Locale(identifier: "ar_SA"))
                    
                    DatePicker(
                        "الوقت",
                        selection: $selectedTime,
                        displayedComponents: .hourAndMinute
                    )
                    .environment(\.locale, Locale(identifier: "ar_SA"))
                }
                
                // MARK: - قسم التصنيف
                Section(header: Text("التصنيف")) {
                    Picker("اختر التصنيف", selection: $selectedCategory) {
                        ForEach(Reminder.ReminderCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                }
                
                // MARK: - قسم الإشعارات
                Section(header: Text("الإشعارات")) {
                    Toggle("تفعيل التذكيرات", isOn: $notificationEnabled)
                }
                
                // MARK: - قسم المعاينة
                Section(header: Text("معاينة")) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("العنوان:")
                                .fontWeight(.semibold)
                            Spacer()
                            Text(title.isEmpty ? "لم يتم إدخال عنوان" : title)
                                .foregroundColor(.gray)
                        }
                        
                        HStack {
                            Text("الموعد:")
                                .fontWeight(.semibold)
                            Spacer()
                            Text(formatDateTime())
                                .foregroundColor(.blue)
                        }
                        
                        HStack {
                            Text("التصنيف:")
                                .fontWeight(.semibold)
                            Spacer()
                            Text(selectedCategory.rawValue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                }
            }
            .navigationTitle("إضافة تذكير جديد")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("إلغاء") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("حفظ") {
                        saveReminder()
                    }
                    .disabled(!isFormValid)
                    .fontWeight(.semibold)
                }
            }
            .alert("تنبيه", isPresented: $showAlert) {
                Button("حسناً") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // MARK: - حفظ التذكير
    private func saveReminder() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        
        guard !trimmedTitle.isEmpty else {
            alertMessage = "يجب إدخال عنوان للتذكير"
            showAlert = true
            return
        }
        
        // التحقق من أن الموعد ليس في الماضي
        let reminderDateTime = createReminderDateTime()
        if reminderDateTime < Date() {
            alertMessage = "لا يمكن إنشاء تذكير في الماضي"
            showAlert = true
            return
        }
        
        let newReminder = Reminder(
            title: trimmedTitle,
            description: description,
            date: selectedDate,
            time: selectedTime,
            category: selectedCategory,
            notificationEnabled: notificationEnabled
        )
        
        reminderManager.addReminder(newReminder)
        alertMessage = "✅ تم إضافة التذكير بنجاح"
        showAlert = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isPresented = false
        }
    }
    
    // MARK: - إنشاء تاريخ ووقت التذكير
    private func createReminderDateTime() -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)
        
        var components = DateComponents()
        components.year = dateComponents.year
        components.month = dateComponents.month
        components.day = dateComponents.day
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        
        return calendar.date(from: components) ?? Date()
    }
    
    // MARK: - تنسيق التاريخ والوقت للعرض
    private func formatDateTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm"
        formatter.locale = Locale(identifier: "ar_SA")
        return formatter.string(from: createReminderDateTime())
    }
}

// MARK: - شاشة تعديل التذكير
struct EditReminderView: View {
    @ObservedObject var reminderManager: ReminderManager
    @Binding var isPresented: Bool
    
    let reminder: Reminder
    
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var selectedDate = Date()
    @State private var selectedTime = Date()
    @State private var selectedCategory: Reminder.ReminderCategory = .personal
    @State private var notificationEnabled = true
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - قسم العنوان والوصف
                Section(header: Text("معلومات التذكير")) {
                    TextField("العنوان", text: $title)
                    TextField("الوصف (اختياري)", text: $description, axis: .vertical)
                        .lineLimit(3...5)
                }
                
                // MARK: - قسم التاريخ والوقت
                Section(header: Text("التاريخ والوقت")) {
                    DatePicker(
                        "التاريخ",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                    .environment(\.locale, Locale(identifier: "ar_SA"))
                    
                    DatePicker(
                        "الوقت",
                        selection: $selectedTime,
                        displayedComponents: .hourAndMinute
                    )
                    .environment(\.locale, Locale(identifier: "ar_SA"))
                }
                
                // MARK: - قسم التصنيف
                Section(header: Text("التصنيف")) {
                    Picker("اختر التصنيف", selection: $selectedCategory) {
                        ForEach(Reminder.ReminderCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                }
                
                // MARK: - قسم الإشعارات
                Section(header: Text("الإشعارات")) {
                    Toggle("تفعيل التذكيرات", isOn: $notificationEnabled)
                }
            }
            .navigationTitle("تعديل التذكير")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("إلغاء") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("حفظ") {
                        updateReminder()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("تنبيه", isPresented: $showAlert) {
                Button("حسناً") { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                setupFormValues()
            }
        }
    }
    
    // MARK: - تحضير قيم النموذج
    private func setupFormValues() {
        title = reminder.title
        description = reminder.description
        selectedDate = reminder.date
        selectedTime = reminder.time
        selectedCategory = reminder.category
        notificationEnabled = reminder.notificationEnabled
    }
    
    // MARK: - تحديث التذكير
    private func updateReminder() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        
        guard !trimmedTitle.isEmpty else {
            alertMessage = "يجب إدخال عنوان للتذكير"
            showAlert = true
            return
        }
        
        var updatedReminder = reminder
        updatedReminder.title = trimmedTitle
        updatedReminder.description = description
        updatedReminder.date = selectedDate
        updatedReminder.time = selectedTime
        updatedReminder.category = selectedCategory
        updatedReminder.notificationEnabled = notificationEnabled
        
        reminderManager.updateReminder(updatedReminder)
        alertMessage = "✅ تم تحديث التذكير بنجاح"
        showAlert = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isPresented = false
        }
    }
}

#Preview {
    @State var isPresented = true
    
    return AddReminderView(
        reminderManager: ReminderManager(),
        isPresented: $isPresented
    )
}

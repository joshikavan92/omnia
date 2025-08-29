import CoreLocation
import SwiftUI

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    // Published properties
    @Published var latitude: Double = 0.0
    @Published var longitude: Double = 0.0
    @Published var batteryLevel: Int = 0
    @Published var isSyncOn: Bool = false
    @Published var alertMessage: String = "No Alerts"
    @Published var serialNumber: String = ""   // <-- add this

    private let locationManager = CLLocationManager()
    private let managedKey = "com.apple.configuration.managed"

    override init() {
        super.init()

        // Battery
        UIDevice.current.isBatteryMonitoringEnabled = true
        batteryLevel = Self.currentBatteryPercent()

        // Location
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        // Load Managed App Config once
        loadManagedConfig()

        // Watch for config/battery updates
        NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.loadManagedConfig()
        }

        NotificationCenter.default.addObserver(
            forName: UIDevice.batteryLevelDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.batteryLevel = Self.currentBatteryPercent()
        }

        self.isSyncOn = true
    }

    private func loadManagedConfig() {
        let cfg = UserDefaults.standard.dictionary(forKey: managedKey)
        print("Full managed config: \(cfg ?? [:])")
        let serial = (cfg?["SERIAL_NUMBER"] as? String) ?? ""
        if serialNumber != serial {
            serialNumber = serial
            print("Managed Config serial: \(serial.isEmpty ? "<none>" : serial)")
        }
        
        // Additional debugging
        print("Managed key: \(managedKey)")
        print("UserDefaults contains managed config: \(UserDefaults.standard.object(forKey: managedKey) != nil)")
    }

    private static func currentBatteryPercent() -> Int {
        let level = UIDevice.current.batteryLevel
        return level < 0 ? 0 : Int(level * 100)
    }

    // CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        latitude = location.coordinate.latitude
        longitude = location.coordinate.longitude
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}

struct ContentView: View {
    @AppStorage("hasAcceptedTerms") private var hasAcceptedTerms = false
    @State private var showTerms = true
    @State private var showDeviceInfo = false
    @StateObject private var locationManager = LocationManager()

    // This can change if the app is reinstalled or vendor changes
    private let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"

    // Fires every 60 seconds
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header with Branding
                    headerSection
                    
                    // Hero Section
                    heroSection
                    
                    // Primary Actions
                    primaryActionsSection
                    
                    // Secondary Actions
                    secondaryActionsSection
                    
                    // Contact Section
                    contactSection
                    
                    // Trust & Safety
                    trustSafetySection
                    
                    // Device Info Button (hidden but accessible)
                    deviceInfoButton
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
        .onReceive(timer) { _ in
            sendDeviceData()
        }
        .onAppear {
            if !hasAcceptedTerms { showTerms = true }
        }
        .alert("Terms & Conditions", isPresented: $showTerms) {
            Button("I Agree") {
                hasAcceptedTerms = true
                showTerms = false
                print("User accepted terms")
            }
        } message: {
            Text("By using this app, you consent to the collection and use of your location data for providing tracking services. Your data will only be used for the stated purpose and will not be shared with third parties without your consent, except as required by law. Continued use of the app implies acceptance of these terms.")
        }
        .sheet(isPresented: $showDeviceInfo) {
            DeviceInfoView(locationManager: locationManager, deviceId: deviceId)
        }
    }
    
    // MARK: - UI Components
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            // Maruti Suzuki Logo (placeholder - you can replace with actual logo)
            Image(systemName: "car.fill")
                .font(.system(size: 40))
                .foregroundColor(.blue)
                .padding(.top, 20)
            
            Text("Maruti Suzuki")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Official Info (India)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
    }
    
    private var heroSection: some View {
        VStack(spacing: 12) {
            Text("Cars are what Maruti Suzuki builds. Experiences are what it creates.")
                .font(.title3)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
                .padding(.horizontal, 20)
            
            Text("Experiences fuelled by innovations, forward thinking, and a commitment to bring the very best to Indian roads.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
            
            HStack(spacing: 20) {
                Text("Technology")
                Text("·")
                Text("Experience")
                Text("·")
                Text("Design")
            }
            .font(.caption)
            .foregroundColor(.blue)
            .padding(.top, 8)
        }
        .padding(.vertical, 20)
        .background(Color(.systemBackground))
    }
    
    private var primaryActionsSection: some View {
        VStack(spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                ActionButton(
                    title: "Book Test Drive",
                    icon: "car.fill",
                    color: .blue
                ) {
                    // Action for test drive
                }
                
                ActionButton(
                    title: "Get Price List",
                    icon: "list.bullet",
                    color: .green
                ) {
                    // Action for price list
                }
                
                ActionButton(
                    title: "Locate a Dealer",
                    icon: "location.fill",
                    color: .orange
                ) {
                    // Action for dealer location
                }
                
                ActionButton(
                    title: "Book Service",
                    icon: "wrench.and.screwdriver.fill",
                    color: .purple
                ) {
                    // Action for service booking
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 20)
        .background(Color(.systemBackground))
    }
    
    private var secondaryActionsSection: some View {
        VStack(spacing: 16) {
            Text("Additional Services")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                SecondaryActionButton(title: "Insurance", icon: "shield.fill")
                SecondaryActionButton(title: "Accessories", icon: "car.2.fill")
                SecondaryActionButton(title: "Parts", icon: "gearshape.fill")
                SecondaryActionButton(title: "Finance", icon: "creditcard.fill")
                SecondaryActionButton(title: "Rewards", icon: "star.fill")
                SecondaryActionButton(title: "Leasing", icon: "doc.text.fill")
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 20)
        .background(Color(.systemBackground))
    }
    
    private var contactSection: some View {
        VStack(spacing: 16) {
            Text("Contact Us")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                ContactButton(
                    title: "Toll-free: 1800 102 1800",
                    icon: "phone.fill",
                    action: { callTollFree() }
                )
                
                ContactButton(
                    title: "Email: contact@maruti.co.in",
                    icon: "envelope.fill",
                    action: { sendEmail() }
                )
                
                ContactButton(
                    title: "Chat with us",
                    icon: "message.fill",
                    action: { openChat() }
                )
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 20)
        .background(Color(.systemBackground))
    }
    
    private var trustSafetySection: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Caution: Beware of fake promotions or offers.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button("Know more") {
                    // Action for more info
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            .padding(.horizontal, 20)
            
            Text("Fuelled by innovation, designed for Indian roads since 1983.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
    
    private var deviceInfoButton: some View {
        Button(action: { showDeviceInfo = true }) {
            Image(systemName: "info.circle")
                .font(.title2)
                .foregroundColor(.blue)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.trailing, 20)
        .padding(.top, 10)
    }
    
    // MARK: - Actions
    
    private func callTollFree() {
        if let url = URL(string: "tel:18001021800") {
            UIApplication.shared.open(url)
        }
    }
    
    private func sendEmail() {
        if let url = URL(string: "mailto:contact@maruti.co.in") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openChat() {
        // Implement chat functionality
    }

    private func sendDeviceData() {
        guard let url = URL(string: "https://peqjrdaiabwsnbwflnpk.supabase.co/functions/v1/update-device-location") else {
            print("Invalid URL"); return
        }

        let body: [String: Any] = [
            "device_id": deviceId,
            "latitude": locationManager.latitude,
            "longitude": locationManager.longitude,
            "battery_level": locationManager.batteryLevel,
            "accuracy_meters": 50,
            // Optional: include serial if you want to store it upstream
            "serial_number": locationManager.serialNumber
        ]

        guard let json = try? JSONSerialization.data(withJSONObject: body) else {
            print("Failed to encode JSON"); return
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = json

        URLSession.shared.dataTask(with: req) { data, resp, err in
            if let err = err { print("Error: \(err)"); return }
            if let http = resp as? HTTPURLResponse { print("Status Code: \(http.statusCode)") }
            if let data = data, let text = String(data: data, encoding: .utf8) { print("Response: \(text)") }
        }.resume()
    }
}

// MARK: - Supporting Views

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SecondaryActionButton: View {
    let title: String
    let icon: String
    
    var body: some View {
        Button(action: {}) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ContactButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 20)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DeviceInfoView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var locationManager: LocationManager
    let deviceId: String
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Device Information")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.bottom, 10)
                    
                    InfoRow(icon: "location.fill", title: "Current Location", value: "Lat: \(locationManager.latitude)\nLon: \(locationManager.longitude)")
                    
                    InfoRow(icon: "bolt.fill", title: "Battery Level", value: "\(locationManager.batteryLevel)%")
                    
                    InfoRow(icon: "apps.iphone", title: "Device ID", value: deviceId)
                    
                    InfoRow(icon: "number.circle", title: "Serial Number", value: locationManager.serialNumber.isEmpty ? "Not provided" : locationManager.serialNumber)
                    
                    InfoRow(icon: "arrow.trianglehead.2.clockwise.rotate.90", title: "Location Data", value: locationManager.isSyncOn ? "Sync On" : "Sync Off")
                    
                    InfoRow(icon: "exclamationmark.shield", title: "Location Alerts", value: locationManager.alertMessage)
                }
                .padding()
            }
            .navigationTitle("Device Info")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    ContentView()
}

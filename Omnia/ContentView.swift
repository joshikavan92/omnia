import CoreLocation
import SwiftUI

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    // Published properties
    @Published var latitude: Double = 0.0
    @Published var longitude: Double = 0.0
    @Published var batteryLevel: Int = 0
    @Published var isSyncOn: Bool = false
    @Published var alertMessage: String = "No Alerts"
    @Published var serialNumber: String = ""
    @Published var email: String = ""
    @Published var fullName: String = ""

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
        
        // Load Serial Number
        let serial = (cfg?["SERIAL_NUMBER"] as? String) ?? ""
        if serialNumber != serial {
            serialNumber = serial
            print("Managed Config serial: \(serial.isEmpty ? "<none>" : serial)")
        }
        
        // Load Email
        let userEmail = (cfg?["email"] as? String) ?? ""
        if email != userEmail {
            email = userEmail
            print("Managed Config email: \(userEmail.isEmpty ? "<none>" : userEmail)")
        }
        
        // Load Full Name
        let userFullName = (cfg?["firstName"] as? String) ?? ""
        if fullName != userFullName {
            fullName = userFullName
            print("Managed Config fullName: \(userFullName.isEmpty ? "<none>" : userFullName)")
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
                    
                    // Contact IT Section
                    contactITSection
                    
                    // Contact Section
                    contactSection
                    
                    Spacer()
                    
                    // Device Info Button (bottom right)
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
            // Maruti Suzuki Logo
            Image("MarutiLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 40)
                .padding(.top, 20)
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
    
    private var contactITSection: some View {
        VStack(spacing: 16) {
            Text("Contact IT")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                ContactButton(
                    title: "IT Support",
                    icon: "laptopcomputer",
                    action: { contactITSupport() }
                )
                
                ContactButton(
                    title: "Request App",
                    icon: "key.fill",
                    action: { openJamfSelfService() }
                )
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
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 20)
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
        .padding(.bottom, 20)
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
    
    // MARK: - IT Contact Functions
    
    private func contactITSupport() {
        // Implement IT support contact
    }
    
    private func openJamfSelfService() {
        // Open Jamf Self Service app
        if let url = URL(string: "jamfselfservice://") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                // Fallback: try to open App Store for Jamf Self Service
                if let appStoreURL = URL(string: "https://apps.apple.com/app/jamf-self-service/id1234567890") {
                    UIApplication.shared.open(appStoreURL)
                }
            }
        }
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
            "serial_number": locationManager.serialNumber,
            "email": locationManager.email,
            "full_name": locationManager.fullName
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
                    
                    InfoRow(icon: "envelope.fill", title: "Email", value: locationManager.email.isEmpty ? "Not provided" : locationManager.email)
                    
                    InfoRow(icon: "person.fill", title: "Full Name", value: locationManager.fullName.isEmpty ? "Not provided" : locationManager.fullName)
                    
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

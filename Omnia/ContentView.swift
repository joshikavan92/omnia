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
    @StateObject private var locationManager = LocationManager()

    // This can change if the app is reinstalled or vendor changes
    private let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"

    // Fires every 60 seconds
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            Text("Omnia")
                .font(.largeTitle).bold()
                .padding(.bottom, 20)

            // Location
            HStack {
                Image(systemName: "location.fill").font(.title2)
                VStack(alignment: .leading) {
                    Text("Your Current Location").font(.headline)
                    Text("Latitude: \(locationManager.latitude)")
                    Text("Longitude: \(locationManager.longitude)")
                }
            }

            // Battery
            HStack {
                Image(systemName: "bolt.fill").font(.title2)
                VStack(alignment: .leading) {
                    Text("Battery Level").font(.headline)
                    Text("\(locationManager.batteryLevel)%")
                }
            }

            // Device ID
            HStack {
                Image(systemName: "apps.iphone").font(.title2)
                VStack(alignment: .leading) {
                    Text("Device ID").font(.headline)
                    Text(deviceId)
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            // Serial Number (from Jamf Managed App Config)
            HStack {
                Image(systemName: "number.circle").font(.title2)
                VStack(alignment: .leading) {
                    Text("Serial Number").font(.headline)
                    Text(locationManager.serialNumber.isEmpty ? "Not provided" : locationManager.serialNumber)
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            // Sync status
            HStack {
                Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90").font(.title2)
                VStack(alignment: .leading) {
                    Text("Location Data").font(.headline)
                    Text(locationManager.isSyncOn ? "Sync On" : "Sync Off")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
            }

            // Alerts
            HStack {
                Image(systemName: "exclamationmark.shield").font(.title2)
                VStack(alignment: .leading) {
                    Text("Location Alerts").font(.headline)
                    Text(locationManager.alertMessage)
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
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

#Preview {
    ContentView()
}

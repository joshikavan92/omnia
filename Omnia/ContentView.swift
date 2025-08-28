//
//  ContentView.swift
//  Omnia
//
//  Created by George S Christopher on 17/08/25.
//

import CoreLocation
import SwiftUI

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var latitude: Double = 0.0
    @Published var longitude: Double = 0.0
    @Published var batteryLevel: Int = 0
    @Published var isSyncOn: Bool = false
    @Published var alertMessage: String = "No Alerts"
    @Published var SERIAL_NUMBER: String = ""
    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        UIDevice.current.isBatteryMonitoringEnabled = true
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization() // Request permission
        locationManager.startUpdatingLocation() // Start receiving updates
        batteryLevel = Int(UIDevice.current.batteryLevel * 100)
        
        //Get Serial# from JAMF
        print("Serial Number: \(SERIAL_NUMBER)")
        self.isSyncOn = true
    }

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
    let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
    // Timer that fires every 60 seconds
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 40) {
               Text("Omnia")
                   .font(.largeTitle)
                   .bold()
                   .padding(.bottom, 20)

               // Location
               HStack {
                   Image(systemName: "location.fill")
                       .foregroundColor(.blue)
                       .font(.title2)
                   VStack(alignment: .leading) {
                       Text("Your Current Location")
                           .font(.headline)
                       Text("Latitude: \(locationManager.latitude)")
                       Text("Longitude: \(locationManager.longitude)")
                   }
               }

               // Battery
               HStack {
                   Image(systemName: "bolt.fill")
                       .foregroundColor(.green)
                       .font(.title2)
                   VStack(alignment: .leading) {
                       Text("Battery Level")
                           .font(.headline)
                       Text("\(Int(locationManager.batteryLevel))%")
                   }
               }

               // Device ID
               HStack {
                   Image(systemName: "apps.iphone")
                       .foregroundColor(.orange)
                       .font(.title2)
                   VStack(alignment: .leading) {
                       Text("Device ID")
                           .font(.headline)
                       Text(deviceId)
                           .font(.footnote)
                           .foregroundColor(.gray)
                           .lineLimit(1)
                           .truncationMode(.middle)
                   }
               }
            
            // Device ID
            HStack {
                Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                    .foregroundColor(.green)
                    .font(.title2)
                VStack(alignment: .leading) {
                    Text("Location Data")
                        .font(.headline)
                    Text(locationManager.isSyncOn ? "Sync On" : "Sync Off")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            
            // Device ID
            HStack {
                Image(systemName: "exclamationmark.shield")
                    .foregroundColor(.red)
                    .font(.title2)
                VStack(alignment: .leading) {
                    Text("Location Alerts")
                        .font(.headline)
                    Text(locationManager.alertMessage)
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            

         
            /*Button("Send Device Data") {
                    sendDeviceData()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)*/
        }
        .onReceive(timer) { _ in
            sendDeviceData()
        }
        .onAppear {
                    if !hasAcceptedTerms {
                        showTerms = true
                    }
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
    
    func sendDeviceData() {
            guard let url = URL(string: "https://peqjrdaiabwsnbwflnpk.supabase.co/functions/v1/update-device-location") else {
                print("Invalid URL")
                return
            }

        let requestBody: [String: Any] = [
            "device_id": deviceId,
            "latitude": locationManager.latitude,
            "longitude": locationManager.longitude,
            "battery_level": locationManager.batteryLevel,
            "accuracy_meters": 50
        ]

            guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
                print("Failed to encode JSON")
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData

            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error: \(error)")
                    return
                }

                if let httpResponse = response as? HTTPURLResponse {
                    print("Status Code: \(httpResponse.statusCode)")
                }

                if let data = data,
                   let responseBody = String(data: data, encoding: .utf8) {
                    print("Response: \(responseBody)")
                }
            }.resume()
        }
}

#Preview {
    ContentView()
}

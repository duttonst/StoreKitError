//
//  ContentView.swift
//  StoreKitError
//
//  Created by Andrew Jones on 20/07/2021.
//

import SwiftUI
import StoreKit

struct ContentView: View {
    
    @State private var error: NSError? = err(no: 0, message: "Checking capabilities...")
    
    var body: some View {
        
        let isError = !(error == nil)
        let bgColour = isError ? UIColor.red : UIColor.green
        let fgColour = isError ? UIColor.white : UIColor.black
        let codeno = error?.code ?? 0
        let code = (codeno == 0) ? "" : "[\(String(codeno))] "
        let message = error?.localizedDescription ?? "Everything is good!"
        let fulldesc = "\(code)\(message)"
        
        VStack {
            Text(fulldesc)
                .padding()
        }
        .foregroundColor(Color(fgColour))
        .background(Color(bgColour))
        .onAppear() {
            storeKit_Auth() { nserror in
                self.error = nserror
            }
        }
    }
}

func storeKit_Auth(completion: @escaping (NSError?) -> Void) {
    
    switch SKCloudServiceController.authorizationStatus() {
    case .notDetermined:
        SKCloudServiceController.requestAuthorization({ (status) in
            switch status {
            case .notDetermined:
                completion(err(no: -33001, message: "SKCloudServiceController: authorisation status not determined even after requestAuthorization"))
                
            case .denied:
                completion(err(no: -33011, message: "requestAuthorization reports that media access is denied"))
                
            case .restricted:
                completion(err(no: -33012, message: "requestAuthorization reports that media access is restricted"))
                
            case .authorized:
                capability_Check(completion: completion)
                
            @unknown default:
                completion(err(no: -33002, message: "requestAuthorization: unknown authorisation status returned"))
            }
        })

    case .denied:
        completion(err(no: -33041, message: "authorizationStatus reports that media access is denied"))
        
    case .restricted:
        completion(err(no: -33042, message: "authorizationStatus reports that media access is restricted"))
        
    case .authorized:
        capability_Check(completion: completion)
        
    @unknown default:
        completion(err(no: -33044, message: "authorizationStatus: unknown authorisation status returned"))
    }
}

func capability_Check(completion: @escaping (NSError?) -> Void) {

    SKCloudServiceController().requestCapabilities(completionHandler: { (capabilities, error) in

        if let error = error {
            if let skerror = error as? SKError {
                switch skerror.code {
                case .unknown:
                    // This is the error that happens on some production machines:
                    completion(err(no: -33017, message: "[\(skerror.errorCode)] [\(skerror.userStuff)] requestCapabilities reports an unknown error: \(skerror.localizedDescription)"))
                case .cloudServicePermissionDenied:
                    completion(err(no: -33013, message: "[\(skerror.errorCode)] [\(skerror.userStuff)] requestCapabilities reports cloudServicePermissionDenied"))
                case .cloudServiceNetworkConnectionFailed:
                    completion(err(no: -33014, message: "[\(skerror.errorCode)] [\(skerror.userStuff)] requestCapabilities reports cloudServiceNetworkConnectionFailed"))
                default:
                    completion(err(no: -33019, message: "[\(skerror.errorCode)] [\(skerror.userStuff)] requestCapabilities reports an unexpected error: \(skerror.localizedDescription)"))
                }
            } else {
                completion(err(no: -33018, message: "SKCloudServiceController reports the following Non-StoreKit error: \(error.localizedDescription)"))
            }
            return
        }
        
        guard capabilities.contains(.musicCatalogPlayback) else {
            completion(err(no: -33015, message: "SKCloudServiceController reports no musicCatalogPlayback permission"))
            return
        }
        
        guard capabilities.contains(.addToCloudMusicLibrary) else {
            completion(err(no: -33016, message: "SKCloudServiceController reports no addToCloudMusicLibrary permission"))
            return
        }
        
        completion(nil)
    })
}

extension SKError {
    var userStuff: String {
        get {
            var ret = ""
            for (key, value) in self.userInfo {
                if let strValue = value as? String {
                    ret.append("\(key)=\(strValue); ")
                }
            }
            return ret
        }
    }
}

func err(no: Int, message: String) -> NSError {
    return NSError(domain: "Login", code: no, userInfo: [ NSLocalizedDescriptionKey: message])
}

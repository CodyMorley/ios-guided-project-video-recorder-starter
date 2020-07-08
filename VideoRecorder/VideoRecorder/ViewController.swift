//
//  ViewController.swift
//  VideoRecorder
//
//  Created by Paul Solt on 10/2/19.
//  Copyright © 2019 Lambda, Inc. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		requestPermissionAndShowCamera()
	}
    
    
	
    private func requestPermissionAndShowCamera() {
        // TODO: get permission
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            showCamera()
        case .denied:
            // take the user to the settings app or show a custom onboarding screen explaining reasons for needing permissions
            fatalError("Camera Permission Denied")
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                guard granted else {
                    fatalError("Camera permission denied.")
                }
                DispatchQueue.main.async {
                    self.showCamera()
                }
            }
        case .restricted:
            // Parental/Workplace Controls are usually responsible for this setting. Inform the user they do not have access and instruct them to speak with the device's administrator.
            fatalError("Camera Permission Restricted")
        @unknown default:
            fatalError("Unknown system state. Permission value not handled.")
        }
    }
    
	private func showCamera() {
		performSegue(withIdentifier: "ShowCamera", sender: self)
	}
}

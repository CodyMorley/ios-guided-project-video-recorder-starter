//
//  CameraViewController.swift
//  VideoRecorder
//
//  Created by Paul Solt on 10/2/19.
//  Copyright © 2019 Lambda, Inc. All rights reserved.
//

import UIKit
import AVFoundation

class CameraViewController: UIViewController {

    @IBOutlet var recordButton: UIButton!
    @IBOutlet var cameraView: CameraPreviewView!

    var captureSession = AVCaptureSession()
    var fileOutput = AVCaptureMovieFileOutput()
    private var player: AVPlayer?
    private var playerView: VideoPlayerView!

	override func viewDidLoad() {
		super.viewDidLoad()

		// Resize camera preview to fill the entire screen
		cameraView.videoPlayerView.videoGravity = .resizeAspectFill
        setUpCaptureSession()
	}
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        captureSession.startRunning()
    }


    @IBAction func recordButtonPressed(_ sender: Any) {
        toggleRecording()
	}
    
    
    func setUpCaptureSession() {
        //begin changing the session's capture settings
        captureSession.beginConfiguration()
        //Camera
        let camera = bestCamera()
        guard let cameraInput = try? AVCaptureDeviceInput(device: camera),
            captureSession.canAddInput(cameraInput) else {
            fatalError("Cannot create camera input. Crashing now.")
        }
        captureSession.addInput(cameraInput)
        //Mic
        let mic = bestAudio()
        guard let audioinput = try? AVCaptureDeviceInput(device: mic),
            captureSession.canAddInput(audioinput) else {
            fatalError("Cannot create audio input. Crashing hard.")
        }
        captureSession.addInput(audioinput)
        //Quality
        if captureSession.canSetSessionPreset(.hd1920x1080) {
            captureSession.sessionPreset = .hd1920x1080
        } else {
            fatalError("1080p not available on this device. Bye Bye.")
        }
        //Storage/Persistence Target
        guard captureSession.canAddOutput(fileOutput) else {
            fatalError("Cannot add movie recording output.")
        }
        captureSession.addOutput(fileOutput)
        
        
        //Set the settings above
        captureSession.commitConfiguration()
        
        //Give the camera view the session so it can show a camera preview to the user
        cameraView.session = captureSession
    }
    
    private func bestCamera() -> AVCaptureDevice {
        //Choose the ideal camera on the device the application is running on.
        //FUTURE: - Could let the user choose front or back camera -
        if let ultraWideCamera = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) {
            return ultraWideCamera
        } else if let wideAngleCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            return wideAngleCamera
        } else {
            fatalError("No camera available. Is this device a simulator?")
        }
    }
    
    private func bestAudio () -> AVCaptureDevice {
        if let audioDevice = AVCaptureDevice.default(for: .audio) {
            return audioDevice
        } else {
            fatalError("No audio device present.")
        }
    }
    
    private func toggleRecording() {
        if fileOutput.isRecording {
            fileOutput.stopRecording()
            updateViews()
        } else {
            fileOutput.startRecording(to: newRecordingURL(),
                                      recordingDelegate: self)
            updateViews()
        }
    }
    
    private func playMovie(at url: URL) {
        let player = AVPlayer(url: url)
        
        if playerView == nil {
            let playerView = VideoPlayerView()
            
            var frame = view.bounds
            
            frame.size.height /= 4
            frame.size.width /= 4
            
            frame.origin.y = view.directionalLayoutMargins.top
            
            playerView.frame = frame
            
            view.addSubview(playerView)
            self.playerView = playerView
        }
        
        playerView.player = player
        player.play()
        self.player = player
    }
    
    private func updateViews() {
        recordButton.isSelected = fileOutput.isRecording
    }
	
	/// Creates a new file URL in the documents directory
	private func newRecordingURL() -> URL {
		let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

		let formatter = ISO8601DateFormatter()
		formatter.formatOptions = [.withInternetDateTime]

		let name = formatter.string(from: Date())
		let fileURL = documentsDirectory.appendingPathComponent(name).appendingPathExtension("mov")
		return fileURL
	}
}

extension CameraViewController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("Started recording at \(fileURL)")
        updateViews()
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            NSLog("Error recording video to \(outputFileURL). Here's what happened: \(error) \(error.localizedDescription)")
        }
        updateViews()
        DispatchQueue.main.async {
            self.playMovie(at: outputFileURL)
        }
    }
    
    
}

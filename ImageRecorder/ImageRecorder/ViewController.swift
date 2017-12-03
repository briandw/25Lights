//
//  ViewController.swift
//  LightMapper
//
//  Created by Brian Williams on 10/24/17.
//  Copyright © 2017 Rantlab. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCapturePhotoCaptureDelegate, LightSocketDelegate
{
    var client: LightSocket?
    
    var captureSesssion : AVCaptureSession!
    var cameraOutput : AVCapturePhotoOutput!
    var previewLayer : AVCaptureVideoPreviewLayer!
    var documentURL : URL!
    var _photoName : String!
    
    @IBOutlet weak var previewView: UIView!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        captureSesssion = AVCaptureSession()
        captureSesssion.sessionPreset = AVCaptureSession.Preset.photo
        cameraOutput = AVCapturePhotoOutput()
        
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        documentURL = paths[0]
        documentURL = documentURL.appendingPathComponent("images", isDirectory: true)
        
        let defaultFM = FileManager.default
        try? defaultFM.createDirectory(at: documentURL,
                                       withIntermediateDirectories: true,
                                       attributes: nil)
        
        if let device = AVCaptureDevice.default(for: AVMediaType.video)
        {
            if let input = try? AVCaptureDeviceInput(device: device) {
                if (captureSesssion.canAddInput(input)) {
                    captureSesssion.addInput(input)
                    if (captureSesssion.canAddOutput(cameraOutput)) {
                        captureSesssion.addOutput(cameraOutput)
                        previewLayer = AVCaptureVideoPreviewLayer(session: captureSesssion)
                        previewLayer.frame = previewView.bounds
                        previewView.layer.addSublayer(previewLayer)
                        captureSesssion.startRunning()
                    }
                } else {
                    print("issue here : captureSesssion.canAddInput")
                }
            } else {
                print("some problem here")
            }
        }
    }
    
    // Take picture button
    @IBAction func didPressTakePhoto(_ sender: UIButton)
    {
        shootPhoto(photoName:"button")
    }
    
    func shootPhoto(photoName:String)
    {
        _photoName = photoName
        let settings = AVCapturePhotoSettings()
        let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
        let previewFormat = [
            kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
            kCVPixelBufferWidthKey as String: 128,
            kCVPixelBufferHeightKey as String: 128
        ]
        settings.previewPhotoFormat = previewFormat
        cameraOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?)
    {
        if let imageData = photo.fileDataRepresentation()
        {
            let dataProvider = CGDataProvider(data: imageData as CFData)
            let cgImageRef: CGImage! = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
            let image = UIImage(cgImage: cgImageRef, scale: 1.0, orientation: UIImageOrientation.right)
            
            let newSize = CGSize(width:128, height:128)
            let newRect = CGRect(x:0, y:0, width:128, height:128)
            UIGraphicsBeginImageContextWithOptions(newSize, true, 1.0);
            image.draw(in:newRect, blendMode: CGBlendMode.normal, alpha: 1.0)
            let newImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            if let img = newImage
            {                
                if let newData = UIImagePNGRepresentation(img)
                {
                    if let photo = _photoName
                    {
                        let filename = documentURL.appendingPathComponent("\(photo).png")
                        try? newData.write(to: filename)
                    }
                }
            }
        }
        photoNameRequest()
    }
    
    // This method you can use somewhere you need to know camera permission   state
    func askPermission() {
        print("here")
        let cameraPermissionStatus =  AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        
        switch cameraPermissionStatus {
        case .authorized:
            print("Already Authorized")
        case .denied:
            print("denied")
            
            let alert = UIAlertController(title: "Sorry :(" , message: "But  could you please grant permission for camera within device settings",  preferredStyle: .alert)
            let action = UIAlertAction(title: "Ok", style: .cancel,  handler: nil)
            alert.addAction(action)
            present(alert, animated: true, completion: nil)
            
        case .restricted:
            print("restricted")
        default:
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: {
                [weak self]
                (granted :Bool) -> Void in
                
                if granted == true {
                    // User granted
                    print("User granted")
                    DispatchQueue.main.async(){
                        //Do smth that you need in main thread
                    }
                }
                else {
                    // User Rejected
                    print("User Rejected")
                    
                    DispatchQueue.main.async(){
                        let alert = UIAlertController(title: "WHY?" , message:  "Camera it is the main feature of our application", preferredStyle: .alert)
                        let action = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
                        alert.addAction(action)
                        self?.present(alert, animated: true, completion: nil)
                    }
                }
            });
        }
    }
    
    @IBAction func startButtonAction()
    {
        if (client == nil)
        {
            client = LightSocket()
            client?.delegate = self
            client?.setupNetworkCommunication()
        }
        
        photoNameRequest()
    }
    
    func receivedMessage(message: String)
    {
        print(message)
        shootPhoto(photoName:message)
    }
    
    func photoNameRequest()
    {
        client?.request()
    }
}




//
//  ViewController.swift
//  HelloOpenCV
//
//  Created by Masaaki Uno on 2016/01/05.
//  Copyright © 2016年 Masaaki Uno. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var modeButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    
    
    // セッション
    var mySession : AVCaptureSession!
    // カメラデバイス
    var myDevice : AVCaptureDevice!
    // 出力先
    var myOutput : AVCaptureVideoDataOutput!
    // mode select
    var mode: Int = 0
    // save flag
    var saveFlag: Bool = false
    
    let akaze = Akaze();
    let orb = Orb();
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // カメラを準備
        if initCamera() {
            // 撮影開始
            mySession.startRunning()
        }
    }
    
    @IBAction func changeMode(sender: AnyObject) {
        if (self.mode == 0) {
            self.mode = 1
        } else {
            self.mode = 0
        }
    }
    
    @IBAction func savePhoto(sender: AnyObject) {
        self.saveFlag = true
    }

    // カメラの準備処理
    func initCamera() -> Bool {
        // セッションの作成.
        mySession = AVCaptureSession()
        
        // 解像度の指定.
        mySession.sessionPreset = AVCaptureSessionPresetMedium
        
        
        // デバイス一覧の取得.
        if let device = findCamera(AVCaptureDevicePosition.Back) {
            myDevice = device
        } else {
            print("カメラが見つかりませんでした")
            return false
        }
        
        do {
            // バックカメラからVideoInputを取得.
            let myInput: AVCaptureDeviceInput?
            try myInput = AVCaptureDeviceInput(device: myDevice)
            
            // セッションに追加.
            if mySession.canAddInput(myInput) {
                mySession.addInput(myInput)
            } else {
                return false
            }
            
            // 出力先を設定
            myOutput = AVCaptureVideoDataOutput()
            myOutput.videoSettings = [ kCVPixelBufferPixelFormatTypeKey: Int(kCVPixelFormatType_32BGRA) ]
            
            // FPSを設定
            try myDevice.lockForConfiguration()
            myDevice.activeVideoMinFrameDuration = CMTimeMake(1, 15)
            myDevice.unlockForConfiguration()
            
            // デリゲートを設定
            let queue: dispatch_queue_t = dispatch_queue_create("myqueue",  nil)
            myOutput.setSampleBufferDelegate(self, queue: queue)
            
            // 遅れてきたフレームは無視する
            myOutput.alwaysDiscardsLateVideoFrames = true
            
        } catch let error as NSError {
            print(error)
            return false
        }
        
        
        // セッションに追加.
        if mySession.canAddOutput(myOutput) {
            mySession.addOutput(myOutput)
        } else {
            return false
        }
        
        // カメラの向きを合わせる
        for connection in myOutput.connections {
            if let conn = connection as? AVCaptureConnection {
                if conn.supportsVideoOrientation {
                    conn.videoOrientation = AVCaptureVideoOrientation.Portrait
                }
            }
        }
        
        return true
    }
    
    // 指定位置のカメラを探します
    func findCamera(position: AVCaptureDevicePosition) -> AVCaptureDevice? {
        for device in AVCaptureDevice.devices() {
            if(device.position == position){
                return device as? AVCaptureDevice
            }
        }
        return nil
    }
    
    
    // 毎フレーム実行される処理
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!)
    {
        dispatch_sync(dispatch_get_main_queue(), {
            let image = CameraUtil.imageFromSampleBuffer(sampleBuffer)
            
            if (self.saveFlag) {
                self.saveFlag = false
                
            }
            
            if (self.mode == 0) {
                // Akaze
                let akazeImage = self.akaze.recognizePoints(image)
                // 表示
                self.imageView.image = akazeImage
                self.textLabel.text = "AKAZE: " + String(self.akaze.getPoints()) + "pts"
            } else {
                // Orb
                let orbImage = self.orb.recognizePoints(image)
                // 表示
                self.imageView.image = orbImage
                self.textLabel.text = "Orb: " + String(self.orb.getPoints()) + "pts"
            }
            

            
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
}
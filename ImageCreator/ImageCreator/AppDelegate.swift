//
//  AppDelegate.swift
//  25LightsDisplay
//
//  Created by Brian Williams on 10/24/17.
//  Copyright © 2017 Rantlab. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var ledView : LEDView!
    @IBOutlet weak var label : NSTextField!
    
    var encodedValue = UInt32(0)

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        self.ledView.drawData(bits:0xFFFFFFFF)
       tick()
        
        //runServer()
        /*
        encodedValue = arc4random()
        var intArray = [UInt8]()
        for i in 0..<4
        {
            let bitShift = UInt32((3-i)*8)
            let value = (encodedValue >> bitShift) & 0x000000FF
            //intArray.insert(UInt8(value), at: 0)
            intArray.append(UInt8(value))
        }
        
        self.ledView.drawData(bits:encodedValue)
        
        var decodedValue = UInt32(0)
        for i in 0..<4
        {
            decodedValue = decodedValue + UInt32(intArray[i])
            if (i < 3)
            {
                decodedValue = decodedValue << 8
            }
        }
        
        print(encodedValue)
        print(decodedValue)
        
        print(intArray)
 */
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func delay(_ delay:Double, closure:@escaping ()->())
    {
        let when = DispatchTime.now() + delay
        DispatchQueue.main.asyncAfter(deadline: when, execute: closure)
    }
    
    
    func tick()
    {
        self.ledView.drawData(bits:arc4random())

        delay(3)
        {
            self.tick()
        }
    }

    
    func echoService(client: TCPClient)
    {
        print("Newclient from:\(client.address)[\(client.port)]")
        while true
        {
            let d = client.read(3)
            
            if (d != nil)
            {
                encodedValue = arc4random()
                var intArray = [UInt8]()
                for i in 0..<4
                {
                    let bitShift = UInt32((3-i)*8)
                    let value = (encodedValue >> bitShift) & 0x000000FF
                    //intArray.insert(UInt8(value), at: 0)
                    intArray.append(UInt8(value))
                }
                
                let keyData = Data(intArray)
                DispatchQueue.main.sync
                {
                    self.ledView.drawData(bits:encodedValue)
                }
                
                delay(0.1)
                {
                    let result = client.send(data: keyData)
                    if (result.isSuccess)
                    {
                        print("send success");
                    }
                    else
                    {
                        print("fail to send");
                    }
                }
                
                //encodedValue = encodedValue + 1
            }
            else
            {
                client.close()
                print("Close Client");
                break;
            }
        }
    }
    
    func runServer()
    {
        DispatchQueue.global(qos: .background).async {
            let server = TCPServer(address: "10.0.0.241", port: 8888)
            switch server.listen()
            {
            case .success:
                while true
                {
                    if let client = server.accept()
                    {
                        self.echoService(client: client)
                    }
                    else
                    {
                        print("accept error")
                    }
                }
            case .failure(let error):
                print("fail to run \(error)")
            }
            
            print("Closed)")
        }
    }
}


/**
 * Copyright (c) 2017 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 * distribute, sublicense, create a derivative work, and/or sell copies of the
 * Software in any work that is designed, intended, or marketed for pedagogical or
 * instructional purposes related to programming, coding, application development,
 * or information technology.  Permission for such use, copying, modification,
 * merger, publication, distribution, sublicensing, creation of derivative works,
 * or sale is expressly withheld.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit

extension Data
{
    func hexEncodedString() -> String
    {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}

protocol LightSocketDelegate: class
{
  func receivedMessage(message: String)
}

class LightSocket: NSObject
{
  weak var delegate: LightSocketDelegate?
  
  var inputStream: InputStream!
  var outputStream: OutputStream!
  
  let maxReadLength = 8
  
  //1) Set up the input and output streams for message sending
  func setupNetworkCommunication()
  {
    var readStream: Unmanaged<CFReadStream>?
    var writeStream: Unmanaged<CFWriteStream>?
    
    CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault,
                                       "10.0.0.241" as CFString,
                                       8888,
                                       &readStream,
                                       &writeStream)
    
    inputStream = readStream!.takeRetainedValue()
    outputStream = writeStream!.takeRetainedValue()
    
    inputStream.delegate = self
    outputStream.delegate = self
    
    inputStream.schedule(in: .main, forMode: .commonModes)
    outputStream.schedule(in: .main, forMode: .commonModes)
    
    inputStream.open()
    outputStream.open()
  }
  
  func request()
  {
    let data = "req".data(using: .ascii)!
    _ = data.withUnsafeBytes { outputStream.write($0, maxLength: data.count) }
  }
  
  func stopChatSession()
  {
    inputStream.close()
    outputStream.close()
  }
}

extension LightSocket: StreamDelegate
{
  func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
    switch eventCode
    {
        case Stream.Event.hasBytesAvailable:
          print("new message received")
          readAvailableBytes(stream: aStream as! InputStream)
        case Stream.Event.endEncountered:
          stopChatSession()
        case Stream.Event.errorOccurred:
          print("error occurred")
        case Stream.Event.hasSpaceAvailable:
          print("has space available")
        default:
          print("some other event...")
          break
    }
}
  
  private func readAvailableBytes(stream: InputStream)
  {
    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: maxReadLength)
    
        while stream.hasBytesAvailable
        {
          let numberOfBytesRead = inputStream.read(buffer, maxLength: maxReadLength)
          
          if numberOfBytesRead < 0
          {
            if let _ = inputStream.streamError
            {
              break
            }
          }
            let data = Data(bytes:buffer, count:numberOfBytesRead)
            
            let res = data.hexEncodedString()
            delegate?.receivedMessage(message: res)
        }
    }
}

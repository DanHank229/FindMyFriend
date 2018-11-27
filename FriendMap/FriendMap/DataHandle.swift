//
//  DataHandle.swift
//  FriendMap
//
//  Created by 9S on 2018/11/6.
//  Copyright © 2018 9S. All rights reserved.
//

import Foundation
import MapKit
import CoreLocation

// 抓取資料用結構 外層
struct FriendAll: Codable {
    var result: Bool
    var friendsDownload: [FriendsDownload]?
    
    enum CodingKeys: String, CodingKey {
        case result = "result"
        case friendsDownload = "friends"
    }
}

// 資料細節結構 內層
struct FriendsDownload: Codable {
    var id: String
    var friendName: String
    var lat: String
    var lon: String
    var lastUpdateDateTime: String
}






extension ViewController {
    

    // 下載朋友資料
    func getFriendData() {
        communicator.getFriendMessages(text: GROUPNAME) { (result, error) in
            // Error
            if let error = error {
                print("Send Text Error: \(error)")
                return
            }
            // Value nil
            guard let result = result else {
                print ("result is nil")
                return
            }
            // 有取得資料
//            print("getFriendMessage OK.")
            
            // Decode as [MessageItem].
            guard let jsonData = try? JSONSerialization.data(withJSONObject: result, options: .prettyPrinted) else {
                print("Fail to generate jsonData.")
                return
            }
            
            let decoder = JSONDecoder()
            guard let resultObject = try? decoder.decode(FriendAll.self, from: jsonData) else {
                print("Fail to decode jsonData.")
                return
            }
            self.friends = resultObject.friendsDownload!
            // 取得朋友資訊 從JSON轉完後的結果
//            print("resultObject: \(resultObject)")
            guard let friendLocationMessages = resultObject.friendsDownload,
                !friendLocationMessages.isEmpty else {
                    print("messages is nil or empty.")
                    return
            }
            
            // save Date
            for f in friendLocationMessages {
                let f_Name = f.friendName
                if f_Name == MY_NAME {
                    let saveMyDate = LocationMassage.init(id: f.id,
                                                          userName: f.friendName,
                                                          lat: f.lat,
                                                          lon: f.lon,
                                                          lastUpdateDateTime: f.lastUpdateDateTime)
                    self.myLocationHistory.append(saveMyDate)
                    print("save mylocation \(saveMyDate)")
                    continue
                }
                
            }
        }
        
    }
  
    
    // updata 上傳資料
    func update(_ location: CLLocationCoordinate2D) {
        if myLocotionSwitch.isOn {
            print("update: ok >> \(location)")
            communicator.updata(lat: String(location.latitude),
                                lon: String(location.longitude)) { (result, error) in
                                    if let error = error {
                                        print("updata fail: \(error)")
                                        return
                                    } else if let result = result {
                                        print("updata OK: \(result)")
                                    }
            }
        }
    }
    
    
    // 更新朋友位置
    func reUpDate () {
        
        // 移除地圖釘
        self.mainMapView.removeAnnotations(self.mainMapView.annotations)
        
        for f in friends {
            let f_Name = f.friendName
            guard let f_lat = Double(f.lat),
                let f_lon = Double(f.lon) else {
                    continue
            }
            if f_Name == MY_NAME {
                continue
            }
            if friendPosition.isOn {
                var storeCoordinate = CLLocationCoordinate2D()
                storeCoordinate.latitude = f_lat
                storeCoordinate.longitude = f_lon
                
                // MK開頭 == MapKit相關 插圖釘
                let annotation = MKPointAnnotation()
                annotation.coordinate = storeCoordinate
                annotation.title = "\(f.friendName)"
                annotation.subtitle = "\(f.lat)\n\(f.lon)"
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0){
                    self.mainMapView.addAnnotation(annotation)
                }
            } else { continue }
        }
    }
    
    
    
}

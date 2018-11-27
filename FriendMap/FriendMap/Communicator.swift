//
//  Communicator.swift
//  HelloMyPushMessage
//
//  Created by Mrosstro on 2018/10/24.
//  Copyright © 2018 Mrosstro. All rights reserved.
//

import UIKit
import Alamofire

let GROUPNAME = "cp102"
let MY_NAME   = "Dan"

// JSON Keys
let ID_KEY              = "id"
let FRIENDS_KEY         = "friends"
let GROUPNAME_KEY       = "GroupName"
let USERNAME_KEY        = "UserName"
let FRIENDNAME_KEY      = "friednName"
let LAT_KEY             = "lat"
let LON_KEY             = "lon"
let LASTUPDATEDATETIME_KEY = "lastUpdateDateTime"
let RESULT_KEY          = "result"




//key:value 可能會拿到其他值 故Any+?
typealias DoneHandler = (_ result:[String:Any]?, _ error: Error?) -> Void
typealias DownloadDoneHandler = (_ result: Data?, _ error: Error?) -> Void

class Communicator {

    static let BASEURL = "http://class.softarts.cc/FindMyFriends/"
    // 上傳MyDate
    let UPDATEDEVICETOKEN_URL = BASEURL +
    "updateUserLocation.php?GroupName=cp102"
    // 取得FriendDate
    let QUERYFRIENDLOCATIONS = BASEURL +
    "queryFriendLocations.php?GroupName=cp102"
    
    static let shared = Communicator()
    
    private init() {
        
    }

    
    // MARK: - Public methods.
    // 上傳Mydata資料
    func updata(lat: String,lon: String, completion: @escaping DoneHandler) {
        
        let urlString = UPDATEDEVICETOKEN_URL + "&UserName=\(MY_NAME)&Lat=\(lat)&Lon=\(lon)"
        // doPost內容組成
        doPost(urlString: urlString,
               completion: completion)
    }
    

    // 拿朋友資料
    func getFriendMessages(text message: String,
                           completion: @escaping DoneHandler) {
        
        doPost(urlString: QUERYFRIENDLOCATIONS,
               completion: completion)
    }

    
    // doPost
    // prettyPrinted 產生出的內容可讀性較高,缺點 使用較多的流量
    private func doPost(urlString: String, completion: @escaping DoneHandler) {
        
        Alamofire.request(urlString, method: .post, encoding: URLEncoding.default).responseJSON { (response) in
            self.handleJSON(response: response, completion: completion)
        }
    }

    private func handleJSON(response: DataResponse<Any>, completion: DoneHandler) {
        switch response.result {
        case .success(let json):
            // 拿到JSON資料
//            print("Get success response: \(json)")
            
            
            // JSON解析失敗跳這邊
            guard let finalJson = json as? [String: Any] else {
                let error = NSError(domain: "Invalid JSON object.", code: -1, userInfo: nil)
                completion(nil, error)
                return
            }
            guard let result = finalJson[RESULT_KEY] as? Bool, result == true else {
                let error = NSError(domain: "Server respond false or not result.", code: -1, userInfo: nil)
                completion(nil, error)
                return
            }
            completion(finalJson, nil)

        case .failure(let error):
            print("Server respond error: \(error)")
            completion(nil, error)
        }
    }
}

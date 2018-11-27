//
//  MyLocationManager.swift
//  FriendMap
//
//  Created by 9S on 2018/11/13.
//  Copyright © 2018 9S. All rights reserved.
//

import Foundation
import SQLite

struct LocationMassage: Codable {
    var id: String
    var userName: String
    var lat: String
    var lon: String
    var lastUpdateDateTime: String

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case userName = "userName"
        case lat = "lat"
        case lon = "lon"
        case lastUpdateDateTime = "LastUpDateTime"
    }
}

class MyLocationManager {

    // 為了讓底下使用，要提前生成，不加上 static 無法使用
    static let tableName = "locationMessageLog"
    static let midKey = "mid"
    static let idKey = "id"
    static let usernameKey = "username"
    static let latKey = "lat"
    static let lonKey = "lon"
    static let lastupdatetimeKey = "lastupdatetime"
    
    // SQLite.swift support
    var db: Connection!
    var logTable = Table(tableName)
    var midColumn = Expression<Int64>(midKey)
    var idColumn = Expression<String>(idKey)
    var usernameColumn = Expression<String>(usernameKey)
    var latColumn = Expression<String>(latKey)
    var lonColumn = Expression<String>(lonKey)
    var lastupdatetimeColumn = Expression<String>(lastupdatetimeKey)

    
    var messageIDs = [Int64]()
    
    init() {
        // Prepare DB filename/path.
        let filemanager = FileManager.default
        guard let documentsURL = filemanager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let fullURLPath = documentsURL.appendingPathComponent("log.sqlite").path
        var isNewDB = false
        if !filemanager.fileExists(atPath: fullURLPath) {
            isNewDB = true
        }
        
        // Prepare connection of DB.
        do {
            db = try Connection(fullURLPath)
        } catch {
            assertionFailure("Fail to create connection.")
            return
        }
        
        // Create Table at the first time.
        if isNewDB {
            do {
                let command = logTable.create { (builder) in
                    builder.column(midColumn, primaryKey: true)
                    builder.column(idColumn)
                    builder.column(usernameColumn)
                    builder.column(latColumn)
                    builder.column(lonColumn)
                    builder.column(lastupdatetimeColumn)

                }
                try db.run(command)
                print("run")
            } catch {
                assertionFailure("Fail to create table: \(error).")
            }
        } else {
            // Keep mid into messageIDs.
            
            do {
                // SELECT * FROM "messageLog"
                for userName in try db.prepare(logTable) {
                    messageIDs.append(userName[midColumn])
                }
            } catch {
                assertionFailure("Fail to execute prepare command: \(error).")
            }
            print("There are total \(messageIDs.count) messages in DB")
        }
    }
    
    // 資料總比數
    var count: Int {
        return messageIDs.count
    }
    
    // 新增
    func append(_ userLocation: LocationMassage) {
        let command = logTable.insert(idColumn <- userLocation.id,
                                      usernameColumn <- userLocation.userName,
                                      latColumn <- userLocation.lat,
                                      lonColumn <- userLocation.lon,
                                      lastupdatetimeColumn <- userLocation.lastUpdateDateTime)
        do {
            let newMessageID = try db.run(command)
            messageIDs.append(newMessageID)
        } catch {
            assertionFailure("Fail to inser a new message: \(error).")
        }
    }
    
    // 讀取某一則訊息
    func getMessage(at: Int) -> LocationMassage? {
        guard at >= 0 && at < count else {
            assertionFailure("Invalid message index.")
            return nil
        }
        let targetMessageID = messageIDs[at]
        
        // SELECT * FROM "logMessage" WHERE mid == xxxx;
        let results = logTable.filter(midColumn == targetMessageID)
        // Pick the first one.
        do {
            guard let message = try db.pluck(results) else {
                assertionFailure("Fail to get the only one result.")
                return nil
            }
            return LocationMassage(id: message[idColumn],
                               userName: message[usernameColumn],
                               lat: message[latColumn],
                               lon: message[lonColumn],
                               lastUpdateDateTime: message[lastupdatetimeColumn])
        } catch {
            print("Pluck fail: \(error)")
        }
        
        return nil
    }
    
    
    // MARK: - Photo cache support.
    // 載入
    func load(image filename: String) -> UIImage? {
        let url = urlFor(filename)
        return UIImage(contentsOfFile: url.path)
    }
    
    // 存圖
    func save(image data: Data, filename: String) {
        let url = urlFor(filename)
        do {
            try data.write(to: url)
        } catch {
            assertionFailure("Fail to save image: \(error).")
        }
    }
    
    // 處理URL
    private func urlFor(_ filename: String) -> URL {
        let filemanager = FileManager.default
        let documentsURL = filemanager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsURL.appendingPathComponent(filename)
    }
}

//
//  ViewController.swift
//  FriendMap
//
//  Created by 9S on 2018/10/30.
//  Copyright © 2018 9S. All rights reserved.
//

import UIKit
import MapKit
import Alamofire
import CoreLocation


let v = [String]()

class ViewController: UIViewController {
    // 顯示地圖MKMapView
    @IBOutlet weak var mainMapView: MKMapView!
    @IBOutlet weak var SetView: UIView!
    
    
    @IBOutlet weak var friendPosition: UISwitch!
    @IBOutlet weak var myRoadHistory: UISwitch!
    @IBOutlet weak var myLocotionSwitch: UISwitch!
    
    
    var myCoordinate: CLLocationCoordinate2D?
    let locationManager = CLLocationManager()
    var myMapView :MKMapView!
    let communicator = Communicator.shared
    var setView = false   //setView狀態
    var downloadType = false
    var friends = [FriendsDownload]()
    let myLocationHistory = MyLocationManager()
    var endLocation: CLLocationCoordinate2D?
    
    
    var lat: Double = 0
    var lon: Double = 0
   
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // p delegate 架構必需要做的 從main sb map拉線進ViewController關聯
        // MKMapViewDelegate 設置代理
        mainMapView.delegate = self
        // 畫面中心追蹤使用者 帶方向性
        mainMapView.userTrackingMode = .followWithHeading
        // 位置服務啟用 show alert to user.
        guard CLLocationManager.locationServicesEnabled() else { return }
        //Ask permission.   請求授權(必要) 需在info設定三個user位置授權請求
        locationManager.requestAlwaysAuthorization()
        // Prepare locationManager 設置委任對象  CLLocationManagerDelegate
        locationManager.delegate = self // Important
        // 取得自身定位位置的精確度 分六等
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        // 移動模式 類型 步行
        locationManager.activityType = .fitness
        // 背景定位提醒
        locationManager.showsBackgroundLocationIndicator = true
        // 背景持續定位
        locationManager.allowsBackgroundLocationUpdates = false
        // 自動暫停位置更新 預設true, 不改false會在20min關閉更新
        locationManager.pausesLocationUpdatesAutomatically = false
        // 距離篩選 超過多少公尺呼叫 didUpdateLocations
        locationManager.distanceFilter = 10.0
        // 開始定位現在位置
        locationManager.startUpdatingLocation()
        // 拿朋友資料

        
    }
    
    // 朋友位置 Switch
    @IBAction func newFriendLocation(_ sender: Any) {
        if friendPosition.isOn {
            getFriendData()
            reUpDate()
        } else {
            // 移除friend圖標
            self.mainMapView.removeAnnotations(self.mainMapView.annotations)
        }
    }
    
    // 歷史軌跡Switch
    @IBAction func myLocationHistory(_ sender: Any) {
        if myRoadHistory.isOn{
            var myLocaOld: CLLocationCoordinate2D?
            var myLocaNew: CLLocationCoordinate2D?
            var myHistry: CLLocationCoordinate2D?
            
            for i in 0..<(myLocationHistory.count) {
                
                myLocaOld = myLocaNew
                
                guard let myDBLocation = myLocationHistory.getMessage(at: i) else {
                    continue
                }
                myHistry = CLLocationCoordinate2DMake(Double(myDBLocation.lat)!, Double(myDBLocation.lon)!)
                
                myLocaNew = myHistry
                
                guard let oldHistory = myLocaOld, let newHistory = myLocaNew else {
                    continue
                }
                let coords = [oldHistory, newHistory]
                let myPolyine = MKPolyline(coordinates: coords, count: coords.count)
                self.mainMapView.addOverlay(myPolyine)
                
            }
            
        } else {
            // 移除線
            self.mainMapView.removeOverlays(self.mainMapView.overlays)
        }
    }
    
    // 位置上傳Switch
    @IBAction func myLocationUp(_ sender: Any) {
        if myLocotionSwitch.isOn {
            drawPolyLine()
        } else {
            self.mainMapView.removeOverlays(self.mainMapView.overlays)
        }
        
    }

    // 手勢
    @IBAction func tapGestureSetView(_ sender: Any) {
        if SetView.isHidden == false {
        offOnSetView()
        }
    }
    
    // Set 設定頁面 On or Off
    @IBAction func setViewBtn(_ sender: Any) {
        offOnSetView()
    }
    
    // 開收set頁
    func offOnSetView () {
        if setView == true {
            SetView.isHidden = true
            setView = false
        } else {
            SetView.isHidden = false
            setView = true
        }
    }
    
    // 畫面準備完成 即將啟動
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        //Grand Central Dispatch GCD 延遲3秒後執行方法
        // Execute moveAndZoomMap() after 3.0 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.moveAndZoomMap()
        }
    }
    
    
    
    
    // 移動畫面 設定
    func moveAndZoomMap() {
        //拿到最後一次位置 可選型別 可能會是nil
        guard let location = locationManager.location else{
            print("Location is not ready.")
            return
        }
        //Move and zoom the map. zoom:放大
        // MKCoordinateSpan 地圖預設顯示的範圍大小 (數字越小越精確)
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        // MKCoordinateRegion 設置地圖顯示的範圍與中心點座標
        let region = MKCoordinateRegion(center: location.coordinate,span: span)
        mainMapView.setRegion(region, animated: true)
        
    }
    // 進入背景時呼叫
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // 停止定位自身位置
//        locationManager.stopUpdatingLocation()
    }
    
}



// MARK: - MKMapViewDelegate Methods.
extension ViewController: MKMapViewDelegate {
    
    //region(區域)改變就會被呼叫  若是ViewController
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let coordinate = mapView.region.center
        print("Map Center 畫面顯示中心緯經:  \(coordinate.latitude), \(coordinate.longitude)")
    }

    
    // 畫線方法必須實作的
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let polyLine = overlay as? MKPolyline else {
            return MKOverlayRenderer()
        }
        let renderer = MKPolylineRenderer(polyline: polyLine)
        renderer.lineWidth = 5.0    // lineWedth 線寬
        renderer.alpha = 0.4        // alpha 透明度
        renderer.strokeColor = #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)   // color
        
        return renderer
    }
    
    // 畫線方法
    func drawPolyLine() {
        
        guard let startLocation = endLocation else {
            endLocation = myCoordinate
            return
        }
        endLocation = myCoordinate
        let coords = [startLocation, endLocation!]
        let geodesicPolyline = MKPolyline(coordinates: coords, count: coords.count)
        mainMapView.addOverlay(geodesicPolyline)
        print("polyline: ok")
    }
}


// MARK: CLLocationMangerDelegate Methods
extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations : [CLLocation]) {
        
        // 取得座標
        guard let coordinate = locations.last?.coordinate else {
            assertionFailure("Invalid coordinate or location.")
            //assertionFailure debug執行到 程式碼會停止在這邊 debug模式限定
            return
        }
        
        myCoordinate = coordinate
        
        if myLocotionSwitch.isOn {
            drawPolyLine()
        } else {
            
        }
        
        update(coordinate)
        getFriendData()
        
        // 印出經緯度
        print("Current Location 所在位置範圍: \(coordinate.latitude), \(coordinate.longitude)")
        
    }
    
}


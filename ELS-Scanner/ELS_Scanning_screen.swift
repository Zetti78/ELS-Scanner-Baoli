//
//  ViewController.swift
//  ELS-Scanner
//
//  Created by Voltensee iMac on 07.02.20.
//  Copyright © 2020 Voltensee GmbH. All rights reserved.
//

import UIKit
import CoreBluetooth

class ELS_Scanning_Screen: UIViewController, UITableViewDelegate, UITableViewDataSource, CBCentralManagerDelegate {

    @IBOutlet weak var ELSListView: UITableView!
    @IBOutlet weak var btn_scanning: UIButton!
    
    private var centralManager : CBCentralManager!
    
    private var IsScanning : Bool!
    
    // UserData
    let defaults = UserDefaults.standard
    
    // ELS_List
    var ELS_List: [ELS_ItemCell] = []      // scanned List
    var ELS_SavedList: [ELS_Device] = []     // List with saved ELS_Devices
    var ELS_PreferenceList: [ELS_Device] = []   // Devicelist only with Devices with username to save it
    
    // Delete ScannedTimer
    var scanningOutOfRangeTimer :Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
 
        ELSListView.dataSource = self
        ELSListView.delegate = self
        
        SetupBluetooth()
        // Do any additional setup after loading the view.
        IsScanning = false
        

        LoadELSList()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear( animated)
        
        // stop scanning
        if self.IsScanning {
            self.StartStopScan()
        }
    }
    
    // save permant List to UserData
    func SaveELSList() {
        let encoder = JSONEncoder()
        
        // save DeviceList
        if let encodedList = try? encoder.encode(ELS_SavedList) {
            defaults.set(encodedList, forKey: "scannedList")
        }
        
        // save PreferenceList
        if let encodedList = try? encoder.encode(ELS_PreferenceList) {
            defaults.set(encodedList, forKey: "preferenceList")
        }

    }
    
    // load permant List from userData
    func LoadELSList() {
        let decoder = JSONDecoder()
        if let savedUserData = defaults.object(forKey: "scannedList") as? Data {
            ELS_SavedList = try! decoder.decode([ELS_Device].self, from: savedUserData)
        }
        
        // preference List
        if let savedPrefData = defaults.object(forKey: "preferenceList") as? Data {
            ELS_PreferenceList = try! decoder.decode([ELS_Device].self, from: savedPrefData)
        }
    }
    
    func SetupBluetooth() {
        centralManager = CBCentralManager(delegate: self, queue: nil, options: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ELS_List.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = ELSListView.dequeueReusableCell(withIdentifier: "ELS_ScanItem_Cell", for: indexPath) as! ELS_ItemCell
        
        cell.lb_Name?.text = ELS_List[indexPath.row].els_Device.ELS_UserName
        cell.lb_RSSI_Text?.text = String(ELS_List[indexPath.row].els_Device.ELS_RSSI ?? 0).appending(" dB")
        cell.lb_SecondName?.text = ELS_List[indexPath.row].els_Device.ELS_Name
        cell.lb_MacAdresse?.text = ELS_List[indexPath.row].els_Device.ELS_MAC
        cell.img_SignalStrength?.level = ELS_List[indexPath.row].ELS_SignalStrength.level
        cell.img_BatState?.image = ELS_List[indexPath.row].ELS_BatState.image
        cell.btn_ItemDetail.tag = indexPath.row
        cell.btn_ItemDetail.addTarget(self, action: #selector(onbtnDetailClick(_:)), for: .touchDown)
        return cell
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        /* test start scan
        if central.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        }
 */
    }

    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let data2: String? = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        if data2 != nil {
            if (data2?.hasPrefix("MEK-ELS") == true) {
                
                var advData: NSData!
                
                if(advertisementData[CBAdvertisementDataManufacturerDataKey] != nil) {
                    advData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? NSData
                }
                
                if advData == nil {
                    return
                }
                
                let newCell = ELS_ItemCell()
                
                newCell.els_Device = ELS_Device.init(ELS_Name: "", ELS_UserName: "", ELS_State: false, ELS_LastScanTime: currentTimeInMilliSeconds(), ELS_MAC: "", ELS_RSSI: 0, ELS_IsBlocked: false)
                
                newCell.els_Device.ELS_Name = data2!
                newCell.els_Device.ELS_RSSI = RSSI.intValue
                
                ManageScanData(item: newCell, data: advData)

                // check for duplicates
                var bFound = false;
                for cell in ELS_List {
                    if cell.els_Device.ELS_Name.contains(newCell.els_Device.ELS_Name) {
                        cell.els_Device.ELS_RSSI = newCell.els_Device.ELS_RSSI
                        cell.els_Device.ELS_LastScanTime = currentTimeInMilliSeconds()
                        
                        ManageScanData(item: cell, data: advData)
                        UpdateMailList(item: cell.els_Device)
                        bFound = true;
                    }
                }
                
                if !bFound {
                    ELS_List.append(newCell)
                    
                    // check preferenceList for Username
                    for i in 0..<ELS_PreferenceList.count {
                        if newCell.els_Device.ELS_Name.contains(ELS_PreferenceList[i].ELS_Name) {
                            newCell.els_Device.ELS_UserName = ELS_PreferenceList[i].ELS_UserName
                        }
                    }
                    UpdateMailList(item: newCell.els_Device)
                }
                
                ELS_List.sort(by: { $0.els_Device.ELS_RSSI ?? 0 > $1.els_Device.ELS_RSSI ?? 0})
                
                self.ELSListView.reloadData()
            }
        }
    }
    
    // prepare permant ELS_List. update or adding item-Data
    private func UpdateMailList(item: ELS_Device) {
        // first check, is the item in the list
        var bNewItem: Bool = true;
        for i in 0..<ELS_SavedList.count {
            if item.ELS_Name.contains(ELS_SavedList[i].ELS_Name) {
                ELS_SavedList[i].ELS_State = item.ELS_State
                ELS_SavedList[i].ELS_UserName = item.ELS_UserName
                ELS_SavedList[i].ELS_LastScanTime = item.ELS_LastScanTime
                bNewItem = false
                break
            }
        }

        if bNewItem {
            ELS_SavedList.append(item)
        }
        
        // PreferenceList update, delete or adding item Data
        bNewItem = true;

        for i in 0..<ELS_PreferenceList.count {
            // check, if exists
            if item.ELS_Name.contains(ELS_PreferenceList[i].ELS_Name) {
                // if the new username empy, delete it else update
                if !item.ELS_UserName.isEmpty {
                    // update username
                    ELS_PreferenceList[i].ELS_UserName = item.ELS_UserName
                    ELS_PreferenceList[i].ELS_LastScanTime = item.ELS_LastScanTime
                } else {
                    // delete item in PreferenceList
                    ELS_PreferenceList.remove(at: i)
                }
                bNewItem = false
                break
            }
        }

        if bNewItem {
            ELS_PreferenceList.append(item)
        }

        SaveELSList()
    }
    
    // prepare and convert scanned Data
    private func ManageScanData(item: ELS_ItemCell, data: NSData) {
        let rssi: Int = (item.els_Device.ELS_RSSI ?? 0 ) * -1     // make the value positive
        if rssi < 67 {
            item.ELS_SignalStrength.level = .excellent
        } else if rssi >= 67 && rssi < 70 {
            item.ELS_SignalStrength.level = .veryGood
        } else if rssi >= 70 && rssi < 75 {
            item.ELS_SignalStrength.level = .good
        } else if rssi >= 75 && rssi < 85 {
            item.ELS_SignalStrength.level = .low
        } else if rssi >= 85 {
            item.ELS_SignalStrength.level = .veryLow
        }
        
        // signal-strength
        item.ELS_SignalStrength.setNeedsDisplay()
        
        // fake MAC-Adress
        // ELS-Name: MEK-ELS xx:yy:zz <- extract the last 8 chars and adding to 00:80:25:
        var macadresse = "00:80:25:"
        
        if item.els_Device.ELS_Name.count > 8 {
            macadresse = macadresse.appending(item.els_Device.ELS_Name.suffix(8))
            item.els_Device.ELS_MAC = macadresse
        }
                
        // manage/set the image for batt-state
        var arr2 = Array<UInt8>(repeating: 0, count: data.count/MemoryLayout<UInt8>.stride)
        _ = arr2.withUnsafeMutableBytes { data.copyBytes(to: $0)
        }
        
        if arr2.count > 8 {
            if arr2[8] == 0x00 {
                item.els_Device.ELS_State = false
                item.ELS_BatState.image = UIImage(named: "ic_battlow")!
            } else {
                item.els_Device.ELS_State = true
                item.ELS_BatState.image = UIImage(named: "ic_battfull")!
            }
        }

    }
    
    // Buch Seite 823
    @IBAction func onbtnDetailClick(_ sender: UIButton) {
        var _: ELS_ItemCell = ELS_List[sender.tag]
        
        // stop scanning
        if self.IsScanning {
            self.StartStopScan()
        }
        
        // Alert-Controller
        let alertController = UIAlertController(title: "ELS-Name vergeben", message: "Hier können Sie einen individuellen Namen vergeben", preferredStyle: .alert)
        
        // Editfield ELS_Username
        alertController.addTextField {
            (textField) in textField.placeholder = "ELS-Name"
            textField.text = self.ELS_List[sender.tag].els_Device.ELS_UserName
        }

        // cancel_button
        let cancelAction = UIAlertAction(title: "Abbrechen", style: .cancel, handler: nil)
        
        // accept button
        let acceptAction = UIAlertAction(title: "Übernehmen", style: .default) {
            (alertAction) in
            let els_NameTextField = alertController.textFields![0]
            self.ELS_List[sender.tag].els_Device.ELS_UserName = els_NameTextField.text!
            self.ELSListView.reloadData()
            
            // Save Preference
            self.UpdateMailList(item: self.ELS_List[sender.tag].els_Device)
        }
        // add actions
        alertController.addAction(cancelAction)
        alertController.addAction(acceptAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    // TODO
    // regular Bluetooth Scan does not update a founded Device
    // must be replace to

    @IBAction func onStartStopScan(_ sender: UIButton) {
        self.StartStopScan()
    }
    
    // start or stop bluetooth scanning
    private func StartStopScan() {
        IsScanning = !IsScanning;
        
        if IsScanning {
            // clear old List
            ELS_List = []
            ELSListView.reloadData()
            
            centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey : true])
            scanningOutOfRangeTimer = Timer.scheduledTimer(timeInterval: 2.5, target: self, selector: #selector(fireOutOfRangeTimer), userInfo: nil, repeats: true)
            
            // rotate effekt for UIButton
            let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
            rotateAnimation.fromValue = 0.0
            rotateAnimation.toValue = CGFloat(Double.pi * 2)
            rotateAnimation.isRemovedOnCompletion = false;
            rotateAnimation.duration = 2
            rotateAnimation.repeatCount = Float.infinity
            self.btn_scanning.imageView?.layer.add(rotateAnimation, forKey: nil)
            
        } else {
            centralManager.stopScan()
            self.btn_scanning.imageView?.layer.removeAllAnimations()
            scanningOutOfRangeTimer?.invalidate()
            
        }
    }
    
    
    func finished(cell: ELS_ItemCell, state: Bool) {
        if state == true {
            self.ELSListView.reloadData()
        } else {
            
        }
    }
    
    // OutOfRange Timer is fired after 2.5s
    @objc func fireOutOfRangeTimer() {
        var deleteItemIDs: [Int] = []
        var i: Int = 0
        
        for cell in ELS_List {
            let currentTime: Int = currentTimeInMilliSeconds()
            var elapsedTime: Int = 0
            let lastscantime: Int = cell.els_Device.ELS_LastScanTime
            
            if currentTime > lastscantime {
                elapsedTime = currentTime - lastscantime
            } else {
                elapsedTime = lastscantime - currentTime
            }
            
            if (elapsedTime > 15000) && !cell.els_Device.ELS_IsBlocked {
                deleteItemIDs.append(i)
            }
            
            i += 1
        }
        
        // delete all elements there are longer as 15s not scanned
        if deleteItemIDs.count > 0 {
            for id in deleteItemIDs {
                if id < ELS_List.count {
                    ELS_List.remove(at: id)
                }
            }
            
            ELSListView.reloadData()
        }
    }
    
    // time in millis
    func currentTimeInMilliSeconds()-> Int
        {
            let currentDate = Date()
            let since1970 = currentDate.timeIntervalSince1970
            return Int(since1970 * 1000)
        }

}


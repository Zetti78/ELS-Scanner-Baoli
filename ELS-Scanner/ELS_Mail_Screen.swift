//
//  ELS_Mail_Screen.swift
//  ELS-Scanner
//
//  Created by Voltensee iMac on 04.11.20.
//  Copyright © 2020 Voltensee GmbH. All rights reserved.
//

import UIKit
import MessageUI

class ELS_Mail_Screen: UIViewController, UITableViewDelegate, UITableViewDataSource, MFMailComposeViewControllerDelegate {
    @IBOutlet weak var ELSMaillistView: UITableView!
    @IBOutlet weak var btn_sendToMail: UIButton!
    @IBOutlet weak var btn_deleteList: UIButton!
    
    var ELS_List: [ELS_ItemCell] = []     // List with saved ELS_Devices
    var ELS_SavedList: [ELS_Device] = []
    
    // UserData
    let defaults = UserDefaults.standard
    
    // initial View
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ELSMaillistView.delegate = self
        ELSMaillistView.dataSource = self
        
        //LoadMailList()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        LoadMailList()
    }
    
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ELS_List.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = ELSMaillistView.dequeueReusableCell(withIdentifier: "ELS_MailItem_Cell", for: indexPath) as! ELS_ItemCell
        
        cell.lb_Name?.text = ELS_List[indexPath.row].els_Device.ELS_UserName
        cell.lb_RSSI_Text?.text = String(ELS_List[indexPath.row].els_Device.ELS_RSSI ?? 0)
        cell.lb_SecondName?.text = ELS_List[indexPath.row].els_Device.ELS_Name
        cell.img_SignalStrength?.level = ELS_List[indexPath.row].ELS_SignalStrength.level
        cell.img_BatState?.image = ELS_List[indexPath.row].ELS_BatState.image
        cell.lb_MacAdresse?.text = ELS_List[indexPath.row].els_Device.ELS_MAC
        
        let date = Date(timeIntervalSince1970: TimeInterval(ELS_List[indexPath.row].els_Device.ELS_LastScanTime / 1000))
        let format = DateFormatter()
        format.timeZone = .current
        format.dateFormat = "dd.MM.yyyy - HH:mm:ss"
        cell.lb_LastScanTime?.text = format.string(from: date)
        return cell
    }
    
    func LoadMailList() {
        let decoder = JSONDecoder()
        if let savedUserData = defaults.object(forKey: "scannedList") as? Data {
            ELS_SavedList = try! decoder.decode([ELS_Device].self, from: savedUserData)
            
            // copy to ItemList
            ELS_List = []
            for item in ELS_SavedList {
                var ELS_DeviceItem: ELS_ItemCell = ELS_ItemCell()
                ELS_DeviceItem.els_Device = item
                
                if item.ELS_State {
                    ELS_DeviceItem.ELS_BatState.image = UIImage(named: "ic_battfull")!
                } else {
                    ELS_DeviceItem.ELS_BatState.image = UIImage(named: "ic_battlow")!
                }
                
                ELS_List.append(ELS_DeviceItem)
            }
            
            ELSMaillistView.reloadData()
        }
    }
    
    func createCSVFromList() -> String {
        let headerString: String = "\"ELS-Sensor\";\"Mac-Adresse\";\"ELS-Name\";\"Elektrolytstand\";\"Scanzeit\"\n"
        
        var dataString: String = ""
        
        // sort list before export
        //ELS_SavedList.sort(by: { $0.ELS_State ?? false > $1.ELS_State.ELS_RSSI ?? false})
        
        
        for item in ELS_SavedList {
            // convert ScanTime
            let date = Date(timeIntervalSince1970: TimeInterval(item.ELS_LastScanTime / 1000))
            let format = DateFormatter()
            format.timeZone = .current
            format.dateFormat = "dd.MM.yyyy - HH:mm:ss"
            
            // convert ELS-State
            var ELSStateText: String = ""
            if item.ELS_State {
                ELSStateText = "ok"
            } else {
                ELSStateText = "nicht ok"
            }
                        
            
            dataString = dataString.appending(String(format: "%@;%@;%@;%@;%@\n", item.ELS_Name, item.ELS_MAC, item.ELS_UserName, ELSStateText, format.string(from: date)))
        }

        return headerString.appending(dataString)
    }
    
    @IBAction func onbtn_SendEMail(_ sender: UIButton) {
        let csv = createCSVFromList()
        let data = csv.data(using: String.Encoding(rawValue: String.Encoding.utf8.rawValue), allowLossyConversion: false)
        
        if MFMailComposeViewController.canSendMail() {
            
            // Email-input
            // Alert-Controller
            let alertController = UIAlertController(title: "Liste versenden", message: "Geben sie eine EMail-Adresse an", preferredStyle: .alert)
            
            // Editfield ELS_Username
            alertController.addTextField {
                (textField) in textField.placeholder = "max@mustermann.de"
            }

            // cancel_button
            let cancelAction = UIAlertAction(title: "Abbrechen", style: .cancel, handler: nil)
            
            // accept button
            let acceptAction = UIAlertAction(title: "Senden", style: .default) {
                (alertAction) in
                
                let mail = MFMailComposeViewController()
                var recipient: Array<String> = []
                let currentDateTime = Date()
                let dateFormatter = DateFormatter()
                dateFormatter.timeZone = .current
                dateFormatter.dateFormat = "dd.MM.yyyy - HH:mm:ss"
                
                recipient.append(alertController.textFields?[0].text ?? "")
                mail.setToRecipients(recipient)
                mail.setSubject("ELS-Liste vom " + dateFormatter.string(from: currentDateTime))
                mail.setMessageBody("gesendet von MobileEasyKey MEKM-ELS-Scanner-App", isHTML: false)
                mail.mailComposeDelegate = self
                
                //add attachment
                mail.addAttachmentData(data!, mimeType: "text/csv", fileName: "ELS-Liste.csv")
                
                self.present(mail, animated: true)
            }
            // add actions
            alertController.addAction(cancelAction)
            alertController.addAction(acceptAction)
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onDelEMailList() {
        // Alert-Controller
        let alertController = UIAlertController(title: "Liste löschen", message: "Soll die Liste wirklich gelöscht werden?", preferredStyle: .alert)

        // cancel_button
        let cancelAction = UIAlertAction(title: "Abbrechen", style: .cancel, handler: nil)
        
        // accept button
        let acceptAction = UIAlertAction(title: "Löschen", style: .default) {
            (alertAction) in
            
            // clear list
            DispatchQueue.main.async {
                self.ELS_SavedList.removeAll(keepingCapacity: false)
                self.ELS_List .removeAll(keepingCapacity: false)
                let encoder = JSONEncoder()

                guard let encodedList = try? encoder.encode(self.ELS_SavedList) else {
                    print("cannot convert cleared ELS-List")
                    return;
                }
                
//            self.defaults.removeObject(forKey: "scannedList")
            
                self.defaults.set(encodedList, forKey: "scannedList")
                self.defaults.synchronize()
                self.ELSMaillistView.reloadData()
            }
            
            
            // save DeviceList
//            if let encodedList = try? encoder.encode(self.ELS_SavedList) {
//                self.defaults.set(encodedList, forKey: "scannedList")
//            }
            
            

        }
        // add actions
        alertController.addAction(cancelAction)
        alertController.addAction(acceptAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
}

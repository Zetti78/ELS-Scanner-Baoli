//
//  ELS_ItemCell.swift
//  ELS-Scanner
//
//  Created by Voltensee iMac on 04.03.20.
//  Copyright © 2020 Voltensee GmbH. All rights reserved.
//

import UIKit

class ELS_ItemCell: UITableViewCell {
   
    @IBOutlet weak var lb_Name: UILabel!
    @IBOutlet weak var lb_MacAdresse: UILabel!
    @IBOutlet weak var lb_SecondName: UILabel!
    @IBOutlet weak var lb_RSSI_Text: UILabel!
    @IBOutlet weak var btn_ItemDetail: UIButton!
    @IBOutlet weak var img_SignalStrength: SignalStrengthIndicator!
    @IBOutlet weak var img_BatState: UIImageView!
    @IBOutlet weak var lb_LastScanTime: UILabel!
    
    var els_Device: ELS_Device!
    var ELS_SignalStrength = SignalStrengthIndicator.init()
    var ELS_BatState = UIImageView.init()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    // Mask: Actions

    
}

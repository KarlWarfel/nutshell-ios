//
//  EventListTableViewCell.swift
//  Nutshell
//
//  Created by Larry Kenyon on 9/10/15.
//  Copyright © 2015 Tidepool. All rights reserved.
//

import UIKit

class EventListTableViewCell: BaseTableViewCell {

    var eventItem:NutEventItem?

    var eventGroup:NutEvent?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

/*
* Copyright (c) 2015, Tidepool Project
*
* This program is free software; you can redistribute it and/or modify it under
* the terms of the associated License, which is identical to the BSD 2-Clause
* License as published by the Open Source Initiative at opensource.org.
*
* This program is distributed in the hope that it will be useful, but WITHOUT
* ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
* FOR A PARTICULAR PURPOSE. See the License for more details.
*
* You should have received a copy of the License along with this program; if
* not, you can obtain one from Tidepool Project at tidepool.org.
*/

import UIKit

class EventListTableViewCell: BaseUITableViewCell {

    var eventGroup: NutEvent?

    @IBOutlet weak var titleLabel: NutshellUILabel!
    @IBOutlet weak var locationLabel: NutshellUILabel!
    @IBOutlet weak var repeatCountLabel: NutshellUILabel!
    @IBOutlet weak var nutCrackedStar: UIImageView!
    @IBOutlet weak var placeIconView: UIImageView!

    static var _highlightedPlaceIconImage: UIImage?
    class var highlightedPlaceIconImage: UIImage {
        if _highlightedPlaceIconImage == nil {
            _highlightedPlaceIconImage = UIImage(named: "placeSmallIcon")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
        }
        return _highlightedPlaceIconImage!
    }
 
    static var _defaultPlaceIconImage: UIImage?
    class var defaultPlaceIconImage: UIImage {
        if _defaultPlaceIconImage == nil {
            _defaultPlaceIconImage = UIImage(named: "placeSmallIcon")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        }
        return _defaultPlaceIconImage!
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    override func setHighlighted(highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated:animated)
        
        // Configure the view for the highlighted state
        titleLabel.highlighted = highlighted
        locationLabel?.highlighted = highlighted
        repeatCountLabel.highlighted = highlighted
        nutCrackedStar.highlighted = highlighted
        placeIconView?.highlighted = highlighted
    }

    func configureCell(nutEvent: NutEvent) {
        titleLabel.text = nutEvent.title
        repeatCountLabel.text = "x" + String(nutEvent.itemArray.count)
        eventGroup = nutEvent
        nutCrackedStar.hidden = true
        
        if !nutEvent.location.isEmpty {
            locationLabel.text = nutEvent.location
            placeIconView.hidden = false
            placeIconView.image = EventListTableViewCell.defaultPlaceIconImage
            placeIconView.highlightedImage = EventListTableViewCell.highlightedPlaceIconImage
            placeIconView.tintColor = Styles.altDarkGreyColor
        }
        
        titleLabel.textColor = UIColor.blackColor()
        NutUtils.setFormatterTimezone(nutEvent.itemArray[nutEvent.itemArray.count-1].tzOffsetSecs)
        var addOnText = ""
        var addOnTextExpire = ""
        var timeSinceNow=nutEvent.itemArray[nutEvent.itemArray.count-1].time.timeIntervalSinceNow
        var timeActive = 0.0
        var timeExpire = -365.0*24.0*60*60
        
        for item in nutEvent.itemArray {
            //KBW is there an activity tag?
            if item.notes.rangeOfString("#A(") != nil {
                var minInTextArr = item.notes.characters.split("(")
                var minInText = String(minInTextArr[1])
                var minInTextArr2 = minInText.characters.split(")")
                var minInTextNum = String(minInTextArr2[0])
                //[item.notes.rangeOfString("#A(")!]
                //let tempString = minInTextArr
                NSLog("**Active tag found in %@  with note \(item.notes) ",item.title)
                NSLog("  number string ")//\(String(minInTextNum))")
                ///addOnText="****Active****"
                
                //parse out time
                timeActive = -4.0 * 60.0 * 60.0
                
                    //minInTextNum = "10"
                
                timeActive = -60.0*Double(minInTextNum)!
                addOnText="****Active****"
                var addOnTextArr = item.notes.characters.split("\"")
                if (addOnTextArr.count > 1) {
                    addOnText = String(addOnTextArr[1])
                }
                else
                {
                    //addOnText = String("****Active****")
                }
                //and copy add on text
                //titleLabel.textColor = UIColor.redColor()
            }//End activity tag
            
            if item.notes.rangeOfString("#D(") != nil {
                var minInTextArr = item.notes.characters.split("(")
                var minInText = String(minInTextArr[1])
                var minInTextArr2 = minInText.characters.split(")")
                var minInTextNum = String(minInTextArr2[0])
                //[item.notes.rangeOfString("#A(")!]
                //let tempString = minInTextArr
                NSLog("***DUE tag found in %@  with note \(item.notes) ",item.title)
                NSLog("  number string ")//\(String(minInTextNum))")
                ///addOnText="****Active****"
                
                //parse out time
                timeExpire = -24.0 * 60.0 * 60.0
                timeExpire = -60.0*Double(minInTextNum)!
                addOnText="****Active****"
                var addOnTextArr = item.notes.characters.split("\"")
                if (addOnTextArr.count > 1) {
                    addOnTextExpire = "\n" + String(addOnTextArr[1])
                }
                else
                { 
                    //addOnText = String("****Active****")
                }
                //and copy add on text
                //titleLabel.textColor = UIColor.redColor()
            }//End Due tag
            
            
            if item.notes.lowercaseString.rangeOfString("#daily") != nil {
                timeExpire = -23.5*60.0*60
                addOnTextExpire = " "//"!! Due !! "
                
            }
            if item.notes.lowercaseString.rangeOfString("#weekly") != nil {
                timeExpire = -6.75*24.0*60.0*60
                addOnTextExpire = " "//"!! Due !! "
            }
            
            
            //KBW Find the most recent time
            if timeSinceNow < item.time.timeIntervalSinceNow {
                timeSinceNow = item.time.timeIntervalSinceNow
                NSLog("**** found better time****")
            }
        }// loop through nut array
        
        if (timeSinceNow>(-24*60*60)){
            repeatCountLabel.textColor = UIColor.blackColor() //"🌞" + repeatCountLabel.text!
        }
        else{
            if (timeSinceNow>(-7*24*60*60)){
                repeatCountLabel.textColor = UIColor.blueColor() //"wk " + repeatCountLabel.text!
            }
            else{
                if (timeSinceNow>(-30*24*60*60)){
                    repeatCountLabel.textColor = UIColor.darkGrayColor() //"mo " + repeatCountLabel.text!
                }
                else
                {
                    repeatCountLabel.textColor = UIColor.lightGrayColor()
                }
            }
            
        }
        
        
        //check active flag and time?
        NSLog("new cell refresh %@  time \(timeSinceNow) ",titleLabel.text!)
        if timeSinceNow > timeActive {  //more recent than
            //addOnText="****Active****"
            titleLabel.text = titleLabel.text! + "\n" + addOnText
            titleLabel.textColor = UIColor.blueColor()
            //titleLabel.textColor = UIColor.darkTextColor()
        }// Check active time
       
        
        //kbw check if expired
        if timeSinceNow < (timeExpire * 10.0) {  //way older then
            //addOnText="****Active****"
            titleLabel.text = titleLabel.text! + "\n" + "### Obsolete ###"
            titleLabel.textColor = UIColor.lightGrayColor()
        }// way older than
        else{
            if timeSinceNow < timeExpire {  //older than
                //addOnText="****Active****"
                titleLabel.text = titleLabel.text! + addOnTextExpire + "\n" + (NSString(format: "Due %3.1f days ago ",(timeSinceNow-timeExpire)/(24*60*60)) as String)
                titleLabel.textColor = UIColor.redColor()
            }// Check expire time
            else
            {  // shirk non expired cells
                if ((timeSinceNow-timeExpire)<(7.0*24*60*60)) {
                titleLabel.text = titleLabel.text! + "\n" + (NSString(format: "Due in %3.1f days ",(timeSinceNow-timeExpire)/(60*60*24)) as String)
                }
            }
        }
        
        if   titleLabel.text!.lowercaseString.rangeOfString("hour report") != nil {
            titleLabel.text = titleLabel.text! + NutUtils.fastingHoursText(NSDate()) + "\n" + NutUtils.iobText(NSDate()) + "\n" + NutUtils.bglText(NSDate())
        }
        
        if   titleLabel.text!.lowercaseString.rangeOfString("quick summary") != nil {
            titleLabel.text = titleLabel.text! + NutUtils.fastingHoursText(NSDate()) + "\n" + NutUtils.iobText(NSDate()) + "\n" + NutUtils.bglText(NSDate())
   /*             +
                (NSString(format: "\u{00B5} ToD BG:\t%3.1f/ %3.2f\n\u{03C3} ToD BG:\t%3.1f/ %3.2f\n...guidance here...",
                    NutUtils.averageSMBGTOD(NSDate().dateByAddingTimeInterval(+2.0*60.0*60.0), startDate: NSDate().dateByAddingTimeInterval(-7.0*24.0*60.0*60.0), endDate: NSDate().dateByAddingTimeInterval(1.0*24.0*60.0*60.0)),
                    NutUtils.averageSMBGTOD(NSDate().dateByAddingTimeInterval(+2.0*60.0*60.0), startDate: NSDate().dateByAddingTimeInterval(-30.0*24.0*60.0*60.0), endDate: NSDate().dateByAddingTimeInterval(1.0*24.0*60.0*60.0)),
                    NutUtils.standardDeviationSMBGTOD(NSDate().dateByAddingTimeInterval(+2.0*60.0*60.0), startDate: NSDate().dateByAddingTimeInterval(-7.0*24.0*60.0*60.0), endDate: NSDate().dateByAddingTimeInterval(1.0*24.0*60.0*60.0)),
                    NutUtils.standardDeviationSMBGTOD(NSDate().dateByAddingTimeInterval(+2.0*60.0*60.0), startDate: NSDate().dateByAddingTimeInterval(-30.0*24.0*60.0*60.0), endDate: NSDate().dateByAddingTimeInterval(1.0*24.0*60.0*60.0))
                    ) as String)as String
   */
            //add avgBGLTOD 30 day and std dev?
            //add fasting time
            //add IOB?
        }
        
        //kbw should this be rolled into other itemarray for loop?
        for item in nutEvent.itemArray {
            if item.nutCracked {
                nutCrackedStar.hidden = false
                break
            }
        }
    }
}

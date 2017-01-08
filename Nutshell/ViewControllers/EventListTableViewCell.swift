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
        var addOnTextRepeat = ""
        var timeSinceNow=nutEvent.itemArray[nutEvent.itemArray.count-1].time.timeIntervalSinceNow
        var timeActive = 0.0
        var timeExpire = -365.0*24.0*60*60
        var timeRepeat = -365.0*24.0*60*60
        var autoRepeat = false
        var duedate = false
        var due = false
        
        
        // replace this with and tag detect function
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
                //NSLog("  number string ")//\(String(minInTextNum))")
                ///addOnText="****Active****"
                
                //parse out time
                timeExpire = -24.0 * 60.0 * 60.0
                timeExpire = -60.0*Double(minInTextNum)!
                //addOnText="****Active****"
                var addOnTextArr = item.notes.characters.split("\"")
                if (addOnTextArr.count > 1) {
                    addOnTextExpire = "\n" + String(addOnTextArr[1])
                }
                else
                {
                    //addOnText = String("****Active****")
                }
                
                due = true
                //and copy add on text
                //titleLabel.textColor = UIColor.redColor()
                /// if there is no nutEvent with this title anf a tag - then creat one
                // ?? double scan?
                
                if nutEvent.itemArray[nutEvent.itemArray.count-1].notes.rangeOfString("#NextDate") != nil {
                    //set boolean that there is a due date item
                    duedate=true
                }
            }//End Due tag
            
            
            //check to see if #NextDate is the most recent - otherwise disregard
            if item.notes.rangeOfString("#NextDate") != nil {
                //set boolean that there is a due date item
                //duedate=true
            }
            
            
            if item.notes.rangeOfString("#R(") != nil {
                var minInTextArr = item.notes.characters.split("(")
                var minInText = String(minInTextArr[1])
                var minInTextArr2 = minInText.characters.split(")")
                var minInTextNum = String(minInTextArr2[0])
                autoRepeat = true
                //[item.notes.rangeOfString("#A(")!]
                //let tempString = minInTextArr
                NSLog("***Repeat tag found in %@  with note \(item.notes) ",item.title)
                NSLog("  number string ")//\(String(minInTextNum))")
                ///addOnText="****Active****"
                
                //parse out time
                //??timeExpire = -24.0 * 60.0 * 60.0
                timeRepeat = -60.0*Double(minInTextNum)!
                //addOnText="*Auto Add*"
                var addOnTextArr = item.notes.characters.split("\"")
                if (addOnTextArr.count > 1) {
                    addOnTextRepeat = String(addOnTextArr[1])
                }
                else
                {
                    //addOnText = String("****Active****")
                }
                //and copy add on text
                //titleLabel.textColor = UIColor.redColor()
            }//End repeat tag
            
            
            
            if item.notes.lowercaseString.rangeOfString("#daily") != nil {
                timeExpire = -23.5*60.0*60
                addOnTextExpire = " "//"!! Due !! "
                due = true
                
                if nutEvent.itemArray[nutEvent.itemArray.count-1].notes.rangeOfString("#NextDate") != nil {
                    //set boolean that there is a due date item
                    duedate=true
                }
                
            }
            if item.notes.lowercaseString.rangeOfString("#weekly") != nil {
                timeExpire = -6.75*24.0*60.0*60
                addOnTextExpire = " "//"!! Due !! "
                due = true
                
                if nutEvent.itemArray[nutEvent.itemArray.count-1].notes.rangeOfString("#NextDate") != nil {
                    //set boolean that there is a due date item
                    duedate=true
                }
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
        
        
        if (timeSinceNow > 0) {  // future
            //addOnText="****Active****"
            //titleLabel.text = titleLabel.text! //+ "\n" + addOnText
            //if addOnText.characters.count > 0 { titleLabel.text = titleLabel.text! + "\n" + addOnText }
            titleLabel.textColor = UIColor.brownColor()
            //titleLabel.textColor = UIColor.darkTextColor()
        }// Check active time
        
        
        //check active flag and time?
        NSLog("new cell refresh %@  time \(timeSinceNow) ",titleLabel.text!)
        if (timeSinceNow > timeActive) && (timeActive != 0) {  //more recent than
            //addOnText="****Active****"
            //titleLabel.text = titleLabel.text! //+ "\n" + addOnText
            if addOnText.characters.count > 0 { titleLabel.text = titleLabel.text! + "\n" + addOnText }
            titleLabel.textColor = UIColor.blueColor()
            //titleLabel.textColor = UIColor.darkTextColor()
        }// Check active time
        
        
        //kbw check if expired
        if timeSinceNow < (timeExpire * 10.0) {  //way older then
            //addOnText="****Active****"
            titleLabel.text = titleLabel.text! + "\n" + "### Obsolete ###"
            titleLabel.textColor = UIColor.lightGrayColor()
            
            // need to refactor this code to new tag fir reoccring events
            if titleLabel.text!.rangeOfString("💉TDD Novalog Fast Insulin Report") != nil {
                //add new
                //NutEvent.createMealEvent(nutEvent.title, notes: "test auto add obsolete", location: "", photo: "", photo2: "", photo3: "", time: nutEvent.itemArray[nutEvent.itemArray.count-1].time.dateByAddingTimeInterval(24.0*60.0*60.0), timeZoneOffset: (-5*60*60)/*NSCalendar.currentCalendar().timeZone.secondsFromGMT/60*/)
                NSLog("triggered TDD auto add obsolete ")
            }
        }// way older than
        else{
            if timeSinceNow < timeExpire {  //older than
                //addOnText="****Active****"
                titleLabel.text = titleLabel.text! + addOnTextExpire + "\n" + (NSString(format: "Due %@ ",NSDate().timeAgoInWords(NSDate().dateByAddingTimeInterval(timeSinceNow-timeExpire)),(timeSinceNow-timeExpire)/(24*60*60)) as String)
                titleLabel.textColor = UIColor.redColor()
                //auto renew
                if titleLabel.text!.rangeOfString("💉TDD Novalog Fast Insulin Report") != nil {
                    //add new
                    //NutEvent.createMealEvent(titleLabel.text!, notes: "test auto add", location: "", photo: "", photo2: "", photo3: "", time: NSDate(), timeZoneOffset: NSCalendar.currentCalendar().timeZone.secondsFromGMT/60)
                    NSLog("triggered TDD auto add")
                }
                
            }// Check expire time
            else
            {  // check non expired cells
                if ((timeSinceNow-timeExpire)<(90.0*24*60*60)) {
                    titleLabel.text = titleLabel.text! + "\n" + (NSString(format: "Due %@ ",NSDate().timeAgoInWords(nutEvent.itemArray[nutEvent.itemArray.count-1].time),(timeSinceNow-timeExpire)/(60*24.0)) as String)
                }
            }
        }
        
        //kbw check to see if auto repeat needed
        if (autoRepeat)&&(timeSinceNow<0) {
            //if titleLabel.text!.rangeOfString("💉TDD Novalog Fast Insulin Report") != nil {
            //add new
            NutEvent.createMealEvent(nutEvent.title, notes: "auto repeat ", location: "", photo: "", photo2: "", photo3: "", time: nutEvent.itemArray[nutEvent.itemArray.count-1].time.dateByAddingTimeInterval(timeRepeat * -1.0), timeZoneOffset: /*Int { NSTimeZone.localTimeZone.seconds secondsFromGMT()}*/(-5*60*60)/*NSCalendar.currentCalendar().timeZone.secondsFromGMT/60*/)
            NSLog("triggered TDD auto add r tag \(timeRepeat)")
            
            // }
        }
        
        //kbw check to see if future event needs to be created
        if (!duedate)&&(due)&&(timeExpire<(0)) {
            //add new
            // need to check if a meal or a workout and add the right one
            
            if nutEvent.itemArray[nutEvent.itemArray.count-1].notes.rangeOfString("#NextDate") != nil {
                //set boolean that there is a due date item
                duedate=true
                if nutEvent.itemArray[nutEvent.itemArray.count-1].time.timeIntervalSinceNow < 0 {
                    titleLabel.textColor = UIColor.redColor()
                }
                else{
                    titleLabel.textColor = UIColor.blackColor()
                }
            }
            else{
                NutEvent.createMealEvent(nutEvent.title, notes: "#NextDate", location: "", photo: "", photo2: "", photo3: "", time: nutEvent.itemArray[nutEvent.itemArray.count-1].time.dateByAddingTimeInterval(timeExpire * -1.0), timeZoneOffset: /*Int { NSTimeZone.localTimeZone.seconds secondsFromGMT()}*/(-5*60*60)/*NSCalendar.currentCalendar().timeZone.secondsFromGMT/60*/)
                NSLog("triggered new due event  \(timeRepeat)")
            }
            
            // }
        }
        
        if nutEvent.itemArray[nutEvent.itemArray.count-1].notes.rangeOfString("#NextDate") != nil {
            //set boolean that there is a due date item
            duedate=true
            if nutEvent.itemArray[nutEvent.itemArray.count-1].time.timeIntervalSinceNow < 0 {
                titleLabel.textColor = UIColor.redColor()
            }
            else{
                titleLabel.textColor = UIColor.blackColor()
            }
            
            if ((nutEvent.itemArray[nutEvent.itemArray.count-2].time.timeIntervalSinceDate(nutEvent.itemArray[nutEvent.itemArray.count-1].time)) - timeExpire) == 0 {
                //okay Next date
                
            }else{
                titleLabel.text = titleLabel.text! + " next date is off \(nutEvent.itemArray[nutEvent.itemArray.count-2].time.timeIntervalSinceDate(nutEvent.itemArray[nutEvent.itemArray.count-1].time))"
                //this creates a bad condition between the new next date and the old x date   
                
               // NutEvent.createMealEvent(nutEvent.title, notes: "#NextDate from early update", location: "", photo: "", photo2: "", photo3: "", time: nutEvent.itemArray[nutEvent.itemArray.count-2].time.dateByAddingTimeInterval(timeExpire * -1.0), timeZoneOffset: /*Int { NSTimeZone.localTimeZone.seconds secondsFromGMT()}*/(-5*60*60)/*NSCalendar.currentCalendar().timeZone.secondsFromGMT/60*/)
            }
        }
        
        
        
        
        
        //specials
        if   titleLabel.text!.lowercaseString.rangeOfString("hour report") != nil {
            titleLabel.text = titleLabel.text! + "\n" + NutUtils.fastingHoursText(NSDate()) + "\n" + NutUtils.iobText(NSDate()) + "\n" + NutUtils.bglText(NSDate())
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

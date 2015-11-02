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
import CoreData
import Photos

class NutUtils {

    class func dispatchBoolToVoidAfterSecs(secs: Float, result: Bool, boolToVoid: (Bool) -> (Void)) {
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(secs * Float(NSEC_PER_SEC)))
        dispatch_after(time, dispatch_get_main_queue()){
            boolToVoid(result)
        }
    }
    
    class func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
    
    class func loadImage(url: String, imageView: UIImageView) {
        if let image = UIImage(named: url) {
            imageView.image = image
            imageView.hidden = false
        } else {
            if let nsurl = NSURL(string:url) {
                let fetchResult = PHAsset.fetchAssetsWithALAssetURLs([nsurl], options: nil)
                if let asset = fetchResult.firstObject as? PHAsset {
                    var targetSize = imageView.frame.size
                    // bump up resolution...
                    targetSize.height *= 2.0
                    targetSize.width *= 2.0
                    let options = PHImageRequestOptions()
                    PHImageManager.defaultManager().requestImageForAsset(asset, targetSize: targetSize, contentMode: PHImageContentMode.AspectFit, options: options) {
                        (result, info) in
                        if let result = result {
                            imageView.hidden = false
                            imageView.image = result
                        }
                    }
                }
            }
        }
    }

    class func dateFromJSON(json: String?) -> NSDate? {
        if let json = json {
            return jsonDateFormatter.dateFromString(json)
        }
        return nil
    }
    
    class func decimalFromJSON(json: String?) -> NSDecimalNumber? {
        if let json = json {
            return NSDecimalNumber(string: json)
        }
        return nil
    }

    /** Date formatter for JSON date strings */
    class var jsonDateFormatter : NSDateFormatter {
        struct Static {
            static let instance: NSDateFormatter = {
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
                dateFormatter.timeZone = NSTimeZone(name: "GMT")
                return dateFormatter
                }()
        }
        return Static.instance
    }
    
    /** Date formatter for date strings in the UI */
    private class var dateFormatter : NSDateFormatter {
        struct Static {
            static let instance: NSDateFormatter = {
                let df = NSDateFormatter()
                df.dateFormat = Styles.uniformDateFormat
                return df
            }()
        }
        return Static.instance
    }
    
    // NOTE: this is not internationalized, and ignores user preferences for date display!
    class func standardUIDateString(date: NSDate, relative: Bool = false) -> String {
        let df = NutUtils.dateFormatter
        if (relative) {
            df.dateFormat = "MMM d, yyyy"
            var dayString = df.stringFromDate(date)
            // If this year, remove year.
            df.dateFormat = ", yyyy"
            let thisYearString = df.stringFromDate(NSDate())
            dayString = dayString.stringByReplacingOccurrencesOfString(thisYearString, withString: "")
            // Figure the hour/minute part...
            df.dateFormat = "h:mm a"
            var hourString = df.stringFromDate(date)
            // Replace uppercase PM and AM with lowercase versions
            hourString = hourString.stringByReplacingOccurrencesOfString("PM", withString: "pm", options: NSStringCompareOptions.LiteralSearch, range: nil)
            hourString = hourString.stringByReplacingOccurrencesOfString("AM", withString: "am", options: NSStringCompareOptions.LiteralSearch, range: nil)
            // Replace with today, yesterday if appropriate: only check if it's in the last 48 hours
            // TODO: look at using NSCalendar.startOfDayForDate and then time intervals to determine today, yesterday, Saturday, etc., back a week.
            if (date.timeIntervalSinceNow > -48 * 60 * 60) {
                if NSCalendar.currentCalendar().isDateInToday(date) {
                    dayString = "Today"
                } else if NSCalendar.currentCalendar().isDateInYesterday(date) {
                    dayString = "Yesterday"
                }
            }
            return dayString + " at " + hourString
        } else {
            df.dateFormat = Styles.uniformDateFormat
            return df.stringFromDate(date)
        }
    }

}
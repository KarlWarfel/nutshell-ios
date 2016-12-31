/*
* Copyright (c) 2016, Tidepool Project
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

import Foundation

extension NSDate {
    func differenceInDays(date: NSDate) -> Int {
        let calendar: NSCalendar = NSCalendar.currentCalendar()
        let components = calendar.components(.Day, fromDate: calendar.startOfDayForDate(self), toDate: calendar.startOfDayForDate(date), options: [])
        return components.day
    }
    
    func timeAgoInWords(date: NSDate) -> String {
        // TODO: Localize these strings
        
        let timeAgoInSeconds = round(abs(date.timeIntervalSinceDate(self)))
        var agoQ = ""
        
        if (date.timeIntervalSinceDate(self)) < 0 {
            agoQ = "ago"
        }
        else{
            agoQ = ""
        }
        
        switch timeAgoInSeconds {
        case 0...59:
            return "less than a minute " + agoQ
        default:
            break
        }
        
        let timeAgoInMinutes = round(timeAgoInSeconds / 60.0)
        switch timeAgoInMinutes {
        case 0...1:
            return "1 minute " + agoQ
        case 2...59:
            return "\(Int(timeAgoInMinutes))" + " minutes " + agoQ
        default:
            break
        }

        let timeAgoInHours = round(timeAgoInMinutes / 60.0)
        switch timeAgoInHours {
        case 0...1:
            return "1 hour " + agoQ
        case 2...23:
            return "\(Int(timeAgoInHours))" + " hours " + agoQ
        default:
            break
        }
        
        let timeAgoInDays = round(timeAgoInHours / 24.0)
        switch timeAgoInDays {
        case 0...1:
            return "1 day " + agoQ
        case 2...29:
            return "\(Int(timeAgoInDays))" + " days " + agoQ
        default:
            break
        }
        
        let timeAgoInMonths = round(timeAgoInDays / 30.0)
        switch timeAgoInMonths {
        case 0...1:
            return "1 month " + agoQ
        case 2...11:
            return "\(Int(timeAgoInMonths))" + " months " + agoQ
        default:
            break
        }
        
        let timeAgoInYears = round(timeAgoInMonths / 12.0)
        switch timeAgoInYears {
        case 0...1:
            return "1 year " + agoQ
        default:
            return "\(Int(timeAgoInYears))" + " years " + agoQ
        }
    }
}

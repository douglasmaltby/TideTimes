import Foundation

extension Date {
    func isSameDay(as date: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: date)
    }
    
    func isWithinLast48Hours(from date: Date = Date()) -> Bool {
        let timeInterval = date.timeIntervalSince(self)
        return timeInterval <= 48 * 60 * 60 && timeInterval >= 0
    }
} 
import SwiftUI
import Foundation

//
// Club
//

struct Category: Decodable, Identifiable, Hashable {
    let C_CategoryID: String
    let C_Category: String
    
    var id: String { C_CategoryID }
    
    static func == (lhs: Category, rhs: Category) -> Bool {
        return lhs.C_CategoryID == rhs.C_CategoryID
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(C_CategoryID)
    }
}

struct GroupInfoResponse: Decodable {
    let groups: [GroupInfo]
    let gmember: [Member]
}

struct GroupInfo: Decodable {
    let C_GroupsID: String
    let C_GroupNo: String
    let C_NameC: String
    let C_NameE: String
    let C_Category: String
    let C_CategoryID: String
    let C_FoundTime: String
    let C_DescriptionC: String
    let C_DescriptionE: String
}

struct Member: Decodable, Identifiable {
    let StudentID: String
    let S_Name: String
    let S_Nickname: String?
    let S_STel: String?
    let S_Email: String?
    let LeaderYes: String
    let C_Secede: String?
    
    var id: String { StudentID }
}

//
// Activity
//

struct GroupDropdownResponse: Decodable {
    let groups: [ClubGroup]
}

struct ClubGroup: Codable, Identifiable, Hashable {
    let C_GroupsID: String
    let C_GroupNo: String
    let C_NameC: String
    let C_NameE: String
    
    var id: String { C_GroupsID }
    
    static func == (lhs: ClubGroup, rhs: ClubGroup) -> Bool {
        return lhs.C_GroupsID == rhs.C_GroupsID
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(C_GroupsID)
    }
}

struct ActivityResponse: Decodable {
    let casRecord: [ActivityRecord]
}

struct ActivityRecord: Codable, Identifiable {
    var id: String { C_ARecordID } // Conform to Identifiable for List
    var C_ARecordID: String
    var C_Theme: String
    var C_Date: String
    var C_DurationC: String
    var C_DurationA: String
    var C_DurationS: String
    var C_Reflection: String
}

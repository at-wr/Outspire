import Foundation

struct GroupDropdownResponse: Decodable {
    let groups: [Group]
}

struct Group: Decodable, Identifiable, Hashable {
    let C_GroupsID: String
    let C_GroupNo: String
    let C_NameC: String
    let C_NameE: String
    
    var id: String { C_GroupsID }
    
    static func == (lhs: Group, rhs: Group) -> Bool {
        return lhs.C_GroupsID == rhs.C_GroupsID
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(C_GroupsID)
    }
}

struct ActivityResponse: Decodable {
    let casRecord: [ActivityRecord]
}

struct ActivityRecord: Decodable, Identifiable {
    var id: String { C_ARecordID } // Conform to Identifiable for List
    var C_ARecordID: String
    var C_Theme: String
    var C_Date: String
    var C_DurationC: String
    var C_DurationA: String
    var C_DurationS: String
    var C_Reflection: String
}

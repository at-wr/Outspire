import SwiftUI

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

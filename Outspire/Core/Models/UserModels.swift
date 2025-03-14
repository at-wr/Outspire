import SwiftUI

struct LoginResponse: Decodable {
    let status: String
}

struct UserInfo: Codable {
    let studentname: String
    let nickname: String
    let studentid: String
    let studentNo: String
    let tUsername: String
}

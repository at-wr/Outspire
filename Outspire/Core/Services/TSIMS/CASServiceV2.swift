import Foundation

struct V2Group: Decodable { let Id: Int; let Name: String }
struct V2GroupAlt: Decodable { let GroupNo: String; let NameC: String?; let NameE: String? }

// Flexible record decoding to accommodate alternate server field names
struct V2Record: Decodable, Identifiable {
    let Id: Int
    let GroupId: Int?
    let Title: String
    let Date: String

    // Individual durations as raw strings to preserve formatting
    let CDuration: String?
    let ADuration: String?
    let SDuration: String?
    let Reflection: String?

    // Convenience total hours if present
    let Hours: Double?

    // Confirmation status
    let IsConfirm: Int?
    let IsConfirmStr: String?

    enum CodingKeys: String, CodingKey {
        case Id, GroupId, Title, Hours, Date
        case Theme, ActivityDateStr, CDuration, ADuration, SDuration, Reflection
        case IsConfirm, IsConfirmStr
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        Id = (try? c.decode(Int.self, forKey: .Id)) ?? 0
        GroupId = try? c.decode(Int.self, forKey: .GroupId)
        if let t = try? c.decode(String.self, forKey: .Title) { Title = t }
        else { Title = (try? c.decode(String.self, forKey: .Theme)) ?? "" }
        if let d = try? c.decode(String.self, forKey: .Date) { Date = d }
        else { Date = (try? c.decode(String.self, forKey: .ActivityDateStr)) ?? "" }

        // Read raw durations as strings (supports string or number types)
        func decodeDuration(_ key: CodingKeys) -> String? {
            if let s = try? c.decodeIfPresent(String.self, forKey: key) { return s }
            if let d = try? c.decodeIfPresent(Double.self, forKey: key) {
                // Use one decimal place when needed
                if d.truncatingRemainder(dividingBy: 1) == 0 { return String(Int(d)) }
                return String(format: "%.1f", d)
            }
            if let i = try? c.decodeIfPresent(Int.self, forKey: key) { return String(i) }
            return nil
        }
        CDuration = decodeDuration(.CDuration)
        ADuration = decodeDuration(.ADuration)
        SDuration = decodeDuration(.SDuration)
        Reflection = try? c.decodeIfPresent(String.self, forKey: .Reflection)

        // Compute total hours if not provided
        if let h = try? c.decode(Double.self, forKey: .Hours) {
            Hours = h
        } else {
            let cH = CDuration.flatMap(Double.init) ?? 0
            let aH = ADuration.flatMap(Double.init) ?? 0
            let sH = SDuration.flatMap(Double.init) ?? 0
            let total = cH + aH + sH
            Hours = total > 0 ? total : nil
        }

        // Confirmation
        IsConfirm = try? c.decodeIfPresent(Int.self, forKey: .IsConfirm)
        IsConfirmStr = try? c.decodeIfPresent(String.self, forKey: .IsConfirmStr)
    }

    var id: Int { Id }
}

final class CASServiceV2 {
    static let shared = CASServiceV2()
    private init() {}

    // MARK: - Group list (paged, all groups)
    struct V2GroupListItem: Decodable {
        let Id: Int?
        let GroupNo: String?
        let NameC: String?
        let NameE: String?
        let YearName: String?
        let TeacherName: String?
        let DescriptionC: String?
        let DescriptionE: String?
    }

    private var groupDetailsCache: [String: V2GroupListItem] = [:]

    private func cacheGroupDetails(_ items: [V2GroupListItem]) {
        for it in items {
            if let id = it.Id { groupDetailsCache[String(id)] = it }
            if let no = it.GroupNo { groupDetailsCache[no] = it }
        }
    }

    func getCachedGroupDetails(idOrNo: String) -> V2GroupListItem? {
        return groupDetailsCache[idOrNo]
    }

    func fetchGroupList(pageIndex: Int = 1, pageSize: Int = 20, categoryId: String? = nil, completion: @escaping (Result<[ClubGroup], NetworkError>) -> Void) {
        var form: [String: String] = [
            "pageIndex": String(pageIndex),
            "pageSize": String(pageSize)
        ]
        if let c = categoryId { form["categoryId"] = c }

        TSIMSClientV2.shared.postFormRaw(path: "/Stu/Cas/GetGroupList", form: form) { result in
            switch result {
            case .failure(let err): completion(.failure(err))
            case .success(let data):
                let dec = JSONDecoder()
                if let env = try? dec.decode(ApiResponse<Paged<V2GroupListItem>>.self, from: data), env.isSuccess, let paged = env.data {
                    self.cacheGroupDetails(paged.list)
                    let mapped = paged.list.map { item -> ClubGroup in
                        let id = item.Id.map(String.init) ?? (item.GroupNo ?? "")
                        let nameC = item.NameC ?? item.NameE ?? ("Group " + id)
                        let nameE = item.NameE ?? item.NameC ?? ("Group " + id)
                        return ClubGroup(C_GroupsID: id, C_GroupNo: item.GroupNo ?? id, C_NameC: nameC, C_NameE: nameE)
                    }
                    completion(.success(mapped)); return
                }
                if Configuration.debugNetworkLogging, let preview = String(data: data, encoding: .utf8)?.prefix(300) {
                    print("[CASV2] GetGroupList unexpected preview=\(preview)")
                }
                completion(.failure(.decodingError(NSError(domain: "CAS", code: -10, userInfo: [NSLocalizedDescriptionKey: "Unexpected group list format"])) ))
            }
        }
    }

    func fetchMyGroups(categoryId: String? = nil, completion: @escaping (Result<[ClubGroup], NetworkError>) -> Void) {
        var form: [String: String] = [:]
        if let c = categoryId { form["categoryId"] = c }
        TSIMSClientV2.shared.postFormRaw(path: "/Stu/Cas/GetMyGroupList", form: form) { result in
            switch result {
            case .failure(let err): completion(.failure(err))
            case .success(let data):
                if let env = try? JSONDecoder().decode(ApiResponse<[V2Group]>.self, from: data), env.isSuccess, let arr = env.data {
                    let mapped = arr.map { ClubGroup(C_GroupsID: String($0.Id), C_GroupNo: "", C_NameC: $0.Name, C_NameE: $0.Name) }
                    completion(.success(mapped)); return
                }
                if let env2 = try? JSONDecoder().decode(ApiResponse<[V2GroupAlt]>.self, from: data), env2.isSuccess, let arr2 = env2.data {
                    let mapped = arr2.map { ClubGroup(C_GroupsID: $0.GroupNo, C_GroupNo: $0.GroupNo, C_NameC: $0.NameC ?? ($0.NameE ?? ""), C_NameE: $0.NameE ?? ($0.NameC ?? "")) }
                    completion(.success(mapped)); return
                }
                if Configuration.debugNetworkLogging, let preview = String(data: data, encoding: .utf8)?.prefix(200) {
                    print("[CASV2] groups unexpected preview=\(preview)")
                }
                completion(.failure(.decodingError(NSError(domain: "CAS", code: -4, userInfo: [NSLocalizedDescriptionKey: "Unexpected group format"])) ))
            }
        }
    }

    func fetchRecords(groupId: String, pageIndex: Int = 1, pageSize: Int = 50, completion: @escaping (Result<[ActivityRecord], NetworkError>) -> Void) {
        let form: [String: String] = ["pageIndex": String(pageIndex), "pageSize": String(pageSize), "groupId": groupId]
        TSIMSClientV2.shared.postFormRaw(path: "/Stu/Cas/GetRecordList", form: form) { result in
            switch result {
            case .failure(let err): completion(.failure(err))
            case .success(let data):
                if let env = try? JSONDecoder().decode(ApiResponse<Paged<V2Record>>.self, from: data), env.isSuccess, let paged = env.data {
                    let mapped = paged.list.map { rec in
                        ActivityRecord(
                            C_ARecordID: String(rec.Id),
                            C_Theme: rec.Title,
                            C_Date: rec.Date,
                            C_DurationC: (rec.CDuration?.isEmpty == false) ? rec.CDuration! : "0",
                            C_DurationA: (rec.ADuration?.isEmpty == false) ? rec.ADuration! : "0",
                            C_DurationS: (rec.SDuration?.isEmpty == false) ? rec.SDuration! : "0",
                            C_Reflection: rec.Reflection ?? "",
                            C_IsConfirm: rec.IsConfirm,
                            C_IsConfirmStr: rec.IsConfirmStr
                        )
                    }
                    if Configuration.debugNetworkLogging { print("[CASV2] records count=\(mapped.count)") }
                    completion(.success(mapped))
                } else {
                    if Configuration.debugNetworkLogging, let preview = String(data: data, encoding: .utf8)?.prefix(200) {
                        print("[CASV2] records unexpected preview=\(preview)")
                    }
                    completion(.failure(.decodingError(NSError(domain: "CAS", code: -2, userInfo: [NSLocalizedDescriptionKey: "Unexpected record format"])) ))
                }
            }
        }
    }

    // MARK: - Reflections (V2)
    struct V2Reflection: Decodable, Identifiable {
        let Id: Int
        let Title: String?
        let Summary: String?
        let Content: String?
        let CreateTime: String?
        var id: Int { Id }
    }

    func fetchReflections(groupId: String, pageIndex: Int = 1, pageSize: Int = 50, completion: @escaping (Result<[Reflection], NetworkError>) -> Void) {
        let form: [String: String] = ["pageIndex": String(pageIndex), "pageSize": String(pageSize), "groupId": groupId]
        TSIMSClientV2.shared.postFormRaw(path: "/Stu/Cas/GetReflectionList", form: form) { result in
            switch result {
            case .failure(let err): completion(.failure(err))
            case .success(let data):
                if let env = try? JSONDecoder().decode(ApiResponse<Paged<V2Reflection>>.self, from: data), env.isSuccess, let paged = env.data {
                    let mapped = paged.list.map { it in
                        Reflection(
                            C_RefID: String(it.Id),
                            C_Title: it.Title ?? "",
                            C_Summary: it.Summary ?? "",
                            C_Content: it.Content ?? "",
                            C_Date: it.CreateTime ?? "",
                            C_GroupNo: "",
                            c_lo1: nil, c_lo2: nil, c_lo3: nil, c_lo4: nil, c_lo5: nil, c_lo6: nil, c_lo7: nil, c_lo8: nil
                        )
                    }
                    completion(.success(mapped))
                } else {
                    completion(.failure(.decodingError(NSError(domain: "CAS", code: -3, userInfo: [NSLocalizedDescriptionKey: "Unexpected reflection format"])) ))
                }
            }
        }
    }

    func deleteReflection(id: String, completion: @escaping (Result<Bool, NetworkError>) -> Void) {
        TSIMSClientV2.shared.postForm(path: "/Stu/Cas/DeleteReflection", form: ["id": id]) { (result: Result<ApiResponse<String>, NetworkError>) in
            switch result {
            case .success(let env): completion(.success(env.isSuccess))
            case .failure(let err): completion(.failure(err))
            }
        }
    }

    func deleteRecord(id: String, completion: @escaping (Result<Bool, NetworkError>) -> Void) {
        TSIMSClientV2.shared.postForm(path: "/Stu/Cas/DeleteRecord", form: ["id": id]) { (result: Result<ApiResponse<String>, NetworkError>) in
            switch result {
            case .success(let env):
                if Configuration.debugNetworkLogging { print("[CASV2] deleteRecord isSuccess=\(env.isSuccess) msg=\(env.message ?? "")") }
                completion(.success(env.isSuccess))
            case .failure(let err):
                if Configuration.debugNetworkLogging { print("[CASV2] deleteRecord error=\(err.localizedDescription)") }
                completion(.failure(err))
            }
        }
    }

    // MARK: - Group leader status
    func isGroupLeader(groupId: String, completion: @escaping (Result<Bool, NetworkError>) -> Void) {
        TSIMSClientV2.shared.postForm(path: "/Stu/Cas/GetGroupLeader", form: ["groupId": groupId]) { (result: Result<ApiResponse<Bool>, NetworkError>) in
            switch result {
            case .success(let env): completion(.success(env.data ?? false))
            case .failure(let err): completion(.failure(err))
            }
        }
    }

    // MARK: - Join / Exit group
    func joinGroup(groupId: String, isProject: Bool = false, completion: @escaping (Result<Bool, NetworkError>) -> Void) {
        let form = ["groupid": groupId, "IsProject": isProject ? "true" : "false"]
        TSIMSClientV2.shared.postForm(path: "/Stu/Cas/JoinGroup", form: form) { (result: Result<ApiResponse<String>, NetworkError>) in
            switch result {
            case .success(let env): completion(.success(env.isSuccess))
            case .failure(let err): completion(.failure(err))
            }
        }
    }

    func exitGroup(groupId: String, completion: @escaping (Result<Bool, NetworkError>) -> Void) {
        TSIMSClientV2.shared.postForm(path: "/Stu/Cas/ExitGroup", form: ["id": groupId]) { (result: Result<ApiResponse<String>, NetworkError>) in
            switch result {
            case .success(let env): completion(.success(env.isSuccess))
            case .failure(let err): completion(.failure(err))
            }
        }
    }

    // MARK: - Evaluate data (summary)
    struct V2EvaluateData: Decodable {
        struct GroupRecord: Decodable {
            let GroupNo: String?
            let NameC: String?
            let NameE: String?
            let TeacherName: String?
            let Id: Int?
        }
        let GroupRecordList: [GroupRecord]?
        let RecLevel: Int?
        let RefLevel: Int?
        let Talk: Int?
        let Final: Int?
    }

    func fetchEvaluateData(yearId: String, completion: @escaping (Result<V2EvaluateData, NetworkError>) -> Void) {
        TSIMSClientV2.shared.postForm(path: "/Stu/Cas/GetEvaluateData", form: ["yearId": yearId]) { (result: Result<ApiResponse<V2EvaluateData>, NetworkError>) in
            switch result {
            case .success(let env):
                if env.isSuccess, let data = env.data { completion(.success(data)) }
                else { completion(.failure(.requestFailed(NSError(domain: "CAS", code: -5, userInfo: [NSLocalizedDescriptionKey: env.message ?? "Failed"])) )) }
            case .failure(let err): completion(.failure(err))
            }
        }
    }
}

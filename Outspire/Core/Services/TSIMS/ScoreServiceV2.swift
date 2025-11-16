import Foundation

struct V2ScoreItem: Decodable, Identifiable {
    let id = UUID().uuidString
    let subject: String
    let score: String
    let grade: String?

    enum CodingKeys: String, CodingKey {
        case subject = "Subject"
        case score = "Score"
        case grade = "Grade"
    }
}

final class ScoreServiceV2 {
    static let shared = ScoreServiceV2()
    private init() {}

    func fetchScores(yearId: String, completion: @escaping (Result<[V2ScoreItem], NetworkError>) -> Void) {
        TSIMSClientV2.shared.postForm(path: "/Stu/Exam/GetScoreData", form: ["yearId": yearId]) { (result: Result<ApiResponse<[V2ScoreItem]>, NetworkError>) in
            switch result {
            case .success(let env):
                if Configuration.debugNetworkLogging { print("[ScoreV2] isSuccess=\(env.isSuccess) count=\(env.data?.count ?? 0) msg=\(env.message ?? "")") }
                if env.isSuccess {
                    completion(.success(env.data ?? []))
                } else {
                    completion(.failure(.requestFailed(NSError(domain: "Score", code: -1, userInfo: [NSLocalizedDescriptionKey: env.message ?? "Failed"])) ))
                }
            case .failure(let err):
                if Configuration.debugNetworkLogging { print("[ScoreV2] error=\(err.localizedDescription)") }
                completion(.failure(err))
            }
        }
    }
}

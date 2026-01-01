import Foundation

struct V2ScoreItem: Decodable, Identifiable {
    let id = UUID().uuidString

    let subject: String
    let score1: String
    let ibScore1: String
    let score2: String
    let ibScore2: String
    let score3: String
    let ibScore3: String
    let score4: String
    let ibScore4: String
    let score5: String
    let ibScore5: String

    private enum CodingKeys: String, CodingKey {
        case subject = "SubjectName"
        case score1 = "Score1"
        case ibScore1 = "IbScore1"
        case score2 = "Score2"
        case ibScore2 = "IbScore2"
        case score3 = "Score3"
        case ibScore3 = "IbScore3"
        case score4 = "Score4"
        case ibScore4 = "IbScore4"
        case score5 = "Score5"
        case ibScore5 = "IbScore5"
    }

    init(
        subject: String,
        score1: String,
        ibScore1: String,
        score2: String,
        ibScore2: String,
        score3: String,
        ibScore3: String,
        score4: String,
        ibScore4: String,
        score5: String,
        ibScore5: String
    ) {
        self.subject = subject
        self.score1 = score1
        self.ibScore1 = ibScore1
        self.score2 = score2
        self.ibScore2 = ibScore2
        self.score3 = score3
        self.ibScore3 = ibScore3
        self.score4 = score4
        self.ibScore4 = ibScore4
        self.score5 = score5
        self.ibScore5 = ibScore5
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        subject = (try? c.decode(String.self, forKey: .subject)) ?? ""

        // TSIMS uses "-" and sometimes trailing spaces for missing/graded fields.
        // Decode defensively so missing keys don't break the entire response.
        score1 = Self.normalizedScore((try? c.decode(String.self, forKey: .score1)) ?? "0")
        ibScore1 = Self.normalizedGrade((try? c.decode(String.self, forKey: .ibScore1)) ?? "")
        score2 = Self.normalizedScore((try? c.decode(String.self, forKey: .score2)) ?? "0")
        ibScore2 = Self.normalizedGrade((try? c.decode(String.self, forKey: .ibScore2)) ?? "")
        score3 = Self.normalizedScore((try? c.decode(String.self, forKey: .score3)) ?? "0")
        ibScore3 = Self.normalizedGrade((try? c.decode(String.self, forKey: .ibScore3)) ?? "")
        score4 = Self.normalizedScore((try? c.decode(String.self, forKey: .score4)) ?? "0")
        ibScore4 = Self.normalizedGrade((try? c.decode(String.self, forKey: .ibScore4)) ?? "")
        score5 = Self.normalizedScore((try? c.decode(String.self, forKey: .score5)) ?? "0")
        ibScore5 = Self.normalizedGrade((try? c.decode(String.self, forKey: .ibScore5)) ?? "")
    }

    static func normalizedScore(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed == "-" ? "0" : trimmed
    }

    static func normalizedGrade(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

final class ScoreServiceV2 {
    static let shared = ScoreServiceV2()
    private init() {}

    func fetchScores(yearId: String, completion: @escaping (Result<[V2ScoreItem], NetworkError>) -> Void) {
        TSIMSClientV2.shared.postForm(path: "/Stu/Exam/GetScoreData", form: ["yearId": yearId]) { (result: Result<
            ApiResponse<[V2ScoreItem]>,
            NetworkError
        >) in
            switch result {
            case let .success(env):
                if Configuration
                    .debugNetworkLogging
                {
                    print("[ScoreV2] isSuccess=\(env.isSuccess) count=\(env.data?.count ?? 0) msg=\(env.message ?? "")")
                }
                if env.isSuccess {
                    completion(.success(env.data ?? []))
                } else {
                    completion(.failure(.requestFailed(NSError(
                        domain: "Score",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: env.message ?? "Failed"]
                    ))))
                }
            case let .failure(err):
                if Configuration.debugNetworkLogging { print("[ScoreV2] error=\(err.localizedDescription)") }
                completion(.failure(err))
            }
        }
    }
}

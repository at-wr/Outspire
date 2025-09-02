import Foundation

struct V2MenuItem: Decodable, Identifiable {
    let id = UUID()
    let title: String?
    let href: String?
    let icon: String?
    let children: [V2MenuItem]?
}

final class HomeServiceV2 {
    static let shared = HomeServiceV2()
    private init() {}

    func fetchMenu(completion: @escaping (Result<[V2MenuItem], NetworkError>) -> Void) {
        TSIMSClientV2.shared.getJSON(path: "/Home/GetMenu") { (result: Result<ApiResponse<[V2MenuItem]>, NetworkError>) in
            switch result {
            case .success(let env):
                if env.isSuccess { completion(.success(env.data ?? [])) }
                else { completion(.failure(.requestFailed(NSError(domain: "Home", code: -1, userInfo: [NSLocalizedDescriptionKey: env.message ?? "Failed"])) )) }
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }
}


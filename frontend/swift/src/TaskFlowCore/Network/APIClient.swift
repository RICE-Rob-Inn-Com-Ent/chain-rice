import Foundation
import Alamofire
import SwiftyJSON

// MARK: - API Configuration
struct APIConfiguration {
    static let baseURL = "https://api.taskflowpro.com/v1"
    static let timeout: TimeInterval = 30
}

// MARK: - API Error Types
enum APIError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case networkError(Error)
    case serverError(Int, String)
    case unauthorized
    case forbidden
    case notFound
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Nieprawidłowy URL"
        case .noData:
            return "Brak danych"
        case .decodingError(let error):
            return "Błąd dekodowania: \(error.localizedDescription)"
        case .networkError(let error):
            return "Błąd sieci: \(error.localizedDescription)"
        case .serverError(let code, let message):
            return "Błąd serwera (\(code)): \(message)"
        case .unauthorized:
            return "Brak autoryzacji"
        case .forbidden:
            return "Brak uprawnień"
        case .notFound:
            return "Nie znaleziono"
        }
    }
}

// MARK: - API Response Wrapper
struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let message: String?
    let errors: [String]?
}

// MARK: - API Client
class APIClient {
    static let shared = APIClient()
    
    private let session: Session
    private var authToken: String?
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = APIConfiguration.timeout
        configuration.timeoutIntervalForResource = APIConfiguration.timeout
        
        self.session = Session(configuration: configuration)
    }
    
    // MARK: - Authentication
    func setAuthToken(_ token: String) {
        self.authToken = token
    }
    
    func clearAuthToken() {
        self.authToken = nil
    }
    
    // MARK: - Request Headers
    private func headers() -> HTTPHeaders {
        var headers = HTTPHeaders()
        headers["Content-Type"] = "application/json"
        headers["Accept"] = "application/json"
        
        if let token = authToken {
            headers["Authorization"] = "Bearer \(token)"
        }
        
        return headers
    }
    
    // MARK: - Generic Request Method
    func request<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = JSONEncoding.default,
        responseType: T.Type
    ) async throws -> T {
        let url = APIConfiguration.baseURL + endpoint
        
        return try await withCheckedThrowingContinuation { continuation in
            session.request(
                url,
                method: method,
                parameters: parameters,
                encoding: encoding,
                headers: headers()
            )
            .validate()
            .responseData { response in
                switch response.result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601
                        let result = try decoder.decode(T.self, from: data)
                        continuation.resume(returning: result)
                    } catch {
                        continuation.resume(throwing: APIError.decodingError(error))
                    }
                case .failure(let error):
                    if let statusCode = response.response?.statusCode {
                        let apiError = self.handleHTTPError(statusCode: statusCode, data: response.data)
                        continuation.resume(throwing: apiError)
                    } else {
                        continuation.resume(throwing: APIError.networkError(error))
                    }
                }
            }
        }
    }
    
    // MARK: - Error Handling
    private func handleHTTPError(statusCode: Int, data: Data?) -> APIError {
        switch statusCode {
        case 401:
            return .unauthorized
        case 403:
            return .forbidden
        case 404:
            return .notFound
        case 400...499:
            let message = extractErrorMessage(from: data) ?? "Błąd klienta"
            return .serverError(statusCode, message)
        case 500...599:
            let message = extractErrorMessage(from: data) ?? "Błąd serwera"
            return .serverError(statusCode, message)
        default:
            return .serverError(statusCode, "Nieznany błąd")
        }
    }
    
    private func extractErrorMessage(from data: Data?) -> String? {
        guard let data = data else { return nil }
        do {
            let json = try JSON(data: data)
            return json["message"].string ?? json["error"].string
        } catch {
            return nil
        }
    }
}

// MARK: - API Endpoints
extension APIClient {
    // MARK: - Authentication Endpoints
    func login(email: String, password: String) async throws -> User {
        let parameters: Parameters = [
            "email": email,
            "password": password
        ]
        
        let response: APIResponse<User> = try await request(
            endpoint: "/auth/login",
            method: .post,
            parameters: parameters,
            responseType: APIResponse<User>.self
        )
        
        guard let user = response.data else {
            throw APIError.noData
        }
        
        return user
    }
    
    func register(name: String, email: String, password: String) async throws -> User {
        let parameters: Parameters = [
            "name": name,
            "email": email,
            "password": password
        ]
        
        let response: APIResponse<User> = try await request(
            endpoint: "/auth/register",
            method: .post,
            parameters: parameters,
            responseType: APIResponse<User>.self
        )
        
        guard let user = response.data else {
            throw APIError.noData
        }
        
        return user
    }
    
    // MARK: - Projects Endpoints
    func getProjects() async throws -> [Project] {
        let response: APIResponse<[Project]> = try await request(
            endpoint: "/projects",
            method: .get,
            responseType: APIResponse<[Project]>.self
        )
        
        return response.data ?? []
    }
    
    func createProject(_ project: Project) async throws -> Project {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(project)
        let parameters = try JSONSerialization.jsonObject(with: data) as? Parameters ?? [:]
        
        let response: APIResponse<Project> = try await request(
            endpoint: "/projects",
            method: .post,
            parameters: parameters,
            responseType: APIResponse<Project>.self
        )
        
        guard let createdProject = response.data else {
            throw APIError.noData
        }
        
        return createdProject
    }
    
    func updateProject(_ project: Project) async throws -> Project {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(project)
        let parameters = try JSONSerialization.jsonObject(with: data) as? Parameters ?? [:]
        
        let response: APIResponse<Project> = try await request(
            endpoint: "/projects/\(project.id)",
            method: .put,
            parameters: parameters,
            responseType: APIResponse<Project>.self
        )
        
        guard let updatedProject = response.data else {
            throw APIError.noData
        }
        
        return updatedProject
    }
    
    func deleteProject(id: String) async throws {
        let _: APIResponse<EmptyResponse> = try await request(
            endpoint: "/projects/\(id)",
            method: .delete,
            responseType: APIResponse<EmptyResponse>.self
        )
    }
    
    // MARK: - Tasks Endpoints
    func getTasks(projectId: String? = nil) async throws -> [Task] {
        var endpoint = "/tasks"
        if let projectId = projectId {
            endpoint += "?project_id=\(projectId)"
        }
        
        let response: APIResponse<[Task]> = try await request(
            endpoint: endpoint,
            method: .get,
            responseType: APIResponse<[Task]>.self
        )
        
        return response.data ?? []
    }
    
    func createTask(_ task: Task) async throws -> Task {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(task)
        let parameters = try JSONSerialization.jsonObject(with: data) as? Parameters ?? [:]
        
        let response: APIResponse<Task> = try await request(
            endpoint: "/tasks",
            method: .post,
            parameters: parameters,
            responseType: APIResponse<Task>.self
        )
        
        guard let createdTask = response.data else {
            throw APIError.noData
        }
        
        return createdTask
    }
    
    func updateTask(_ task: Task) async throws -> Task {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(task)
        let parameters = try JSONSerialization.jsonObject(with: data) as? Parameters ?? [:]
        
        let response: APIResponse<Task> = try await request(
            endpoint: "/tasks/\(task.id)",
            method: .put,
            parameters: parameters,
            responseType: APIResponse<Task>.self
        )
        
        guard let updatedTask = response.data else {
            throw APIError.noData
        }
        
        return updatedTask
    }
    
    func deleteTask(id: String) async throws {
        let _: APIResponse<EmptyResponse> = try await request(
            endpoint: "/tasks/\(id)",
            method: .delete,
            responseType: APIResponse<EmptyResponse>.self
        )
    }
}

// MARK: - Empty Response for Delete Operations
struct EmptyResponse: Codable {}

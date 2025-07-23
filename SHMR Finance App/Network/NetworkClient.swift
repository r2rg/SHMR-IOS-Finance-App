//
//  NetworkClient.swift
//  SHMR Finance App
//
//  Created by Артур Галустян on 17.07.2025.
//

import Foundation

private let apiDateFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
}()

private let apiDateFormatterNoFraction: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter
}()

enum NetworkError: Error, LocalizedError {
    case httpError(statusCode: Int, data: Data?)
    case decodingError(Error)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .httpError(let code, let data):
            if let data = data, let message = String(data: data, encoding: .utf8) {
                return "HTTP error: \(code)\n\(message)"
            } else {
                return "HTTP error: \(code)"
            }
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

struct NetworkClient {
    // Тут нужно вставить свой токен для работы
    private var bearerToken = "Bearer <TOKEN>"
    private var baseUrl = "https://shmr-finance.ru/api/v1/"
    private let timeout: TimeInterval = 20.0
    
    private var encoder: JSONEncoder = {
        let anEncoder = JSONEncoder()
        anEncoder.dateEncodingStrategy = .custom { date, encoder in
            let dateStr = apiDateFormatter.string(from: date)
            var container = encoder.singleValueContainer()
            try container.encode(dateStr)
        }
        return anEncoder
    }()
    
    private var decoder: JSONDecoder = {
        let aDecoder = JSONDecoder()
        aDecoder.dateDecodingStrategy = .custom({ decoder in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)
            if let date = apiDateFormatter.date(from: dateStr) {
                return date
            }
            if let date = apiDateFormatterNoFraction.date(from: dateStr) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Date decoding error")
        })
        return aDecoder
    }()
    
    func request<Request: Encodable, Response: Decodable>(
        method: String,
        url: String,
        body: Request?
    ) async throws -> Response {
        let requestUrl = baseUrl + url
        var request = URLRequest(url: URL(string: requestUrl)!, timeoutInterval: timeout)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(bearerToken, forHTTPHeaderField: "Authorization")

        request.httpMethod = method
        if let body = body {
            let parameters = try encoder.encode(body)
            request.httpBody = parameters
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown(NSError(domain: "No HTTPURLResponse", code: 0))
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode, data: data)
        }
        do {
            let result = try decoder.decode(Response.self, from: data)
            return result
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
    
    func request<Response: Decodable>(
        method: String,
        url: String
    ) async throws -> Response {
        let requestUrl = baseUrl + url
        var request = URLRequest(url: URL(string: requestUrl)!, timeoutInterval: timeout)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(bearerToken, forHTTPHeaderField: "Authorization")

        request.httpMethod = method
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown(NSError(domain: "No HTTPURLResponse", code: 0))
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode, data: data)
        }
        do {
            let result = try decoder.decode(Response.self, from: data)
            return result
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
    
    func request<Request: Encodable>(
        method: String,
        url: String,
        body: Request?
    ) async throws {
        let requestUrl = baseUrl + url
        var request = URLRequest(url: URL(string: requestUrl)!, timeoutInterval: timeout)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(bearerToken, forHTTPHeaderField: "Authorization")

        request.httpMethod = method
        if let body = body {
            let parameters = try encoder.encode(body)
            request.httpBody = parameters
            print(String(data: parameters, encoding: .utf8) as Any)
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown(NSError(domain: "No HTTPURLResponse", code: 0))
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode, data: data)
        }
    }
    
    func request(
        method: String,
        url: String,
    ) async throws {
        let requestUrl = baseUrl + url
        var request = URLRequest(url: URL(string: requestUrl)!, timeoutInterval: timeout)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(bearerToken, forHTTPHeaderField: "Authorization")

        request.httpMethod = method
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown(NSError(domain: "No HTTPURLResponse", code: 0))
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode, data: data)
        }
    }
}

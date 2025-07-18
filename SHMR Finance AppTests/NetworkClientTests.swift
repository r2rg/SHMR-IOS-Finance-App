//
//  NetworkClientTests.swift
//  SHMR Finance AppTests
//
//  Created by Артур Галустян on 17.07.2025.
//

import Testing
@testable import SHMR_Finance_App
import Foundation

struct NetworkClientTests {

    @Test("Получить аккаунт") func getAccount() async throws {
        let client = NetworkClient()
        
        let _: [BankAccount] = try await client.request(method: "GET", url: "accounts")
    }

}

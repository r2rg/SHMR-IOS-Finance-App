//
//  AccountBriefDTO.swift
//  SHMR Finance App
//
//  Created by Артур Галустян on 17.07.2025.
//

struct AccountBriefDTO: Identifiable, Codable {
    let id: Int
    let name: String
    let balance: String
    let currency: String
}

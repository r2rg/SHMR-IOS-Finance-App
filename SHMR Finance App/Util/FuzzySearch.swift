//
//  FuzzySearch.swift
//  SHMR Finance App
//
//  Created by Артур Галустян on 05.07.2025.
//

import Foundation

struct FuzzySearch {
    
    /// Вычисляет схожесть строк по алгоритму Левенштейна (регистр не учитывается)
    static func calculateSimilarityScore(between source: String, and target: String) -> Double {
        // Приводим строки к нижнему регистру, чтобы он не имел значения
        let normalizedSource = source.lowercased()
        let normalizedTarget = target.lowercased()
        
        let sourceLength = normalizedSource.count
        let targetLength = normalizedTarget.count
        
        if sourceLength == 0 && targetLength == 0 {
            return 1.0 
        }
        if sourceLength == 0 || targetLength == 0 {
            return 0.0
        }
        if normalizedSource == normalizedTarget {
            return 1.0 
        }
        
        let distance = calculateLevenshteinDistance(between: normalizedSource, and: normalizedTarget)
        
        let maxLength = max(sourceLength, targetLength)
        let similarity = 1.0 - (Double(distance) / Double(maxLength))
        
        return max(0.0, similarity)
    }
    
    /// Считаем расстояние Левенштейна
    private static func calculateLevenshteinDistance(between source: String, and target: String) -> Int {
        let sourceArray = Array(source)
        let targetArray = Array(target)
        let sourceLength = sourceArray.count
        let targetLength = targetArray.count
        
        var matrix = Array(repeating: Array(repeating: 0, count: targetLength + 1), count: sourceLength + 1)
        
        for i in 0...sourceLength {
            matrix[i][0] = i
        }
        for j in 0...targetLength {
            matrix[0][j] = j
        }
        
        for i in 1...sourceLength {
            for j in 1...targetLength {
                let cost = sourceArray[i - 1] == targetArray[j - 1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i - 1][j] + 1,     
                    matrix[i][j - 1] + 1,     
                    matrix[i - 1][j - 1] + cost 
                )
            }
        }
        
        return matrix[sourceLength][targetLength]
    }
    
    /// Проверяем, похожи ли две строки на основе порога
    static func areSimilar(
        _ string1: String,
        _ string2: String,
        threshold: Double = 0.6
    ) -> Bool {
        return calculateSimilarityScore(between: string1, and: string2) >= threshold
    }
}

// Расширение String для удобства
extension String {

    func similarityScore(with other: String) -> Double {
        return FuzzySearch.calculateSimilarityScore(between: self, and: other)
    }
    
    func isSimilar(to other: String, threshold: Double = 0.6) -> Bool {
        return FuzzySearch.areSimilar(self, other, threshold: threshold)
    }
}

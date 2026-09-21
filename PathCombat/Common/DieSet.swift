//
//  DieSet.swift
//  PathCombat
//
//  Created by Federico Brandani on 20/09/2026.
//

struct DieSet {
    var numberOfDies: Int
    var diesType: DieType
    
    func toString() -> String {
        "\(numberOfDies)d(\(diesType.rawValue)"
    }
    
    init(numberOfDies: Int, diesType: DieType) {
        self.numberOfDies = numberOfDies
        self.diesType = diesType
    }
    
    init(fromString: String) {
        let stringElements = fromString.split(separator: "d")
        let number = Int(stringElements.first ?? "1")
        let dieType = DieType(rawValue: Int(stringElements.last ?? "2") ?? 2)!
        self.numberOfDies = number ?? 1
        self.diesType = dieType
    }
    
    func roll() -> Int {
        var total = 0
        (0..<numberOfDies).forEach { _ in
            total +=  Int.random(in: 1...self.diesType.rawValue)
        }
        return total
    }
}

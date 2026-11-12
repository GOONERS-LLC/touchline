//
//  NamePools.swift
//  Touchline
//
//  Nationality-appropriate names for generated players (filler squads, youth
//  intakes and regens), so a generated Spanish second-division side is not
//  full of "James Smith"s.
//

import Foundation

public struct NamePool {
    public let nationality: String
    public let firstNames: [String]
    public let lastNames: [String]

    public func randomName() -> (first: String, last: String) {
        (firstNames.randomElement() ?? "Alex", lastNames.randomElement() ?? "Silva")
    }
}

public enum NamePools {

    public static let england = NamePool(nationality: "England",
        firstNames: ["James", "Jack", "Harry", "Oliver", "George", "Charlie", "Alfie", "Freddie", "Archie", "Theo",
                     "Tom", "Callum", "Josh", "Ben", "Lewis", "Ryan", "Jordan", "Kieran", "Connor", "Reece", "Tyrese", "Jayden"],
        lastNames: ["Smith", "Jones", "Taylor", "Brown", "Williams", "Wilson", "Davies", "Robinson", "Wright", "Thompson",
                    "Evans", "Walker", "Roberts", "Green", "Hall", "Wood", "Clarke", "Hughes", "Turner", "Cole", "Barnes", "Ward"])

    public static let scotland = NamePool(nationality: "Scotland",
        firstNames: ["Callum", "Lewis", "Ross", "Euan", "Fraser", "Jamie", "Kyle", "Liam", "Scott", "Craig", "Ryan", "Andrew", "Stuart", "Cameron"],
        lastNames: ["MacDonald", "Campbell", "Stewart", "Robertson", "Murray", "Fraser", "Ferguson", "McLean", "Reid", "Hamilton",
                    "Paterson", "McKenzie", "Grant", "Duncan", "Mackay", "Watt"])

    public static let spain = NamePool(nationality: "Spain",
        firstNames: ["Álvaro", "Pablo", "Sergio", "Javier", "Diego", "Adrián", "Iván", "Raúl", "Marcos", "Hugo", "Unai",
                     "Iker", "Rubén", "Jorge", "Alejandro", "Mario", "Daniel", "Carlos", "Víctor", "Íñigo"],
        lastNames: ["García", "Fernández", "González", "Rodríguez", "López", "Martínez", "Sánchez", "Pérez", "Gómez", "Martín",
                    "Jiménez", "Ruiz", "Hernández", "Díaz", "Moreno", "Muñoz", "Álvarez", "Romero", "Navarro", "Torres"])

    public static let italy = NamePool(nationality: "Italy",
        firstNames: ["Lorenzo", "Matteo", "Alessandro", "Andrea", "Francesco", "Riccardo", "Federico", "Davide", "Simone",
                     "Gabriele", "Luca", "Marco", "Giorgio", "Nicolò", "Tommaso", "Pietro", "Daniele", "Stefano"],
        lastNames: ["Rossi", "Russo", "Ferrari", "Esposito", "Bianchi", "Romano", "Colombo", "Ricci", "Marino", "Greco",
                    "Bruno", "Gallo", "Conti", "De Luca", "Costa", "Giordano", "Mancini", "Rizzo", "Lombardi", "Moretti"])

    public static let germany = NamePool(nationality: "Germany",
        firstNames: ["Lukas", "Leon", "Finn", "Jonas", "Paul", "Felix", "Maximilian", "Tim", "Niklas", "Jan", "Moritz",
                     "Florian", "Tobias", "Kevin", "Marvin", "Julian", "Fabian", "Dennis"],
        lastNames: ["Müller", "Schmidt", "Schneider", "Fischer", "Weber", "Meyer", "Wagner", "Becker", "Schulz", "Hoffmann",
                    "Koch", "Richter", "Klein", "Wolf", "Schröder", "Neumann", "Braun", "Zimmermann", "Krüger", "Hartmann"])

    public static let france = NamePool(nationality: "France",
        firstNames: ["Lucas", "Hugo", "Théo", "Mathis", "Enzo", "Louis", "Nathan", "Maxime", "Clément", "Antoine",
                     "Yanis", "Bastien", "Florian", "Kylian", "Rayan", "Quentin", "Romain", "Adrien"],
        lastNames: ["Martin", "Bernard", "Dubois", "Thomas", "Robert", "Richard", "Petit", "Durand", "Leroy", "Moreau",
                    "Simon", "Laurent", "Lefebvre", "Michel", "Garcia", "Fournier", "Girard", "Bonnet", "Mercier", "Diallo"])

    public static let portugal = NamePool(nationality: "Portugal",
        firstNames: ["João", "Rodrigo", "Tiago", "Diogo", "Gonçalo", "Rúben", "Pedro", "Francisco", "Miguel", "Afonso", "Rafael", "Bruno"],
        lastNames: ["Silva", "Santos", "Ferreira", "Pereira", "Oliveira", "Costa", "Rodrigues", "Martins", "Sousa", "Gomes", "Lopes", "Carvalho"])

    public static let netherlands = NamePool(nationality: "Netherlands",
        firstNames: ["Daan", "Sem", "Lars", "Thijs", "Jesse", "Bram", "Ruben", "Stijn", "Joey", "Milan", "Luuk", "Jens"],
        lastNames: ["de Jong", "Jansen", "de Vries", "van den Berg", "Bakker", "Visser", "Smit", "Meijer", "de Boer", "Mulder", "Dekker", "Bos"])

    public static let brazil = NamePool(nationality: "Brazil",
        firstNames: ["Gabriel", "Lucas", "Matheus", "Pedro", "Vinícius", "Rafael", "Felipe", "Gustavo", "Thiago", "Caio", "Igor", "Bruno"],
        lastNames: ["Silva", "Santos", "Oliveira", "Souza", "Lima", "Pereira", "Costa", "Ribeiro", "Almeida", "Carvalho", "Gomes", "Rocha"])

    public static let argentina = NamePool(nationality: "Argentina",
        firstNames: ["Santiago", "Matías", "Nicolás", "Facundo", "Agustín", "Tomás", "Lautaro", "Franco", "Joaquín", "Gonzalo", "Emiliano", "Thiago"],
        lastNames: ["González", "Rodríguez", "Gómez", "Fernández", "López", "Díaz", "Martínez", "Pérez", "Romero", "Sosa", "Álvarez", "Acosta"])

    /// Nationalities that commonly appear in other countries' squads.
    public static let international = NamePool(nationality: "Nigeria",
        firstNames: ["Samuel", "Emmanuel", "Moussa", "Ibrahim", "Kwame", "Yusuf", "Ismaïla", "Victor", "Christian", "Joseph"],
        lastNames: ["Mensah", "Okafor", "Diallo", "Traoré", "Koné", "Adeyemi", "Boateng", "Ndiaye", "Sarr", "Osei"])

    /// The home pool for a league country.
    public static func pool(for country: LeagueCountry) -> NamePool {
        switch country {
        case .england: return england
        case .scotland: return scotland
        case .spain: return spain
        case .italy: return italy
        case .germany, .austria, .switzerland: return germany
        case .france, .belgium: return france
        case .portugal: return portugal
        case .netherlands: return netherlands
        case .brazil: return brazil
        case .argentina: return argentina
        default: return international
        }
    }

    /// A believable name and nationality for a player at a club in `country`:
    /// mostly home-grown, with a share of foreign players as in real squads.
    public static func randomIdentity(for country: LeagueCountry) -> (first: String, last: String, nationality: String) {
        let home = pool(for: country)
        let foreignPools = [england, spain, france, portugal, brazil, argentina, netherlands, germany, italy, international]
            .filter { $0.nationality != home.nationality }
        let chosen = Double.random(in: 0..<1) < 0.75 ? home : (foreignPools.randomElement() ?? home)
        let name = chosen.randomName()
        if chosen.nationality == "Nigeria" {
            // The "international" pool spans several West African nations.
            let nations = ["Nigeria", "Ghana", "Senegal", "Ivory Coast", "Mali"]
            return (name.first, name.last, nations.randomElement() ?? "Nigeria")
        }
        return (name.first, name.last, chosen.nationality)
    }
}

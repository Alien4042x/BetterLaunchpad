//
//  FavoritesManager.swift
//  BetterLaunchpad
//
//  Created by Radim Veselý on 08.12.2025.
//

import Foundation
import Combine

final class FavoritesManager: ObservableObject {
    static let shared = FavoritesManager()
    
    @Published private(set) var favorites: Set<String> = []
    
    private let key = "favoriteApps"
    
    private init() {
        loadFavorites()
    }
    
    private func loadFavorites() {
        if let data = UserDefaults.standard.array(forKey: key) as? [String] {
            favorites = Set(data)
        }
    }
    
    private func saveFavorites() {
        UserDefaults.standard.set(Array(favorites), forKey: key)
    }
    
    func isFavorite(_ path: String) -> Bool {
        favorites.contains(path)
    }
    
    func toggleFavorite(_ path: String) {
        if favorites.contains(path) {
            favorites.remove(path)
        } else {
            favorites.insert(path)
        }
        saveFavorites()
    }
    
    func addFavorite(_ path: String) {
        favorites.insert(path)
        saveFavorites()
    }
    
    func removeFavorite(_ path: String) {
        favorites.remove(path)
        saveFavorites()
    }
}

//
//  PokeAnnotation.swift
//  PokeFinder
//
//  Created by Julius Kiano on 2/19/17.
//  Copyright © 2017 Julius Kiano. All rights reserved.
//

import Foundation

class PokeAnnotation: NSObject, MKAnnotation {
    var coordinate = CLLocationCoordinate2D()
    var pokemonNumber: Int
    var pokemonName: String
    var title: String?
    
    
    // here we deifne custom annotation for each pokemon on the map
    init(coordinate: CLLocationCoordinate2D, pokemonNumber: Int) {
        let pokemon = PokeMaster().getPokemonArray()
        self.coordinate = coordinate
        self.pokemonNumber = pokemonNumber
        self.pokemonName = pokemon[pokemonNumber - 1].capitalized
        self.title = self.pokemonName
    }
}

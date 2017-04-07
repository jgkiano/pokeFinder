//
//  Pokemon.swift
//  pokedex
//
//  Created by Julius Kiano on 2/24/17.
//  Copyright © 2017 Julius Kiano. All rights reserved.
//

import Foundation

class Pokemon {
    fileprivate var _name: String!
    fileprivate var _pokedexId: Int!
    //a model of all pokemon
    var name: String {
        return _name
    }
    
    var pokedexId: Int {
        return _pokedexId
    }
    
    init(name: String, pokedexId: Int) {
        self._name = name
        self._pokedexId = pokedexId
    }
}

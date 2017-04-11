//
//  ViewController.swift
//  pokedex
//
//  Created by Julius Kiano on 2/24/17.
//  Copyright © 2017 Julius Kiano. All rights reserved.
//

import UIKit

//all hail serverless apps
import FirebaseDatabase


class PokeFinderView: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource,
UICollectionViewDelegateFlowLayout, UISearchBarDelegate {
    
    var geoFire: GeoFire!
    
    var geoFireRef: FIRDatabaseReference!
    
    @IBOutlet weak var collection: UICollectionView!
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    var pokemon = [Pokemon]()
    
    var filteredPokemon = [Pokemon]()
    
    var inSearchMode = false
    
    var locationPassed: CLLocation!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collection.dataSource = self
        collection.delegate = self
        searchBar.delegate = self
        
        searchBar.returnKeyType = UIReturnKeyType.done
        
        //here set up geofire reference
        geoFireRef = FIRDatabase.database().reference()
        geoFire = GeoFire(firebaseRef: geoFireRef)
        
        getPokemonFromMaster()
    }
    
    func getPokemonFromMaster() {
        let pokemonMaster = PokeMaster()
        let pokeArray = pokemonMaster.getPokemonArray()
        
        for i in (0..<pokeArray.count)
        {
            let id = i + 1
            let name = pokeArray[i]
            let poke = Pokemon(name: name, pokedexId: id)
            pokemon.append(poke)
        }
    }
    
    //this is so that we don't load all 700 pokemon at once..
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PokeCell", for: indexPath) as? PokeCell {
            let poke: Pokemon!
            if inSearchMode {
                poke = filteredPokemon[indexPath.row]
                cell.configureCell(poke)
            } else {
                poke = pokemon[indexPath.row]
                cell.configureCell(poke)
            }
            return cell
        } else {
            return UICollectionViewCell()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        var poke: Pokemon!
        if inSearchMode {
            poke = filteredPokemon[indexPath.row]
            print(poke.pokedexId)
        } else {
            poke = pokemon[indexPath.row]
            print(poke.pokedexId)
        }
        createSighting(forLocation: locationPassed, withPokemon: poke.pokedexId)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if inSearchMode {
            return filteredPokemon.count
        } else {
            return pokemon.count
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    //size of cells..literally
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 105, height: 105)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(true)
    }
    //where filtering magic occurs
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text == nil || searchBar.text == "" {
            inSearchMode = false
            collection.reloadData()
            view.endEditing(true)
        } else {
            inSearchMode = true
            let lower = searchBar.text!.lowercased()
            //filter original pokemon array where name is in range of the lower text
            filteredPokemon = pokemon.filter({$0.name.range(of: lower) != nil})
            collection.reloadData()
        }
    }
    
    //this one line is where all the magic happens
    func createSighting(forLocation location: CLLocation, withPokemon pokeId: Int) {
        geoFire.setLocation(location, forKey: "\(pokeId)")
        performSegue(withIdentifier: "CreatedSiteVC", sender: PokeFinderView.self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "CreatedSiteVC") {
            //Checking identifier is crucial as there might be multiple
            // segues attached to same view
            let viewController = segue.destination as! ViewController;
            viewController.updatedSighting = true
        }
    }
    
    
    
}


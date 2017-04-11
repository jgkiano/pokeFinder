//
//  ViewController.swift
//  PokeFinder
//
//  Created by Julius Kiano on 2/19/17.
//  Copyright © 2017 Julius Kiano. All rights reserved.
//

import UIKit
//map kit for CLLocation
import MapKit

//all hail serverless apps
import FirebaseDatabase

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    //reference to the pokemaster
    var model = PokeMaster()
    
    //mapView outlet
    @IBOutlet weak var mapView: MKMapView!
    
    let locationManager = CLLocationManager()
    
    //this is so that user can pan around without it snapping back
    var mapHasCentredOnce = false
    
    //store and query a set of keys based on their geographic location.
    //A GeoFire object is used to read and write geo location data to your Firebase database and to create queries.
    //To create a new GeoFire instance you need to attach it to a Firebase database reference:
    
    var geoFire: GeoFire!
    
    var geoFireRef: FIRDatabaseReference!
    
    //array of empty pokemons at first
    var pokemon: Array<String>? = nil
    
    //outlet for the pokeball
    @IBOutlet weak var pokeBall: UIButton!
    
    //out let for the add button
    @IBOutlet weak var addButton: UIButton!
    
    //
    var updatedSighting: Bool = false
    
    var currentUserLocation = CLLocation()
    
    //on view did load
    override func viewDidLoad() {
        super.viewDidLoad()
        //A delegate allows one object to send messages to another object when an event happens.
        mapView.delegate = self
        
        //this makes sure the map moves with you as your location changes
        mapView.userTrackingMode = MKUserTrackingMode.follow
        
        //here set up geofire reference
        geoFireRef = FIRDatabase.database().reference()
        geoFire = GeoFire(firebaseRef: geoFireRef)
        
        //get pokemons and hide picker initially
        pokemon = model.getPokemonArray()
    }
    
    //on view did appear we check the location status
    
    override func viewDidAppear(_ animated: Bool) {
        locationAuthStatus()
    }
    
    //here we handle the requesting for permissions
    
    func locationAuthStatus() {
        //dont drain peoples battery
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            mapView.showsUserLocation = true
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    //center map on users current location..2000 is meters range
    
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, 2000, 2000)
        if updatedSighting {
            mapView.setRegion(coordinateRegion, animated: true)
        } else {
            mapView.setRegion(coordinateRegion, animated: false)
        }
        
    }
    
    //did update function..
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        currentUserLocation = userLocation.location!
        if let loc = userLocation.location {
            if !mapHasCentredOnce {
                centerMapOnLocation(location: loc)
                mapHasCentredOnce = true
            }
        }
    }
    
    //this handles the annotation from ash the user and pokemons. 
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var annotationView: MKAnnotationView?
        let annoIdentifier = "Pokemon"
        
        //if this a userlocation annotation
        if annotation.isKind(of: MKUserLocation.self) {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "User")
            annotationView?.image = UIImage(named: "ash")
        }
        // here we set it up so we can resuse an annotation if needed
        else if let deqAnnov = mapView.dequeueReusableAnnotationView(withIdentifier: annoIdentifier) {
            annotationView = deqAnnov
            annotationView?.annotation = annotation
        }
        //other wise create new one
        else {
            let av = MKAnnotationView(annotation: annotation, reuseIdentifier: annoIdentifier)
            //pop up appear with disclosure
            av.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            annotationView = av
        }
        //cast the annotaion to a pokemon annotation
        if let annotationView = annotationView, let anno = annotation as? PokeAnnotation {
            annotationView.canShowCallout = true
            //get pokemon image
            annotationView.image = UIImage(named: "\(anno.pokemonNumber)")
            //create buttton
            let btn = UIButton()
            //some kidigo styling..not too much sauce
            btn.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            btn.setImage(UIImage(named: "map"), for: .normal)
            //set right call out accessory to btn
            annotationView.rightCalloutAccessoryView = btn
            
        }
        return annotationView
    }
    
    //when mapp icon is tapped
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        if let anno = view.annotation as? PokeAnnotation {
            
            var place: MKPlacemark!
            //check ios version
            if #available(iOS 10.0, *) {
                place = MKPlacemark(coordinate: anno.coordinate)
            } else {
                place = MKPlacemark(coordinate: anno.coordinate, addressDictionary: nil)
            }
            
            let destination = MKMapItem(placemark: place)
            destination.name = "Pokemon Sighting"
            let regionDistance: CLLocationDistance = 1000
            let regionSpan = MKCoordinateRegionMakeWithDistance(anno.coordinate, regionDistance, regionDistance)
            
            let options = [MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center), MKLaunchOptionsMapSpanKey:  NSValue(mkCoordinateSpan: regionSpan.span), MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving] as [String : Any]
            //open with maps
            MKMapItem.openMaps(with: [destination], launchOptions: options)
        }
        
    }
    
    func showSightingsOnMap(location: CLLocation) {
        //the query is for 2.5 kilimoteres, so it will show pokemon in a 2.5km radius
        let circleQuery = geoFire!.query(at: location, withRadius: 2.5)
        //called automatically when key is entered
        _ = circleQuery?.observe(GFEventType.keyEntered, with: { (key, location) in
            
            if let key = key, let location = location {
                let anno = PokeAnnotation(coordinate: location.coordinate, pokemonNumber: Int(key)!)
                
                self.mapView.addAnnotation(anno)
            }
        })
    }
    
    //this function updates the map when user pans around
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        //loc to be the center of map
        let loc = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        
        showSightingsOnMap(location: loc)
    }
    
    @IBAction func spotRandomPokemon(_ sender: AnyObject) {
        let loc = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        
        let rand = arc4random_uniform(151) + 1
        createSighting(forLocation: loc, withPokemon: Int(rand))
    }
    
    //this one line is where all the magic happens
    func createSighting(forLocation location: CLLocation, withPokemon pokeId: Int) {
        geoFire.setLocation(location, forKey: "\(pokeId)")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "PokeFinderView") {
            //Checking identifier is crucial as there might be multiple
            // segues attached to same view
            let pokeFinderVC = segue.destination as! PokeFinderView;
            pokeFinderVC.locationPassed = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
//            pokeFinderVC.locationPassed = currentUserLocation
        }
    }

}


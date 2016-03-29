//
//  MapViewController.swift
//  BikeFindr
//
//  Created by Matt Deuschle on 3/25/16.
//  Copyright © 2016 Matt Deuschle. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

    @IBOutlet var mapView: MKMapView!

    var bikes = [Divvy]()

    let locationManager = CLLocationManager()
    var currentLocation = CLLocation()
    let bikesAnnotaion = MKPointAnnotation()

    override func viewDidLoad() {
        super.viewDidLoad()

        requestLocation()
        downloadBikeStations()
//        setUpMapViewStart()

    }

//    func setUpMapViewStart() {
//        let chicagoCord = CLLocationCoordinate2D(latitude: 41.886257, longitude: -87.629875)
//        mapView.setRegion(MKCoordinateRegionMake(chicagoCord, MKCoordinateSpanMake(0.01, 0.01)), animated: false)
//    }

    func requestLocation() {

        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
    }

    func downloadBikeStations() {

        let url = NSURL(string: "http://www.divvybikes.com/stations/json")!
        let session = NSURLSession.sharedSession()

        session.dataTaskWithURL(url) { (data:NSData?, response:NSURLResponse?, error:NSError?) -> Void in
            do {
                if let bikeStationData = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments) as? [String:AnyObject] {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.configureData(bikeStationData)
                    })
                }
            } catch {}
            }.resume()
    }

    func configureData(data: [String:AnyObject]) {

        let results = data["stationBeanList"] as! [[String:AnyObject]]

        for bikestation in results {
            let newBikeStation = Divvy()
            newBikeStation.initWithData(bikestation, currentLocation: self.currentLocation)
            bikes.append(newBikeStation)
        }

        bikes.sortInPlace({ $0.0.distance < $0.1.distance })
        dropPins()
    }

    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, 2000, 2000)

        mapView.setRegion(coordinateRegion, animated: true)
    }

    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {

        if let loc = userLocation.location {

            centerMapOnLocation(loc)
        }
    }

    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        if let currentLoc = locations.first {

            currentLocation = currentLoc
            if currentLoc.verticalAccuracy < 1000 && currentLoc.horizontalAccuracy < 1000 {

                locationManager.stopUpdatingLocation()
                centerMapOnLocation(currentLocation)
            }
        }
    }

    func dropPins() {

        for bike in bikes {

            let newPin = BikePointAnnotation()
            newPin.coordinate = bike.coordinate2D
            newPin.title = bike.stationName
            newPin.subtitle = "Bikes Available: \(bike.availableBikes)"
            newPin.bikeStation = bike
            mapView.addAnnotation(newPin)
        }
    }

    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {

        if annotation.isEqual(mapView.userLocation) {
            return nil }

        let mapPin = MKAnnotationView()
        mapPin.canShowCallout = true
        mapPin.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
        mapPin.image = UIImage(named: "bikePin")
        return mapPin
    }

    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {

        print(error)
    }

    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView,
                 calloutAccessoryControlTapped control: UIControl) {

        performSegueWithIdentifier("DetailSeg", sender: nil)

    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        let detailView = segue.destinationViewController as! DetailViewController
        let selectedPoint = mapView.selectedAnnotations.first as! BikePointAnnotation
        detailView.selectedBikeStation = selectedPoint.bikeStation
        detailView.currentLocation = self.currentLocation
    }

    class BikePointAnnotation : MKPointAnnotation {

        var bikeStation : Divvy!
    }
}

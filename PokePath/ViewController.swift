
//  ViewController.swift
//  PokePath
//
//  Created by jeff on 2016-07-15.
//  Copyright © 2016 jeff. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import CoreFoundation
import GoogleAPIClient
import GTMOAuth2
import AEXML

class ViewController: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate, CLLocationManagerDelegate {
    

    @IBOutlet weak var PokeMap: MKMapView!
    @IBOutlet weak var generateTripButton: UIButton!
    @IBOutlet weak var RemovePathButton: NSLayoutConstraint!
    
    var tripCoordinates: [CLLocationCoordinate2D] = []
    var tripCoordinatesR: [CLLocationCoordinate2D] = []
    var lastCoordinate: CLLocationCoordinate2D?
    var currentDate: NSDate = NSDate()
    var wayPointCount = 0
    var locationManager = CLLocationManager()
    var currentLocation:CLLocation?
    var pokeStops = [AEXMLElement]()
    
    private let kKeyChainItemName = "PokeAPI"
    private let kClientID = "896283999397-aurvq4vdnm2q5fthlumd337rk9a60mv0.apps.googleusercontent.com"
    private let scopes = [kGTLAuthScopeDrive]
    
    private let service = GTLServiceDrive()
    
    var gestureRecognizer: UILongPressGestureRecognizer?
    override func viewDidLoad() {
        super.viewDidLoad()
        PokeMap.delegate = self
        
        gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(addAnnotation(gestureRecognizer:)))
        gestureRecognizer?.minimumPressDuration = 1.0
        PokeMap.addGestureRecognizer(gestureRecognizer!)
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        PokeMap.showsUserLocation = true
        
        //GoogleAPIstuff
        if let auth = GTMOAuth2ViewControllerTouch.authForGoogleFromKeychain(forName: kKeyChainItemName, clientID: kClientID, clientSecret: nil){
            service.authorizer = auth
        }
    
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    func centerMapOnLocation(location: CLLocation) {
        let regionRadius: CLLocationDistance = 1000
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate,latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
        PokeMap.setRegion(coordinateRegion, animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
//    override func viewDidAppear(_ animated: Bool) {
//        if let authorizer = service.authorizer, let canAuth = authorizer.canAuthorize, canAuth{
//            //fetchFiles()
//            print("Maybe fetch files here?")
//        }else{
////            present(
////                createAuthController(),
////                animated: true,
////                completion: nil
////            )
//        }
//    }
    
    private func createAuthController() -> GTMOAuth2ViewControllerTouch {
        let scopeString = scopes.joined(separator: " ")
        return GTMOAuth2ViewControllerTouch(
            scope: scopeString,
            clientID: kClientID,
            clientSecret: nil,
            keychainItemName: kKeyChainItemName,
            delegate: self,
            finishedSelector: #selector(authFinishedController(vc:finishedWithAuth:error:))
        )
    }
    
    @objc func authFinishedController(vc : UIViewController,
                        finishedWithAuth authResult : GTMOAuth2Authentication, error : NSError?) {
        
        if let error = error {
            service.authorizer = nil
            showAlert(title: "Authentication Error", message: error.localizedDescription)
            return
        }
        
        service.authorizer = authResult
        dismiss(animated: true, completion: nil)
    }
    
//    func fetchFiles(){
//        //print("Fetching files")
//        let query = GTLQueryDrive.queryForFilesList()
//        query?.q = "name = 'pokestop.xml'"
//        query?.pageSize = 1
//        query?.fields = "nextPageToken, files(id, name)"
//        service.executeQuery(query as! GTLQueryProtocol, delegate: self, didFinishSelector: #selector(self.displayResultWithTicket(_:finishedWithObject:error:)))
//    }
    
//    func displayResultWithTicket(ticket: GTLServiceTicket, finishedWithObject response: GTLDriveFileList, error: NSError?){
//        if let error = error{
//            showAlert(title: "Error", message: error.localizedDescription)
//            return
//        }
//        var fileString = ""
//        if let files = response.files, !files.isEmpty{
//            fileString += "Files: \n"
//            let file = files[0] as! GTLDriveFile
//            fileString += "\(file.name) (\(file.identifier))\n"
//            //print(file.JSONString())
//            let url = NSString(format: "https://www.googleapis.com/drive/v2/files/%@?alt=media", file.identifier)
//            //print(url)
//            let fetcherService = service.fetcherService
//            fetcherService?.authorizer = service.authorizer
//            let fetcher = fetcherService?.fetcher(withURLString: url as String)
//
//            fetcher!.service = fetcherService!
//            fetcher!.beginFetchWithCompletionHandler({ (data, error) in
//                if error == nil{
//                    //print("Retrieved file contents")
//                    do {
//                        let pokeDoc = try AEXMLDocument(xmlData: data!)
//
//                        for document in pokeDoc.root.children{
//                            for placemark in document.children{
//                                if placemark.name == "Placemark"{
//                                    self.pokeStops.append(placemark)
//                                }
//                            }
//
//                        }
//                        self.addPokeStops()
//                    }catch{
//                        print("AEXML parse error")
//                    }
//                }else{
//                    print("Error occured retrieving file contents")
//                    print(error?.description)
//                }
//            })
//            for file in files as! [GTLDriveFile]{
//                fileString += "\(file.name) (\(file.identifier))\n"
//            }
//            //print(fileString)
//        }else{
//            fileString = "No files found."
//            //print(fileString)
//        }
//    }
    
//    func stringFromTo(stringToIndex: String, fromIndex: String.Index, toIndex: String.Index)->(String, String){
//        return (stringToIndex.substringWithRange(Range<String.Index>(fromIndex..<toIndex)), stringToIndex.substringWithRange(Range<String.Index>(toIndex.advancedBy(1)..<stringToIndex.characters.endIndex)))
//    }

    func showAlert(title : String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: UIAlertController.Style.alert
        )
        let ok = UIAlertAction(
            title: "OK",
            style: UIAlertAction.Style.default,
            handler: nil
        )
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
    
    //MARK
    
    @objc func addAnnotation(gestureRecognizer: UIGestureRecognizer){
        if UIGestureRecognizer.State.began == gestureRecognizer.state{
            // Finger is pressed and gesture recognizer is at the end state
            let touchPoint = gestureRecognizer.location(in: PokeMap)
            let newCoordinates = PokeMap.convert(touchPoint, toCoordinateFrom: PokeMap)
            let annotation = MKPointAnnotation()
            annotation.coordinate = newCoordinates
            PokeMap.addAnnotation(annotation)
            tripCoordinates.append(newCoordinates)
            //need the coordinates in reverse so the trip can be made into a loop, tracing ones steps back to the original location
            tripCoordinatesR.insert(newCoordinates, at: tripCoordinates.startIndex)
        }
    }
    
//    func addPokeStops(){
//        for placemark in pokeStops{
//            if let coordinateString = placemark["Point"]["coordinates"].value{
//                let lat = self.stringFromTo(coordinateString, fromIndex: coordinateString.characters.startIndex, toIndex: coordinateString.characters.indexOf(",")!)
//                let lon = self.stringFromTo(lat.1, fromIndex: lat.1.characters.startIndex, toIndex: lat.1.characters.indexOf(",")!)
//                let loc = CLLocationCoordinate2DMake(Double(lon.0)!, Double(lat.0)!)
//                //let loc = CLLocationCoordinate2DMake(-80.4866794, 43.4910451)
////                PokeMap.addOverlay(PokeStop(title: "hallo", locationName: "PokeStop", coordinate: loc, boundingMapRect: MKMapRect(origin: MKMapPointForCoordinate(loc), size: MKMapSize(width: 10000.0, height: 1000.0))))
//                PokeMap.addAnnotation(PokeStop(title: "HALLO", locationName: "PokeStop", coordinate: loc))
//            }
//        }
//    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? PokeStop {
            let identifier = "PokeSop"
            var view: MKAnnotationView
            if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                as? MKPinAnnotationView { // 2
                dequeuedView.annotation = annotation
                view = dequeuedView
                view.annotation = annotation
                //view.pinTintColor = UIColor.greenColor()
                //view.image = UIImage(named: "Pokestop")
            } else {
                // 3
                view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.canShowCallout = false
                view.calloutOffset = CGPoint(x: -5, y: 5)
                view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
                //view.pinTintColor = UIColor.blueColor()
                let image = UIImage(named: "Pokestop")?.cgImage
                view.image = UIImage(cgImage: image!, scale: 40.0, orientation: UIImage.Orientation.up)
                view.annotation = annotation
            }
            return view
        }else{
            let identifier = "Pin"
            var view: MKAnnotationView
            if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView{
                dequeuedView.annotation = annotation
                view = dequeuedView
                view.annotation = annotation
            }else{
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "Pin")
                print(view.annotation)
            }
            return view
        }
        return nil
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        if view.annotation != nil, let annotation = view.annotation as? PokeStop{
            //Pokestop clicked
        }else{
            //Path annotation clicked
//            mapView.removeAnnotation(view.annotation!)
//            let annotationIndex = tripCoordinates.indexOf({ (coordinate: CLLocationCoordinate2D) -> Bool in
//                print(coordinate)
//                print(view.annotation)
//                return (coordinate.latitude == view.annotation!.coordinate.latitude && coordinate.longitude == view.annotation!.coordinate.longitude)
//            })
//            tripCoordinates.removeAtIndex(annotationIndex!)
        }
    }
    
    
    
    @IBAction func generateTrip(_ sender: UIButton!) {
        if (tripCoordinatesR.isEmpty) {
            return
        }
        
        tripCoordinatesR.removeFirst()
        var gpxFile = AEXMLDocument()
        let gpxAttributes = ["version" : "1.1", "creator" : "Xcode"]
        let gpx = gpxFile.addChild(name: "gpx", attributes: gpxAttributes)
        gpxFile = addGPXPoints(gpxFile: gpxFile, tripCoordinates: tripCoordinates, gpx: gpx)
        gpxFile = addGPXPoints(gpxFile: gpxFile, tripCoordinates: tripCoordinatesR, gpx: gpx)
        print("SHOULD PRINT A GPX FILE?")
        print(gpxFile.xml)
        //cleanup work
        lastCoordinate = nil
        tripCoordinates = []
        tripCoordinatesR = []
        currentDate =  NSDate()
        wayPointCount = 0
    }

    @IBAction func RemovePath(_ sender: AnyObject) {
        PokeMap.removeAnnotations(PokeMap.annotations);
        tripCoordinates = [];
        tripCoordinatesR = [];
    }
    
    func addGPXPoints(gpxFile: AEXMLDocument, tripCoordinates: [CLLocationCoordinate2D], gpx: AEXMLElement) -> AEXMLDocument{
        for annotationPoint in tripCoordinates{
            let wpxAttributes = ["lat":"\(annotationPoint.latitude.description)", "lon":"\(annotationPoint.longitude.description)"]
            let wayPoint = gpx.addChild(name: "wpt", attributes: wpxAttributes)
            wayPoint.addChild(name: "name", value: "Waypoint: \(wayPointCount)")
            wayPoint.addChild(name: "time", value: calculateTime(currentAnnotation: annotationPoint))
            lastCoordinate = annotationPoint
            wayPointCount += 1
        }
        return gpxFile
    }
    
    func calculateTime(currentAnnotation: CLLocationCoordinate2D) -> String{
        var timeInterval = TimeInterval()
        var timeItTakes = 1.0
        if let _=lastCoordinate{
            //distance is set in KM
            let currentMapPoint = MKMapPoint(currentAnnotation)
            let lastMapPoint = MKMapPoint(lastCoordinate!)
            let distance = currentMapPoint.distance(to: lastMapPoint)/1000
            //max walking speed in pokemon Go is reportedly ~24km/h so i'm assuming 20 is safe enough
            //timeItTakes should produce the number of seconds it takes to travel the distance between points when walking at 14km/h
            timeItTakes = (distance/5)*60*30
            //print("Time taken in min \(timeItTakes/60)")
        }
        timeInterval = timeInterval.advanced(by: timeItTakes)
        currentDate = currentDate.addingTimeInterval(timeInterval)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        return dateFormatter.string(from: currentDate as Date)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last
        
        let center = CLLocationCoordinate2D(latitude: location!.coordinate.latitude, longitude: location!.coordinate.longitude)
        
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        
        self.PokeMap.setRegion(region, animated: true)
        
        self.locationManager.stopUpdatingLocation()
    }
    
}


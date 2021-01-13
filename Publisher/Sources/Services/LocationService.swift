import CoreLocation

protocol LocationServiceDelegate: AnyObject {
    func locationService(sender: LocationService, didFailWithError error: Error)
    func locationService(sender: LocationService, didUpdateRawLocation location: CLLocation)
    func locationService(sender: LocationService, didUpdateEnhancedLocation location: CLLocation)
}

protocol LocationService: AnyObject {
    var delegate: LocationServiceDelegate? { get set }
    func startUpdatingLocation()
    func stopUpdatingLocation()
    func changeLocationEngineResolution(resolution: Resolution)
    func changeRoutingProfile(profile: RoutingProfile)
}

import UIKit
import CoreLocation
import Logging
// swiftlint:disable cyclomatic_complexity

// Default logger used in Publisher SDK
let logger: Logger = Logger(label: "com.ably.asset-tracking.Publisher")

class DefaultPublisher: Publisher {
    private let workingQueue: DispatchQueue
    private let connectionConfiguration: ConnectionConfiguration
    private let logConfiguration: LogConfiguration
    private let locationService: LocationService
    private let ablyService: AblyPublisherService

    public let transportationMode: TransportationMode
    public weak var delegate: PublisherDelegate?
    private(set) public var activeTrackable: Trackable?

    init(connectionConfiguration: ConnectionConfiguration,
         logConfiguration: LogConfiguration,
         transportationMode: TransportationMode) {
        self.connectionConfiguration = connectionConfiguration
        self.logConfiguration = logConfiguration
        self.transportationMode = transportationMode
        self.workingQueue = DispatchQueue(label: "io.ably.asset-tracking.Publisher.DefaultPublisher",
                                          qos: .default)
        self.locationService = LocationService()
        self.ablyService = AblyPublisherService(configuration: connectionConfiguration)

        self.ablyService.delegate = self
        self.locationService.delegate = self
    }

    func track(trackable: Trackable, onSuccess: @escaping SuccessHandler, onError: @escaping ErrorHandler) {
        let event = TrackTrackableEvent(trackable: trackable,
                                        onSuccess: onSuccess,
                                        onError: onError)
        execute(event: event)
    }

    func add(trackable: Trackable) {
        // TODO: Implement method
        failWithNotYetImplemented()
    }

    func remove(trackable: Trackable) -> Bool {
        // TODO: Implement method
        failWithNotYetImplemented()
        return false
    }

    func stop() {
        // TODO: Implement method
        failWithNotYetImplemented()
    }
}

// MARK: Threading events handling
extension DefaultPublisher {
    private func execute(event: PublisherEvent) {
        logger.trace("Received event: \(event)")
        performOnWorkingThread { [weak self] in
            switch event {
            case let event as SuccessEvent: self?.handleSuccessEvent(event)
            case let event as ErrorEvent: self?.handleErrorEvent(event)
            case let event as TrackTrackableEvent:  self?.performTrackTrackableEvent(event)
            case let event as TrackableReadyToTrackEvent: self?.performTrackableReadyToTrack(event)
            case let event as EnhancedLocationChangedEvent: self?.performEnhancedLocationChanged(event)
            case let event as RawLocationChangedEvent: self?.performRawLocationChanged(event)

            // Delegate events
            case let event as DelegateErrorEvent: self?.notifyDelegateDidFailWithError(event.error)
            case let event as DelegateConnectionStateChangedEvent: self?.notifyDelegateConnectionStateChanged(event)
            case let event as DelegateRawLocationChangedEvent: self?.notifyDelegateRawLocationChanged(event)
            case let event as DelegateEnhancedLocationChangedEvent: self?.notifyDelegateEnhancedLocationChanged(event)
            default: preconditionFailure("Unhandled event in DefaultPublisher: \(event) ")
            }
        }
    }

    // MARK: Track
    private func performTrackTrackableEvent(_ event: TrackTrackableEvent) {
        guard activeTrackable == nil else {
            let error =  AssetTrackingError.publisherError("For this preview version of the SDK, track() method may only be called once for any given instance of this class.")
            execute(event: ErrorEvent(error: error, onError: event.onError))
            return
        }

        activeTrackable = event.trackable
        self.ablyService.track(trackable: event.trackable) { [weak self] error in
            if let error = error {
                self?.execute(event: ErrorEvent(error: error, onError: event.onError))
                return
            }
            self?.execute(event: TrackableReadyToTrackEvent(trackable: event.trackable, onSuccess: event.onSuccess))
        }
    }

    private func performTrackableReadyToTrack(_ event: TrackableReadyToTrackEvent) {
        locationService.startUpdatingLocation()
        execute(event: SuccessEvent(onSuccess: event.onSuccess))
    }

    // MARK: Location change
    private func performEnhancedLocationChanged(_ event: EnhancedLocationChangedEvent) {
        self.ablyService.sendEnhancedAssetLocation(location: event.location) { [weak self] error in
            if let error = error {
                self?.execute(event: DelegateErrorEvent(error: error))
            }
        }
    }

    private func performRawLocationChanged(_ event: RawLocationChangedEvent) {
        ablyService.sendRawAssetLocation(location: event.location) { [weak self] error in
            if let error = error {
                self?.execute(event: DelegateErrorEvent(error: error))
            }
        }
    }

    // MARK: Utils
    private func performOnWorkingThread(_ operation: @escaping () -> Void) {
        workingQueue.async(execute: operation)
    }

    private func performOnMainThread(_ operation: @escaping () -> Void) {
        DispatchQueue.main.async(execute: operation)
    }

    private func handleSuccessEvent(_ event: SuccessEvent) {
        performOnMainThread(event.onSuccess)
    }

    private func handleErrorEvent(_ event: ErrorEvent) {
        performOnMainThread { event.onError(event.error) }
    }

    // MARK: Delegate
    private func notifyDelegateDidFailWithError(_ error: Error) {
        performOnMainThread { [weak self] in
            guard let self = self else { return }
            self.delegate?.publisher(sender: self, didFailWithError: error)
        }
    }

    private func notifyDelegateRawLocationChanged(_ event: DelegateRawLocationChangedEvent) {
        performOnMainThread { [weak self] in
            guard let self = self else { return }
            self.delegate?.publisher(sender: self, didUpdateRawLocation: event.location)
        }
    }

    private func notifyDelegateEnhancedLocationChanged(_ event: DelegateEnhancedLocationChangedEvent) {
        performOnMainThread { [weak self] in
            guard let self = self else { return }
            self.delegate?.publisher(sender: self, didUpdateEnhancedLocation: event.location)
        }
    }

    private func notifyDelegateConnectionStateChanged(_ event: DelegateConnectionStateChangedEvent) {
        performOnMainThread { [weak self] in
            guard let self = self else { return }
            self.delegate?.publisher(sender: self, didChangeConnectionState: event.connectionState)
        }
    }
}

// MARK: LocationServiceDelegate
extension DefaultPublisher: LocationServiceDelegate {
    func locationService(sender: LocationService, didFailWithError error: Error) {
        logger.error("locationService.didFailWithError. Error: \(error)", source: "DefaultPublisher")
        execute(event: DelegateErrorEvent(error: error))
    }

    func locationService(sender: LocationService, didUpdateRawLocation location: CLLocation) {
        logger.debug("locationService.didUpdateRawLocation.", source: "DefaultPublisher")
        execute(event: RawLocationChangedEvent(location: location))
        execute(event: DelegateRawLocationChangedEvent(location: location))
    }

    func locationService(sender: LocationService, didUpdateEnhancedLocation location: CLLocation) {
        logger.debug("locationService.didUpdateEnhancedLocation.", source: "DefaultPublisher")
        execute(event: EnhancedLocationChangedEvent(location: location))
        execute(event: DelegateEnhancedLocationChangedEvent(location: location))
    }
}

// MARK: AblyPublisherServiceDelegate
extension DefaultPublisher: AblyPublisherServiceDelegate {
    func publisherService(sender: AblyPublisherService, didChangeConnectionState state: ConnectionState) {
        logger.debug("publisherService.didChangeConnectionState. State: \(state)", source: "DefaultPublisher")
        execute(event: DelegateConnectionStateChangedEvent(connectionState: state))
    }
}

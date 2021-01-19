import UIKit

/**
 Default and preferred way to create the `Publisher`.
 */
public protocol PublisherBuilder {
    /**
     Creates a `Publisher` which is ready to publish the asset location to subscribers.
     Notice that it needs asset to to track - it can be set using `Publisher.track()` function.

     - throws: `AssetTrackingError.incompleteConfiguration`  in case of missing mandatory property
     - Returns: `Publisher`  ready to `track` the asset.
     */
    func start() throws -> Publisher

    /**
     Sets the mandatory `ConnectionConfiguration` property
     */
    func connection(_ configuration: ConnectionConfiguration) -> PublisherBuilder

    /**
     Sets the mandatory `LogConfiguration` property
     */
    func log(_ configuration: LogConfiguration) -> PublisherBuilder

    /**
     Sets the mandatory `TransportationMode` property
     */
    func transportationMode(_ transportationMode: TransportationMode) -> PublisherBuilder

    /**
     Sets the mandatory `ResolutionPolicyFactory` property
     */
    func resolutionPolicyFactory(_ factory: ResolutionPolicyFactory) -> PublisherBuilder

    /**
     Sets the optional `Delegate` property.
     It's optional to pass it via builder, as it can be set directly on `Publisher`.  Maintains weak reference.
     */
    func delegate(_ delegate: PublisherDelegate) -> PublisherBuilder
}

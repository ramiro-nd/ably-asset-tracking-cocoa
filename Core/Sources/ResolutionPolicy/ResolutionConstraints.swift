/**
 Specifies factors which contribute towards deciding the tracking `Resolution` for a `Trackable`.
 */
@objc
public protocol ResolutionConstraints { }

/**
 Specifies the thresholds and corresponding logical mappings for tracking `Resolution`s that are required by the
 default `ResolutionPolicy`, which can adopted by `Publisher` instances using the `Builder` `Publisher.Builder`'s
 `resolutionPolicy` `Publisher.Builder.resolutionPolicy` method, providing it with an instance of the
 `DefaultResolutionPolicyFactory` class.
 */
public class DefaultResolutionConstraints: NSObject, ResolutionConstraints {
    /**
     Tracking `Resolution` specifications which are to be used according to thresholds.
     */
    let resolutions: DefaultResolutionSet

    /**
     The boundary differentiating between "near" and "far" in `resolutions`.
     */
    let proximityThreshold: Proximity

    /**
     In the range 0.0f (no battery) to 100.0f (full battery).
     */
    let batteryLevelThreshold: Float

    /**
     The multiplier to be applied to the `interval` `Resolution.desiredInterval` when the battery level is below
     `batteryLevelThreshold`.
     */
    let lowBatteryMultiplier: Float

    @objc
    public init(resolutions: DefaultResolutionSet,
                proximityThreshold: Proximity,
                batteryLevelThreshold: Float,
                lowBatteryMultiplier: Float) {
        self.resolutions = resolutions
        self.proximityThreshold = proximityThreshold
        self.batteryLevelThreshold = batteryLevelThreshold
        self.lowBatteryMultiplier = lowBatteryMultiplier
    }
}

/**
 * The set of resolutions which must be defined in order to specify `DefaultResolutionConstraints`, which are required
 * to use the default `ResolutionPolicy`, as created by instances of the `DefaultResolutionPolicyFactory` class.
 */
public class DefaultResolutionSet: NSObject {
    /**
     The resolution to select if above the `proximityThreshold` `DefaultResolutionConstraints.proximityThreshold`,
     with no subscribers.
     */
    let farWithoutSubscriber: Resolution

    /**
     The resolution to select if above the `proximityThreshold` `DefaultResolutionConstraints.proximityThreshold`,
     with one or more subscribers.
     */
    let farWithSubscriber: Resolution

    /**
     The resolution to select if below the `proximityThreshold` `DefaultResolutionConstraints.proximityThreshold`,
     with no subscribers.
     */
    let nearWithoutSubscriber: Resolution

    /**
     The resolution to select if below the `proximityThreshold` `DefaultResolutionConstraints.proximityThreshold`,
     with one or more subscribers.
     */
    let nearWithSubscriber: Resolution

    /**
     `ResolutionConstraints` initializer.
     */
    public init(farWithoutSubscriber: Resolution,
                farWithSubscriber: Resolution,
                nearWithoutSubscriber: Resolution,
                nearWithSubscriber: Resolution) {
        self.farWithSubscriber = farWithSubscriber
        self.farWithoutSubscriber = farWithoutSubscriber
        self.nearWithSubscriber = nearWithSubscriber
        self.nearWithoutSubscriber = nearWithoutSubscriber
    }

    /**
      Creates an instance of this class, using a single `Resolution` for all states.
     - Parameters:
        - resolution The resolution to be used to populate all fields.
     */
    public init(resolution: Resolution) {
        self.farWithSubscriber = resolution
        self.farWithoutSubscriber = resolution
        self.nearWithSubscriber = resolution
        self.nearWithoutSubscriber = resolution
    }
}

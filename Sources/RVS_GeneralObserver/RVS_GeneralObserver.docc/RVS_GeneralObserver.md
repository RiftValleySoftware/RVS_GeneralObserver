# ``RVS_GeneralObserver``

This is a general-purpose set of protocols that are designed to provide a simple infrastructure for a basic Observer implementation.

## Overview

[Here is the GitHub repo for the project.](https://github.com/RiftValleySoftware/RVS_GeneralObserver)

[Here is the main documentation for the project.](https://riftvalleysoftware.github.io/RVS_GeneralObserver/)

### Does Not Handle Messaging

This does not deal with messaging or managing communications between observers and observables. It simply gives them the infrastructure to track each other.

There are a few callbacks, explicitly related to aggregate management, but, otherwise, it's simply a tool to provide a reliable relationship graph management.

It is up to implementations to handle what to do with this information.

### Protocol-Based

This is based on protocols, as opposed to classes or structs. A couple of the protocols require that they be implemented as classes. There is heavy reliance on protocol default implementations to deliver the infrastructure.

## What Problem Does This Solve?

At its heart, any observer implementation is really just a relationship graph. Observers _subscribe_ to Observables. Observables use the subscription as a one-way broadcast medium.

Managing the subscriptions and relationships is absolutely fundamental to the pattern. If we can't trust our subscription list, then everything built upon it is at risk.

### Different From Delegate

Apple uses the [Delegate](https://developer.apple.com/library/archive/documentation/General/Conceptual/CocoaEncyclopedia/DelegatesandDataSources/DelegatesandDataSources.html) pattern in a lot of their Cocoa infrastucture. This is an excellent and simple pattern that has the following features:

- Delegates are a "one-to-one" relationship. A class that has a delegate has only one delegate.
- Delegates are often "two-way" relationships. Delegates can send information back to the objects to which they are subscribed. In fact, [the Data Source pattern](https://developer.apple.com/library/archive/documentation/General/Conceptual/CocoaEncyclopedia/DelegatesandDataSources/DelegatesandDataSources.html#//apple_ref/doc/uid/TP40010810-CH11-SW6) codifies this explicitly.
- Delegates require that all involved entities be classes. In fact, delegates need to derive from [NSObject](https://developer.apple.com/documentation/objectivec/nsobject).

Observers (at least, they way I do them) have a different aspect:

- They are usually a "one-to-many" relationship. Observers _subscribe_ to observables, who are responsible for managing a list of subscribers.
- They are a "one-way" relationship. Observables can only send messages to subscribers. They cannot receive anything. If an observable wants to get messages from a subscriber, then the subscriber needs to become an observable, and the old observable needs to subscribe to them.
- It isn't a requirement for observers and observables to be classes, to satisfy the pattern, but I do require that a couple of the protocols be class-based protocols, in order to implement some of the defaults.

### Benefits

Managing the subscription lists and relationships is a very fundamental part of Observer, and something that needs to be rock-solid. That was why this tool was developed.

We shouldn't even be thinking about this.

## Implementation

### [Swift Package Manager (SPM)](https://swift.org/package-manager/):

The URI for the repo is:

- [git@github.com:RiftValleySoftware/RVS_GeneralObserver.git](git@github.com:RiftValleySoftware/RVS_GeneralObserver.git) (SSH), or
- [https://github.com/RiftValleySoftware/RVS_GeneralObserver.git](https://github.com/RiftValleySoftware/RVS_GeneralObserver.git) (HTTPS).

Once you have the package included in your project (if you want to find out more about SPM, then you might want to [view this series](https://littlegreenviper.com/series/spm/)), you'll need to include the library. It will be a static (build-time) library:

    import RVS_GeneralObserver

### [Carthage](https://github.com/Carthage/Carthage):

You can include the library by adding the following line to your [Cartfile](https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md#cartfile):

    github "RiftValleySoftware/RVS_GeneralObserver"
    
You should probably just include the `Carthage/Checkouts/RVS_GeneralObserver/Sources/RVS_GeneralObserver/RVS_GeneralObserver_Protocols.swift` file directly, as opposed to building a library.

### [Git Submodule](https://git-scm.com/book/en/v2/Git-Tools-Submodules) or Direct File Download

If you want to include the project as a submodule, simply use one of the URIs above (in the Swift Package Manager section). It's probably best to include [the `Sources/RVS_GeneralObserver/RVS_GeneralObserver_Protocols.swift` file](https://github.com/RiftValleySoftware/RVS_GeneralObserver/blob/master/Sources/RVS_GeneralObserver/RVS_GeneralObserver_Protocols.swift) directly from the submodule (with no module import).

If you want to simply download and include the file, then there is only one file to deal with. [The `Sources/RVS_GeneralObserver/RVS_GeneralObserver_Protocols.swift` file.](https://github.com/RiftValleySoftware/RVS_GeneralObserver/blob/master/Sources/RVS_GeneralObserver/RVS_GeneralObserver_Protocols.swift)

Just download and include that one file. No need to import a module.

### Observables

Once that is done, you can make a class (it needs to be a class) Observable, by conforming to the [`RVS_GeneralObservableProtocol`](https://github.com/RiftValleySoftware/RVS_GeneralObserver/blob/5978359d3521f125b565e63767328ceec911a170/Sources/RVS_GeneralObserver/RVS_GeneralObserver_Protocols.swift#L96) protocol.

You will need to create two stored properties in your implementation (the following examples are from [the unit tests](https://github.com/RiftValleySoftware/RVS_GeneralObserver/blob/81f9021fe228f434df4fb17139620a57c7851412/Tests/RVS_GeneralObserverTest/RVS_GeneralObserverTests.swift#L39)):

    class BaseObservable: RVS_GeneralObservableProtocol {
        /* ############################################################## */
        /**
        The required UUID. It is set up with an initializer, and left alone.
        */
        let uuid = UUID()
        
        /* ############################################################## */
        /**
        This is the required observers Array.
        */
        var observers: [RVS_GeneralObserverProtocol] = []

The `uuid` property is a "set and forget" property. Simply do exactly as above, and never worry about it afterwards.

The `observers` Array is also one you're unlikely to use directly (but you'll probably cast it). It is where subscribers are tracked. This is how your observable will find broadcast targets. Normally, you'll probably cast this to an Array of more specific classes, like so:

    var castArray: [MySpecificSubscriberThatConformsToRVS_GeneralObserverProtocol] { observers as? [MySpecificSubscriberThatConformsToRVS_GeneralObserverProtocol] ?? [] }

### Observers

We have two types of Observers. One is a "generic" one, that can be applied to `struct`s and `class`es, that does not track the Observables to which an Observer is subscribed, and the other is a `class`-only variant that tracks an Observer's subscriptions:

These examples are also from the [unit tests](https://github.com/RiftValleySoftware/RVS_GeneralObserver/blob/master/Tests/RVS_GeneralObserverTest/RVS_GeneralObserverTests.swift):

[Standard (`struct` or `class`) Observer](https://github.com/RiftValleySoftware/RVS_GeneralObserver/blob/81f9021fe228f434df4fb17139620a57c7851412/Tests/RVS_GeneralObserverTest/RVS_GeneralObserverTests.swift#L96):

    struct BaseObserver: RVS_GeneralObserverProtocol {
        /* ############################################################## */
        /**
         The required UUID. It is set up with an initializer, and left alone.
         */
        let uuid = UUID()

[`class`-only Subscription-Tracking Observer](https://github.com/RiftValleySoftware/RVS_GeneralObserver/blob/81f9021fe228f434df4fb17139620a57c7851412/Tests/RVS_GeneralObserverTest/RVS_GeneralObserverTests.swift#L196):

    class SubTrackerObserver: RVS_GeneralObserverSubTrackerProtocol {
        /* ############################################################## */
        /**
         The required UUID. It is set up with an initializer, and left alone.
         */
        let uuid = UUID()
        
        /* ############################################################## */
        /**
         This is where we will track our subscriptions.
         */
        var subscriptions: [RVS_GeneralObservableProtocol] = []

Because the protocol default works with an Array of references, this should be a `class`.

Subscribing to an Observable is as simple as calling its [`subscribe()`](https://github.com/RiftValleySoftware/RVS_GeneralObserver/blob/5978359d3521f125b565e63767328ceec911a170/Sources/RVS_GeneralObserver/RVS_GeneralObserver_Protocols.swift#L134) method, with the observer, supplied:

    let subscribedObserver = observableInstance.subscribe(observerInstance)

The response is the `observerInstance`, if the subscription was successful. This allows the method to be chained. It may be nil, if the observer is already subscribed.

Unsubscribing is exactly the same, except that we call the [`unsubscribe()`](https://github.com/RiftValleySoftware/RVS_GeneralObserver/blob/5978359d3521f125b565e63767328ceec911a170/Sources/RVS_GeneralObserver/RVS_GeneralObserver_Protocols.swift#L145) method, this time.

    let unsubscribedObserver = observableInstance.unsubscribe(observerInstance)

There are also `unsubscribeAll()` methods for [the Observable](https://github.com/RiftValleySoftware/RVS_GeneralObserver/blob/5978359d3521f125b565e63767328ceec911a170/Sources/RVS_GeneralObserver/RVS_GeneralObserver_Protocols.swift#L154), and for [the subscription-tracking Observer](https://github.com/RiftValleySoftware/RVS_GeneralObserver/blob/5978359d3521f125b565e63767328ceec911a170/Sources/RVS_GeneralObserver/RVS_GeneralObserver_Protocols.swift#L401).

Calling these will remove every Observer from an Observable instance, or every Observable from an Observer instance.

### Callbacks

There aren't any required callbacks in the protocols, but there are a few, very basic optional ones.

The Observer protocol has callbacks that are made at the time that a subscription is confirmed:

    func subscribedTo(_ observable: RVS_GeneralObservableProtocol)

and when an unsubscription is confirmed:

    func unsubscribedFrom(_ observable: RVS_GeneralObservableProtocol)

The subscription-tracking protocol has [a couple of internal methods](https://github.com/RiftValleySoftware/RVS_GeneralObserver/blob/5978359d3521f125b565e63767328ceec911a170/Sources/RVS_GeneralObserver/RVS_GeneralObserver_Protocols.swift#L366) that aren't supposed to be used by conformant instances.

The Observable protocol has a single optional callback:

    func observer(_ observer: RVS_GeneralObserverProtocol, didSubscribe: Bool)

This is called whenever an Observer subscribes or unsubscribes (the second argument indicates that).

Once you have set up the `class`es (or `struct`s), you can then use the `observers` property (Observable) or the `subscriptions` property (the subcriber-tracking variant of the Observer protocol) to access and interact with the various targets, recasting, as necessary.

All protocols have an `amISubscribed()` Boolean method, where you pass in an Observer (or Observable) instance to be tested to see if an Observer is subscribed to an Observable.

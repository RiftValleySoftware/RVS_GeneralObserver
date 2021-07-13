/**
    © Copyright 2019, The Great Rift Valley Software Company

    Verison: 1.0.4
     
    LICENSE:

    MIT License

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
    files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,
    modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
    OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
    CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

    The Great Rift Valley Software Company: https://riftvalleysoftware.com
*/

import Foundation   // Required for UUIDs

/* ###################################################################################################################################### */
// MARK: - Special Array Extension for Observers -
/* ###################################################################################################################################### */
/**
 This allows us to extract elements from an Array in a fashion similar to a Dictionary.
 
 It isn't particularly efficient, but we're not talking huge Arrays, here.
 */
public extension Array where Element: RVS_GeneralObserverProtocol {
    /* ################################################################## */
    /**
     This allows us to treat an Array like a Dictionary.
     
     - parameter: The UUID String for the element we want.
     - returns: Either the element, or nil.
     */
    subscript(_ inUUIDString: String) -> Element? {
        for elem in self where elem.uuid.uuidString == inUUIDString { return elem }
        return nil
    }
    
    /* ################################################################## */
    /**
     This allows us to treat an Array like a Dictionary.
     
     - parameter: The UUID String for the element we want.
     - returns: Either the element, or nil.
     */
    subscript(_ inUUID: UUID) -> Element? { self[inUUID.uuidString] }
}

/* ###################################################################################################################################### */
// MARK: - Special Array Extension for Observerables -
/* ###################################################################################################################################### */
/**
 This is the same thing, for observables.
 */
public extension Array where Element: RVS_GeneralObservableProtocol {
    /* ################################################################## */
    /**
     This allows us to treat an Array like a Dictionary.
     
     - parameter: The UUID String for the element we want.
     - returns: Either the element, or nil.
     */
    subscript(_ inUUIDString: String) -> Element? {
        for elem in self where elem.uuid.uuidString == inUUIDString { return elem }
        return nil
    }
    
    /* ################################################################## */
    /**
     This allows us to treat an Array like a Dictionary.
     
     - parameter: The UUID String for the element we want.
     - returns: Either the element, or nil.
     */
    subscript(_ inUUID: UUID) -> Element? { self[inUUID.uuidString] }
}

/* ###################################################################################################################################### */
// MARK: - Observable Entity Protocol -
/* ###################################################################################################################################### */
/**
 This protocol makes any entity observable, by giving it the infrastructure to subscribe and track observers. It's up to the implementor to
 actually use this to send messages.
 
 Observables have to be classes. Observers don't need to be classes.
 
 There are two required components: a UUID, which needs to remain constant during the lifetime of the instance, and an Array of observers.
 */
public protocol RVS_GeneralObservableProtocol: AnyObject {
    /* ################################################################################################################################## */
    // MARK: - REQUIRED PROPERTIES
    /* ################################################################################################################################## */
    /* ################################################################## */
    /**
     This is a unique ID for this Observer.
     
     If you are an observer, then you MUST supply a unique ID that remains constant throughout the lifetime of the instance.
     
     It must be declared as a stored property, and initialized with UUID(). After that, leave it alone.
     
     It should look like this, in your implementation:
     
     `let uuid = UUID()`
     */
    var uuid: UUID { get }
    
    /* ################################################################## */
    /**
     This is an Array of observers that subscribe to the observable instance.
     
     It should be noted that this would be a strong reference, if the observers were classes.
     */
    var observers: [RVS_GeneralObserverProtocol] { get set }
    
    /* ################################################################################################################################## */
    // MARK: - OPTIONAL METHODS
    /* ################################################################################################################################## */
    /* ################################################################## */
    /**
     This is how an observer subscribes to an Observable.
     
     - parameter: The observer entity.
     
     - returns: The subscribed element, if the subscription worked (or if the observer is already subscribed). Nil, otherwise. Can be ignored.
     */
    @discardableResult
    func subscribe(_: RVS_GeneralObserverProtocol) -> RVS_GeneralObserverProtocol?
    
    /* ################################################################## */
    /**
     This is how an observer unsubscribes from an Observable.
     
     - parameter: The observer entity.
     
     - returns: The unsubscribed element, if the unsubscription worked (or if the observer is already unsubscribed). Nil, otherwise. Can be ignored.
     */
    @discardableResult
    func unsubscribe(_: RVS_GeneralObserverProtocol) -> RVS_GeneralObserverProtocol?
    
    /* ################################################################## */
    /**
     Unsubscribes all currently subscribed entities.
     
     - returns: The subscribers that were removed. Can be ignored.
     */
    @discardableResult
    func unsubscribeAll() -> [RVS_GeneralObserverProtocol]
    
    /* ################################################################## */
    /**
     An Observer can use this to see if they are already subscribed to an Observable.
     
     In the default implementation, this is called in the subscription/unsubscritption execution context, so that will be the thread used for the callback.
     
     - parameter: The observer entity.
     
     - returns: True, if subscribed.
     */
    func amISubscribed(_: RVS_GeneralObserverProtocol) -> Bool
    
    /* ################################################################################################################################## */
    // MARK: - OPTIONAL CALLBACKS
    /* ################################################################################################################################## */
    /* ################################################################## */
    /**
     This is method that is called when observers subscribe or unsubscribe. The default does nothing.
     This is called AFTER the fact, and only if the subscription status changed.
     
     - parameter: The Observer that subscribed or unsubscribed.
     - parameter didSubscribe: True, if this was a subscription. False, if not.
     */
    func observer(_: RVS_GeneralObserverProtocol, didSubscribe: Bool)
}

/* ###################################################################################################################################### */
// MARK: - Default Implementation -
/* ###################################################################################################################################### */
extension RVS_GeneralObservableProtocol {
    /* ################################################################## */
    /**
     The default will simply append the observer to our list.
     */
    @discardableResult
    public func subscribe(_ inObserver: RVS_GeneralObserverProtocol) -> RVS_GeneralObserverProtocol? {
        guard !amISubscribed(inObserver) else { return nil }
        
        observers.append(inObserver)
        observer(inObserver, didSubscribe: true)
        inObserver.subscribedTo(self)
        // In the special case of this being the subscription tracker, we call its internal management method.
        if let internalSub = inObserver as? RVS_GeneralObserverSubTrackerProtocol {
            internalSub.internalSubscribedTo(self)
        }

        return inObserver
    }
    
    /* ################################################################## */
    /**
     The default will simply remove the observer from our list.
     */
    @discardableResult
    public func unsubscribe(_ inObserver: RVS_GeneralObserverProtocol) -> RVS_GeneralObserverProtocol? {
        for elem in observers.enumerated() where elem.element.uuid == inObserver.uuid {
            observers.remove(at: elem.offset)
            observer(inObserver, didSubscribe: false)
            inObserver.unsubscribedFrom(self)
            // In the special case of this being the subscription tracker, we call its internal management method.
            if let internalSub = inObserver as? RVS_GeneralObserverSubTrackerProtocol {
                internalSub.internalUnsubscribedFrom(self)
            }
            return inObserver
        }
        
        return nil
    }
    
    /* ################################################################## */
    /**
     The default will run through the Array, looking at UUIDs.
     */
    public func amISubscribed(_ inObserver: RVS_GeneralObserverProtocol) -> Bool {
        for elem in observers where elem.uuid == inObserver.uuid { return true }
        
        return false
    }
    
    /* ################################################################## */
    /**
     Default simply unsubscribes all the elements.
     */
    @discardableResult
    public func unsubscribeAll() -> [RVS_GeneralObserverProtocol] { observers.compactMap { unsubscribe($0) } }
    
    /* ################################################################## */
    /**
     The default does nothing.
     */
    public func observer(_: RVS_GeneralObserverProtocol, didSubscribe: Bool) { }
}

/* ###################################################################################################################################### */
// MARK: - The General Observer protocol -
/* ###################################################################################################################################### */
/**
 This protocol allows any entity to become an observer. The only required component is a UUID.
 */
public protocol RVS_GeneralObserverProtocol {
    /* ################################################################################################################################## */
    // MARK: - REQUIRED PROPERTIES
    /* ################################################################################################################################## */
    /* ################################################################## */
    /**
     This is a unique ID for this Observer.
     
     If you are an observer, then you MUST supply a unique ID that remains constant throughout the lifetime of the instance.
     
     It must be declared as a stored property, and initialized with UUID(). After that, leave it alone.
     
     It should look like this, in your implementation:
     
     `let uuid = UUID()`
     */
    var uuid: UUID { get }
    
    /* ################################################################################################################################## */
    // MARK: - OPTIONAL METHODS
    /* ################################################################################################################################## */
    /* ################################################################## */
    /**
     This will tell us whether or not we are subscribed to the given observable.
     
     - parameter: The Observable we're testing.
     */
    func amISubscribed(_: RVS_GeneralObservableProtocol) -> Bool
    
    /* ################################################################## */
    /**
     This is how an observer unsubscribes itself from an Observable.
     
     - parameter: The Observable from which we're unsubscribing.

     - returns: True, if the unsubscription was successful.
     */
    @discardableResult
    func unsubscribeFrom(_: RVS_GeneralObservableProtocol) -> Bool
    
    /* ################################################################## */
    /**
     Subscribes us to an Observable.
     
     - parameter: The Observable we're subscribing to.
     - returns: Our instance, or nil, if the subscription failed. Can be ignored.
     */
    @discardableResult
    func subscribeTo(_ inObservableInstance: RVS_GeneralObservableProtocol) -> RVS_GeneralObserverProtocol?

    /* ################################################################################################################################## */
    // MARK: - OPTIONAL CALLBACKS
    /* ################################################################################################################################## */
    /* ################################################################## */
    /**
     This is called after being subscribed to an Observable.
     
     This is called after the Observable's `observer(_:, didSubscribe:)` method was called.

     In the default implementation, this is called in the subscription execution context, so that will be the thread used for the callback.

     - parameter: The Observable we've subscribed to.
     */
    func subscribedTo(_: RVS_GeneralObservableProtocol)
    
    /* ################################################################## */
    /**
     This is called after being unsubscribed from an Observable.
     
     This is called after the Observable's `observer(_:, didSubscribe:)` method was called.
     
     In the default implementation, this is called in the unsubscription execution context, so that will be the thread used for the callback.

     - parameter: The Observable we've unsubscribed from.
     */
    func unsubscribedFrom(_: RVS_GeneralObservableProtocol)
}

/* ###################################################################################################################################### */
// MARK: - Default Implementation -
/* ###################################################################################################################################### */
extension RVS_GeneralObserverProtocol {
    /* ################################################################## */
    /**
     The default simply asks the observable.
     */
    public func amISubscribed(_ inObservable: RVS_GeneralObservableProtocol) -> Bool { inObservable.amISubscribed(self) }
    
    /* ################################################################## */
    /**
     Default simply unsubscribes itself, using the Observable's method.
     */
    @discardableResult
    public func unsubscribeFrom(_ inObservable: RVS_GeneralObservableProtocol) -> Bool { nil != inObservable.unsubscribe(self) }
    
    /* ################################################################## */
    /**
     Default asks the Observable to sign us up.
     */
    @discardableResult
    public func subscribeTo(_ inObservableInstance: RVS_GeneralObservableProtocol) -> RVS_GeneralObserverProtocol? { inObservableInstance.subscribe(self) }

    /* ################################################################## */
    /**
     Default does nothing.
     */
    public func subscribedTo(_: RVS_GeneralObservableProtocol) { }
    
    /* ################################################################## */
    /**
     Default does nothing.
     */
    public func unsubscribedFrom(_: RVS_GeneralObservableProtocol) { }
}

/* ################################################################################################################################## */
// MARK: - Subscription-Tracking Observer Protocol -
/* ################################################################################################################################## */
/**
 This is a class protocol, so we can mutate the properties in the protocol extension, and we won't have the issue of unlinked references.
 */
public protocol RVS_GeneralObserverSubTrackerProtocol: AnyObject, RVS_GeneralObserverProtocol {
    /* ############################################################## */
    /**
     This is where we will track our subscriptions.
     */
    var subscriptions: [RVS_GeneralObservableProtocol] { get set }
    
    /* ################################################################## */
    /**
     This unsubs the observer from all of its subscriptions.
     
     - returns: An Array, of all the observables it unsubbed from.
     */
    @discardableResult
    func unsubscribeAll() -> [RVS_GeneralObservableProtocol]

    /* ############################################################################################################################## */
    // MARK: - INTERNAL-USE ONLY -
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     This is called after being subscribed to an Observable.
     
     This is a method that is unique to this protocol, and is used for internal management.

     This is called after the Observable's `observer(_:, didSubscribe:)` method was called.

     In the default implementation, this is called in the subscription execution context, so that will be the thread used for the callback.

     - parameter: The Observable we've subscribed to.
     */
    func internalSubscribedTo(_ inObservableInstance: RVS_GeneralObservableProtocol)
    
    /* ################################################################## */
    /**
     This is called after being unsubscribed from an Observable.
     
     This is a method that is unique to this protocol, and is used for internal management.

     This is called after the Observable's `observer(_:, didSubscribe:)` method was called.
     
     In the default implementation, this is called in the unsubscription execution context, so that will be the thread used for the callback.

     - parameter: The Observable we've unsubscribed from.
     */
    func internalUnsubscribedFrom(_ inObservableInstance: RVS_GeneralObservableProtocol)
}

/* ################################################################################################################################## */
// MARK: - Default Implementation -
/* ################################################################################################################################## */
/**
 These need to be defined as public, so that the protocol doesn't force the user to create them. They generally shouldn't be used, though.
 */
extension RVS_GeneralObserverSubTrackerProtocol {
    /* ################################################################## */
    /**
     Default simply adds the observable to our list.
     */
    public func internalSubscribedTo(_ inObservableInstance: RVS_GeneralObservableProtocol) {
        subscriptions.append(inObservableInstance)
    }
    
    /* ################################################################## */
    /**
     Default simply removes the observable from our list.
     */
    public func internalUnsubscribedFrom(_ inObservableInstance: RVS_GeneralObservableProtocol) {
        for elem in subscriptions.enumerated() where elem.element.uuid == inObservableInstance.uuid {
            subscriptions.remove(at: elem.offset)
            break
        }
    }
    
    /* ################################################################## */
    /**
     Default unsubs us from all of our subscriptions.
     */
    @discardableResult
    public func unsubscribeAll() -> [RVS_GeneralObservableProtocol] {
        var ret = [RVS_GeneralObservableProtocol]()
        
        subscriptions.forEach {
            if nil != $0.unsubscribe(self) {
                ret.append($0)
            }
        }
        
        return ret
    }
}

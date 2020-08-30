/*
© Copyright 2020, The Great Rift Valley Software Company

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

import XCTest
@testable import RVS_GeneralObserver

/* ###################################################################################################################################### */
// MARK: -
/* ###################################################################################################################################### */
/**
 */
class RVS_GeneralObserverBasicTests: XCTestCase {
    /* ################################################################################################################################## */
    // MARK: - Simple Observable, With Expectation -
    /* ################################################################################################################################## */
    /**
     This class allows an expectation to be associated, so it can be "ticked off."
     */
    class BaseObservable: RVS_GeneralObservableProtocol, Equatable {
        /* ############################################################## */
        /**
         This allows us to compare instances, via UUIDs.
         
         - parameter lhs: The left-hand-side argument.
         - parameter rhs: The right-hand-side argument.
         - returns: True, if they are equal.
         */
        static func == (lhs: BaseObservable, rhs: BaseObservable) -> Bool { lhs.uuid == rhs.uuid }
        
        /* ############################################################## */
        /**
         This is for our internal testing.
         */
        let uuid = UUID()

        /* ############################################################## */
        /**
         This is the required observers Array.
         */
        var observers: [RVS_GeneralObserverProtocol] = []
        
        /* ############################################################## */
        /**
         This is an expectation for subscriptions that is passed in.
         */
        weak var expectationSubscribe: XCTestExpectation?
        
        /* ############################################################## */
        /**
         This is an expectation for unsubscriptions that is passed in.
         */
        weak var expectationUnsubscribe: XCTestExpectation?

        /* ################################################################## */
        /**
         Called when an observer is either subscribed, or unsubscribed.
         
         - parameter: The Observer that subscribed or unsubscribed.
         - parameter didSubscribe: True, if this was a subscription. False, if not.
         */
        func observer(_ inObserver: RVS_GeneralObserverProtocol, didSubscribe inDidSubscribe: Bool) {
            if inDidSubscribe {
                expectationSubscribe?.fulfill()
            } else {
                expectationUnsubscribe?.fulfill()
            }
        }
    }
    
    /* ################################################################################################################################## */
    // MARK: - Basic Observer (As A Struct) -
    /* ################################################################################################################################## */
    /**
     This simply declares a UUID.
     */
    struct BaseObserver: RVS_GeneralObserverProtocol, Equatable {
        /* ############################################################## */
        /**
         This allows us to compare instances, via UUIDs.
         
         - parameter lhs: The left-hand-side argument.
         - parameter rhs: The right-hand-side argument.
         - returns: True, if they are equal.
         */
        static func == (lhs: Self, rhs: Self) -> Bool { lhs.uuid == rhs.uuid }
        
        /* ############################################################## */
        /**
         The required UUID. It is set up with an initializer, and left alone.
         */
        let uuid = UUID()
    }

    /* ################################################################## */
    /**
     This just subscribes one single observer, and makes sure that its handled properly.
     */
    func testSimpleSingleObserverProtocol() {
        let basicTestExpectationSubscribe = XCTestExpectation()
        let basicTestExpectationUnsubscribe = XCTestExpectation()
        
        basicTestExpectationSubscribe.expectedFulfillmentCount = 1
        basicTestExpectationUnsubscribe.expectedFulfillmentCount = 1

        let observable = BaseObservable()
        observable.expectationSubscribe = basicTestExpectationSubscribe
        observable.expectationUnsubscribe = basicTestExpectationUnsubscribe
        let observer = BaseObserver()
        
        XCTAssertNotNil(observable.subscribe(observer))
        
        XCTAssertEqual(1, observable.observers.count)
        
        XCTAssertTrue(observable.amISubscribed(observer))
        XCTAssertTrue(observer.amISubscribed(observable))

        if  let observers = observable.observers as? [BaseObserver],
            let observerInstance = observers[observer.uuid],
            let observerInstance2 = observers[observer.uuid.uuidString] {
            XCTAssertEqual(observer, observerInstance)
            XCTAssertEqual(observer, observerInstance2)
        } else {
            XCTFail("There was a problem extracting the observer.")
        }
        
        XCTAssertNotNil(observable.unsubscribe(observer))
        
        XCTAssertEqual(0, observable.observers.count)

        wait(for: [basicTestExpectationSubscribe, basicTestExpectationUnsubscribe], timeout: 0.1)
    }
    
    /* ################################################################## */
    /**
     This just subscribes multiple observers, and then unsubs them.
     */
    func testSimpleMultipleObserversProtocol() {
        let basicTestExpectationSubscribe = XCTestExpectation()
        let basicTestExpectationUnsubscribe = XCTestExpectation()
        let numberOfObservers: Int = 10
        
        basicTestExpectationSubscribe.expectedFulfillmentCount = numberOfObservers
        basicTestExpectationUnsubscribe.expectedFulfillmentCount = numberOfObservers

        var observerArray: [BaseObserver] = []
        for _ in 0..<numberOfObservers {
            observerArray.append(BaseObserver())
        }
        
        let observable = BaseObservable()
        observable.expectationSubscribe = basicTestExpectationSubscribe
        observable.expectationUnsubscribe = basicTestExpectationUnsubscribe
        
        for observer in observerArray { XCTAssertNotNil(observable.subscribe(observer)) }
        XCTAssertEqual(numberOfObservers, observable.observers.count)

        wait(for: [basicTestExpectationSubscribe], timeout: 0.1)
        
        observerArray.forEach { XCTAssertTrue(observable.amISubscribed($0)) }
        observable.observers.forEach { XCTAssertTrue($0.amISubscribed(observable)) }

        for observer in observerArray { XCTAssertNotNil(observable.unsubscribe(observer)) }
        XCTAssertEqual(0, observable.observers.count)
        for observer in observerArray { XCTAssertFalse(observable.amISubscribed(observer)) }

        wait(for: [basicTestExpectationUnsubscribe], timeout: 0.1)
    }
    
    /* ################################################################################################################################## */
    // MARK: - Subscription-Tracking Observer (As A Struct) -
    /* ################################################################################################################################## */
    /**
     This is a class (not a struct), so we can deal with it as references.
     */
    class SubTrackerObserver: RVS_GeneralObserverProtocol {
        /* ############################################################## */
        /**
         The required UUID. It is set up with an initializer, and left alone.
         */
        let uuid = UUID()
        
        /* ############################################################## */
        /**
         This is where we will track our subscriptions.
         */
        var subscriptions: [BaseObservable] = []

        /* ################################################################## */
        /**
         This is called after being subscribed to an Observable.
         
         This is called after the Observable's `observer(_:, didSubscribe:)` method was called.

         In the default implementation, this is called in the subscription execution context, so that will be the thread used for the callback.

         - parameter: The Observable we've subscribed to.
         */
        func subscribedTo(_ inObservableInstance: RVS_GeneralObservableProtocol) {
            if let inputObservable = inObservableInstance as? BaseObservable {
                subscriptions.append(inputObservable)
            }
        }
        
        /* ################################################################## */
        /**
         This is called after being unsubscribed from an Observable.
         
         This is called after the Observable's `observer(_:, didSubscribe:)` method was called.
         
         In the default implementation, this is called in the unsubscription execution context, so that will be the thread used for the callback.

         - parameter: The Observable we've unsubscribed from.
         */
        func unsubscribedFrom(_ inObservableInstance: RVS_GeneralObservableProtocol) {
            if let inputObservable = inObservableInstance as? BaseObservable {
                for elem in subscriptions.enumerated() where elem.element == inputObservable {
                    subscriptions.remove(at: elem.offset)
                    break
                }
            }
        }
        
        /* ################################################################## */
        /**
         This unsubs the observer from all of its subscriptions.
         
         - returns: An Array, of all the observables it unsubbed from.
         */
        @discardableResult
        func unsubscribeAll() -> [RVS_GeneralObservableProtocol] {
            var ret = [RVS_GeneralObservableProtocol]()
            
            subscriptions.forEach {
                if nil != $0.unsubscribe(self) {
                    ret.append($0)
                }
            }
            
            return ret
        }
    }
    
    /* ################################################################## */
    /**
     This test has a matrix of subscribers and observables that we load and drain.
     
     This tests a particular use case (where we test a concrete implementation of a subscription tracker), as well as the tool, itself.
     
     What we will do here, is set up ten observables, then subscribe ten observers to each, so that each observer has ten observables, and each observables has ten subscribers.
     
     We will then unsub all on the first and last observable, so that each of the ten observers is now observing eight observables, but the middle observables still all have ten subscribers.
     */
    func testSubscriberTrackedObservablesAndObservers() {
        let numberOfObservers: Int = 10
        let numberOfObservables: Int = 10
        
        var observables: [BaseObservable] = []
        var observers: [SubTrackerObserver] = []
        
        for _ in 0..<numberOfObservers {
            observers.append(SubTrackerObserver())
        }

        for _ in 0..<numberOfObservables {
            observables.append(BaseObservable())
            observers.forEach { observables.last?.subscribe($0) }
        }
        
        observables.forEach { observable in
            observers.forEach { observer in
                XCTAssertTrue(observer.amISubscribed(observable))
                XCTAssertTrue(observable.amISubscribed(observer))
            }
        }
        
        observers.forEach { observer in
            observer.subscriptions.forEach { observable in
                XCTAssertTrue(observer.amISubscribed(observable))
                XCTAssertTrue(observable.amISubscribed(observer))
            }
        }
        
        let unsubbedObservers = observables.last?.unsubscribeAll()
        
        for index in 0..<(observers.count - 1) {
            XCTAssertEqual(unsubbedObservers?[index].uuid, observers[index].uuid)
        }
        
        if let observable = observables.last {
            observers.forEach { observer in
                XCTAssertFalse(observer.amISubscribed(observable))
                XCTAssertFalse(observable.amISubscribed(observer))
            }
        } else {
            XCTFail("Test Has A Bad Problem")
        }
        
        observables.first?.unsubscribeAll()
        
        for index in 1..<(observers.count - 1) {
            XCTAssertEqual(unsubbedObservers?[index].uuid, observers[index].uuid)
        }

        if let observable = observables.first {
            observers.forEach { observer in
                XCTAssertFalse(observer.amISubscribed(observable))
                XCTAssertFalse(observable.amISubscribed(observer))
            }
        } else {
            XCTFail("Test Has A Bad Problem")
        }

        // Make sure we didn't leave any dingleberries.
        observers.forEach { observer in
            if 0 < observer.subscriptions.count {
                XCTAssertEqual((numberOfObservables - 2), observer.subscriptions.count)
            }
            observer.subscriptions.forEach { observable in
                XCTAssertTrue(observer.amISubscribed(observable))
                XCTAssertTrue(observable.amISubscribed(observer))
            }
        }
        
        var nonSubscribedCount = 0
        
        observables.forEach { observable in
            if 0 < observable.observers.count {
                XCTAssertEqual(numberOfObservers, observable.observers.count)
            } else {
                nonSubscribedCount += 1
            }
            observable.observers.forEach { observer in
                XCTAssertTrue(observer.amISubscribed(observable))
                XCTAssertTrue(observable.amISubscribed(observer))
            }
        }
        
        XCTAssertEqual(2, nonSubscribedCount)
        
        XCTAssertEqual(0, observables.first?.observers.count)
        XCTAssertEqual(0, observables.last?.observers.count)
    }
    
    /* ################################################################## */
    /**
     This will be the same as the `testSubscriberTrackedObservablesAndObservers()` method, but this time, we will work with the observers.
     */
    func testSubscriberTrackedObservablesAndObserversPartDeux() {
        let numberOfObservers: Int = 10
        let numberOfObservables: Int = 10
        
        var observables: [BaseObservable] = []
        var observers: [SubTrackerObserver] = []
        
        for _ in 0..<numberOfObservers {
            observers.append(SubTrackerObserver())
        }

        for _ in 0..<numberOfObservables {
            observables.append(BaseObservable())
            observers.forEach { observables.last?.subscribe($0) }
        }
        
        let unsubbedObservables = observers.first?.unsubscribeAll()
        
        for index in 0..<(observables.count - 1) {
            XCTAssertEqual(observables[index], unsubbedObservables?[index] as? BaseObservable)
        }

        observers.last?.unsubscribeAll()
        
        for index in 1..<(observables.count - 1) {
            XCTAssertEqual(observables[index], unsubbedObservables?[index] as? BaseObservable)
        }
        
        XCTAssertEqual(0, observers.first?.subscriptions.count)
        XCTAssertEqual(0, observers.last?.subscriptions.count)
    }
}

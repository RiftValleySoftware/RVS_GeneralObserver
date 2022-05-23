/*
© Copyright 2021-2022, The Great Rift Valley Software Company

Verison: 1.0.9

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
// MARK: - General Observable and Observer Tests.
/* ###################################################################################################################################### */
/**
 These tests are designed to give a fairly basic stressing of the mechanics of subscription management, in the General Observer Infrastructure.
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
         The required UUID. It is set up with an initializer, and left alone.
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
        
        // This also tests the subscribeTo method.
        for observer in observerArray { XCTAssertNotNil(observer.subscribeTo(observable)) }
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
    // MARK: - Specialized Subscription-Tracking Observer (As A Class) -
    /* ################################################################################################################################## */
    /**
     This simply declares a UUID.
     */
    class SubTrackerObserver: RVS_GeneralObserverSubTrackerProtocol {
        /* ############################################################## */
        /**
         The required UUID. It is set up with an initializer, and left alone.
         */
        let uuid = UUID()
        
        /* ############################################################## */
        /**
         This is where we will track our subscriptions. It is required.
         */
        var subscriptions: [RVS_GeneralObservableProtocol] = []
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
        
        var observables: [RVS_GeneralObservableProtocol] = []
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
        
        observables.forEach { observable in
            if 0 < observable.observers.count {
                XCTAssertEqual(numberOfObservers, observable.observers.count)
            } else {
                nonSubscribedCount += 1
            }
            observable.observers.forEach { observer in
                XCTAssertTrue(observer.unsubscribeFrom(observable))
                XCTAssertFalse(observer.amISubscribed(observable))
                XCTAssertFalse(observable.amISubscribed(observer))
            }
        }
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
        
        if  !observables.isEmpty {
            if let unsubbedObservables = observers.first?.unsubscribeAll() {
                XCTAssertEqual(numberOfObservables, unsubbedObservables.count)
                for index in 0..<(observables.count - 1) {
                    XCTAssertEqual(observables[index], unsubbedObservables[index] as? BaseObservable)
                }

                if let unsubbedTwo = observers.last?.unsubscribeAll() {
                    observers.forEach {
                        if !$0.subscriptions.isEmpty {
                            XCTAssertEqual(numberOfObservers, $0.subscriptions.count)
                        }
                    }
                    
                    observables.forEach {
                        if !$0.observers.isEmpty {
                            XCTAssertEqual(numberOfObservers - 2, $0.observers.count)
                        }
                    }
                    
                    XCTAssertEqual(numberOfObservables, unsubbedTwo.count)
                    XCTAssertEqual(0, observers.first?.subscriptions.count)
                    XCTAssertEqual(0, observers.last?.subscriptions.count)
                    XCTAssertEqual(numberOfObservers, observers[1].subscriptions.count)
                    XCTAssertEqual(numberOfObservers, observers[observers.count - 2].subscriptions.count)
                } else {
                    XCTFail("Nil response from unsub.")
                }
                
                for index in 1..<(observables.count - 1) {
                    XCTAssertEqual(observables[index], unsubbedObservables[index] as? BaseObservable)
                }
            } else {
                XCTFail("Nil response from unsub.")
            }
        } else {
            XCTFail("Test Has A Bad Problem")
        }
        
        XCTAssertEqual(0, observers.first?.subscriptions.count)
        XCTAssertEqual(0, observers.last?.subscriptions.count)
    }
    
    /* ################################################################## */
    /**
     This runs some basic tests on our "treat an Array like a Dictionary" extensions.
     */
    func testArrayExtensions() {
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
        
        let randomIndex = Int.random(in: 0..<numberOfObservables)
        
        let randomObservable = observables[randomIndex]
        let randomObservableUUID = randomObservable.uuid
        let randomObservableUUIDString = randomObservableUUID.uuidString
        
        if let observableFromUUID = observables[randomObservableUUID] {
            XCTAssertEqual(randomObservableUUID, observableFromUUID.uuid)
            XCTAssertEqual(randomObservableUUIDString, observableFromUUID.uuid.uuidString)
        }
        
        let randomObserver = observers[randomIndex]
        let randomObserverUUID = randomObserver.uuid
        let randomObserverUUIDString = randomObserverUUID.uuidString
        
        if let observableFromUUID = observables[randomObserverUUID] {
            XCTAssertEqual(randomObserverUUID, observableFromUUID.uuid)
            XCTAssertEqual(randomObserverUUIDString, observableFromUUID.uuid.uuidString)
        }
        
        XCTAssertNil(observers["HIHOWAYA"])
        XCTAssertNil(observables["HIHOWAYA"])
    }
    
    /* ################################################################## */
    /**
     We test the protocol defaults (for code coverage).
     */
    func testProtocolDefault() {
        class EmptyObservable: RVS_GeneralObservableProtocol {
            var uuid: UUID = UUID()
            var observers: [RVS_GeneralObserverProtocol] = []
        }
        
        class EmptyObserver: RVS_GeneralObserverProtocol {
            var uuid: UUID = UUID()
        }
        
        let observable = EmptyObservable()
        
        let observer = EmptyObserver()
        
        observable.subscribe(observer)
        
        XCTAssertTrue(observer.amISubscribed(observable))
        XCTAssertTrue(observable.amISubscribed(observer))
    }
}

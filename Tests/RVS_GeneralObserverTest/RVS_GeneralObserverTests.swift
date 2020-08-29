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
class RVS_GoTennaDriverTests: XCTestCase {
    /* ################################################################################################################################## */
    // MARK: - Simple Observable, With Expectation -
    /* ################################################################################################################################## */
    /**
     This class allows an expectation to be associated, so it can be "ticked off."
     */
    class BaseObservable: RVS_GeneralObservableProtocol {
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
        static func == (lhs: Self, rhs: Self) -> Bool { lhs.uuid == rhs.uuid }
        
        /* ############################################################## */
        /**
         The required UUID. It is set up with an initializer, and left alone.
         */
        let uuid = UUID()
        
        /* ################################################################## */
        /**
         This will hold the subcriptions we have to Observables.
         */
        var subscriptions: [RVS_GeneralObservableProtocol] = []
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
}

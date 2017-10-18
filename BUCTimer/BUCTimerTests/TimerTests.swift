//
//  TimerTests.swift
//  BUCTimerTests
//
//  Created by Buckley on 4/24/15.
//  Copyright (c) 2015 Buckleyisms. All rights reserved.
//

import XCTest
import BUCTimer

class TimerTests: XCTestCase {

    func testStart() {
        var timesCalled = 0
        let expectation = self.expectation(description: "timer was called")
        let timeStarted = Date()
        var timeFired: Date? = nil

        let timer = Timer(milliseconds: 100, repeats: 0, queue: .main, {
            timer in

            timeFired = Date()
            timesCalled += 1
            expectation.fulfill()
        })

        XCTAssertNotNil(timer, "timer is nil")
        XCTAssertTrue(timer!.start(), "timer failed to start")

        self.waitForExpectations(timeout: 1.0, handler: nil)

        XCTAssertEqual(timesCalled, 1, "timer didn't fire")
        XCTAssertNotNil(timeFired, "timeFired is nil")
        XCTAssertEqual(timer!.state, TimerState.Stopped, "timer is still running")
        XCTAssertEqual(
            timeFired!.timeIntervalSince(timeStarted),
            0.1,
            accuracy: 0.05,
            "timer called at wrong time"
        )
    }

    func testMultipleStarts() {
        var timesCalled = 0
        let expectation = self.expectation(description: "timer was called")

        let timer = Timer(milliseconds: 200, repeats: 0, queue: .main, {
            timer in

            timesCalled += 1
            expectation.fulfill()
        })

        XCTAssertNotNil(timer, "timer is nil")
        XCTAssertTrue(timer!.start(), "timer failed to start")
        XCTAssertFalse(timer!.start(), "start() successfully called twice in a row")

        self.waitForExpectations(timeout: 1.0, handler: nil)

        XCTAssertEqual(timesCalled, 1, "timer didn't fire")
        XCTAssertEqual(timer!.state, TimerState.Stopped, "timer is still running")
    }

    func testMultipleTimers() {
        let expectation1 = self.expectation(description: "timer1 was called")
        let expectation2 = self.expectation(description: "timer2 was called")
        let expectation3 = self.expectation(description: "timer3 was called")

        let timer1 = Timer(milliseconds: 100, repeats: 0, queue: .main, {
            timer in

            expectation1.fulfill()
        })

        let timer2 = Timer(milliseconds: 150, repeats: 0, queue: .main, {
            timer in

            XCTAssertEqual(timer1!.state, TimerState.Stopped, "timer1 is still running")
            expectation2.fulfill()
        })

        let timer3 = Timer(milliseconds: 200,  repeats: 0, queue: .main, {
            timer in

            XCTAssertEqual(timer1!.state, TimerState.Stopped, "timer1 is still running")
            XCTAssertEqual(timer2!.state, TimerState.Stopped, "timer2 is still running")
            expectation3.fulfill()
        })

        XCTAssertNotNil(timer1, "timer1 is nil")
        XCTAssertNotNil(timer2, "timer2 is nil")
        XCTAssertNotNil(timer3, "timer3 is nil")

        XCTAssertTrue(timer1!.start(), "timer1 failed to start")
        XCTAssertTrue(timer2!.start(), "timer2 failed to start")
        XCTAssertTrue(timer3!.start(), "timer3 failed to start")

        self.waitForExpectations(timeout: 1.0, handler: nil)

        XCTAssertEqual(timer1!.state, TimerState.Stopped, "timer1 is still running")
        XCTAssertEqual(timer2!.state, TimerState.Stopped, "timer2 is still running")
        XCTAssertEqual(timer3!.state, TimerState.Stopped, "timer3 is still running")
    }

    func testRepeat() {
        var timesCalled = 0
        let expectation = self.expectation(description: "timer was called")

        let timer = Timer(milliseconds: 100, repeats: 3, queue: .main, {
            timer in

            timesCalled += 1

            if timesCalled == 3 {
                expectation.fulfill()
            }
        })

        XCTAssertNotNil(timer, "timer is nil")
        XCTAssertTrue(timer!.start(), "timer failed to start")

        self.waitForExpectations(timeout: 1.0, handler: nil)

        XCTAssertEqual(timesCalled, 3, "timer didn't fire enough times")
        XCTAssertEqual(timer!.state, TimerState.Stopped, "timer is still running")
    }

    func testRepeatIndefinitely() {
        var timesCalled = 0
        let expectation = self.expectation(description: "timer was called")

        let timer = Timer(milliseconds: 100, repeats: -1, queue: .main, {
            timer in

            timesCalled += 1

            if timesCalled == 3 {
                timer.stop()
                expectation.fulfill()
            }
        })

        XCTAssertNotNil(timer, "timer is nil")
        XCTAssertTrue(timer!.start(), "timer failed to start")

        self.waitForExpectations(timeout: 1.0, handler: nil)

        XCTAssertEqual(timesCalled, 3, "timer didn't fire enough times")
        XCTAssertEqual(timer!.state, TimerState.Stopped, "timer is still running")
    }

    func testPause() {
        var timesCalled = 0
        let expectation = self.expectation(description: "timer was called")
        let timeStarted = Date()
        var timeFired: Date? = nil

        let timer = Timer(seconds: 4, repeats: 0, queue: .main, {
            timer in

            timeFired = Date()
            timesCalled += 1
            expectation.fulfill()
        })

        XCTAssertNotNil(timer, "timer is nil")
        XCTAssertTrue(timer!.start(), "timer failed to start")
        sleep(1)

        XCTAssertTrue(timer!.pause(), "timer failed to pause")
        sleep(1)

        XCTAssertFalse(timer!.pause(), "timer paused when already paused")
        XCTAssertTrue(timer!.start(), "timer failed to start")
        sleep(1)

        XCTAssertTrue(timer!.pause(), "timer failed to pause")
        sleep(1)

        XCTAssertTrue(timer!.start(), "timer failed to start")

        self.waitForExpectations(timeout: 10.0, handler: nil)

        XCTAssertEqual(timesCalled, 1, "timer didn't fire")
        XCTAssertNotNil(timeFired, "timeFired is nil")
        XCTAssertEqual(timer!.state, TimerState.Stopped, "timer is still running")
        XCTAssertEqual(
            timeFired!.timeIntervalSince(timeStarted),
            6.0,
            accuracy: 0.1,
            "timer called at wrong time"
        )
    }

    func testStop() {
        var timesCalled = 0;

        let timer = Timer(seconds: 1, repeats: 0, queue: .main, {
            timer in

            timesCalled += 1
        })

        XCTAssertNotNil(timer, "timer is nil")
        XCTAssertTrue(timer!.start(), "timer failed to start")

        XCTAssertEqual(timer!.state, TimerState.Running, "timer is not running")

        timer!.stop()

        RunLoop.main.run(until: Date() + 2.0)

        XCTAssertEqual(timesCalled, 0, "timer fired after stopping")
        XCTAssertEqual(timer!.state, TimerState.Stopped, "timer is still running")
    }

    func testARC() {
        var timesCalled = 0
        let expectation = self.expectation(description: "timer was called")
        
        let timer = Timer(seconds: 1, repeats: 0, queue: .main, {
            timer in

            timesCalled += 1
            expectation.fulfill()
        })

        XCTAssertNotNil(timer, "timer is nil")
        XCTAssertTrue(timer!.start(), "timer failed to start")
        
        // Don't reference timer below this point. ARC should release it here,
        // but it won't be deallocated until it finishes.
        
        self.waitForExpectations(timeout: 2.0, handler: nil)
        
        XCTAssertEqual(timesCalled, 1, "timer didn't fire")
        
    }
    
}

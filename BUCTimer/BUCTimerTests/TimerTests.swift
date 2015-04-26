//
//  TimerTests.swift
//  TimerTests
//
//  Created by Buckley on 4/24/15.
//  Copyright (c) 2015 Buckleyisms. All rights reserved.
//

import XCTest
import BUCTimer

class TimerTests: XCTestCase {

    func testStart()
    {
        var timesCalled = 0
        let expectation = self.expectationWithDescription("timer was called")
        let timeStarted = NSDate()
        var timeFired: NSDate? = nil

        let timer = Timer(milliseconds: 100, repeat: 0, queue: dispatch_get_main_queue(),
        {
            timer in

            timeFired = NSDate()
            ++timesCalled
            expectation.fulfill()
        })

        XCTAssertNotNil(timer, "timer is nil")
        XCTAssertTrue(timer!.start(), "timer failed to start")

        self.waitForExpectationsWithTimeout(1.0, handler: nil)

        XCTAssertEqual(timesCalled, 1, "timer didn't fire")
        XCTAssertNotNil(timeFired, "timeFired is nil")
        XCTAssertEqual(timer!.state, TimerState.Stopped, "timer is still running")
        XCTAssertEqualWithAccuracy(
            timeFired!.timeIntervalSinceDate(timeStarted),
            0.1,
            0.05,
            "timer called at wrong time"
        )
    }

    func testMultipleStarts()
    {
        var timesCalled = 0
        let expectation = self.expectationWithDescription("timer was called")

        let timer = Timer(milliseconds: 200, repeat: 0, queue: dispatch_get_main_queue(),
        {
            timer in

            ++timesCalled
            expectation.fulfill()
        })

        XCTAssertNotNil(timer, "timer is nil")
        XCTAssertTrue(timer!.start(), "timer failed to start")
        XCTAssertFalse(timer!.start(), "start() successfully called twice in a row")

        self.waitForExpectationsWithTimeout(1.0, handler: nil)

        XCTAssertEqual(timesCalled, 1, "timer didn't fire")
        XCTAssertEqual(timer!.state, TimerState.Stopped, "timer is still running")
    }

    func testMultipleTimers()
    {
        let expectation1 = self.expectationWithDescription("timer1 was called")
        let expectation2 = self.expectationWithDescription("timer2 was called")
        let expectation3 = self.expectationWithDescription("timer3 was called")

        let timer1 = Timer(milliseconds: 100, repeat: 0, queue: dispatch_get_main_queue(),
        {
            timer in

            expectation1.fulfill()
        })

        let timer2 = Timer(milliseconds: 150, repeat: 0, queue: dispatch_get_main_queue(),
        {
            timer in

            XCTAssertEqual(timer1!.state, TimerState.Stopped, "timer1 is still running")
            expectation2.fulfill()
        })

        let timer3 = Timer(milliseconds: 200, repeat: 0, queue: dispatch_get_main_queue(),
        {
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

        self.waitForExpectationsWithTimeout(1.0, handler: nil)

        XCTAssertEqual(timer1!.state, TimerState.Stopped, "timer1 is still running")
        XCTAssertEqual(timer2!.state, TimerState.Stopped, "timer2 is still running")
        XCTAssertEqual(timer3!.state, TimerState.Stopped, "timer3 is still running")
    }

    func testRepeat()
    {
        var timesCalled = 0
        let expectation = self.expectationWithDescription("timer was called")

        let timer = Timer(milliseconds: 100, repeat: 3, queue: dispatch_get_main_queue(),
        {
            timer in

            ++timesCalled

            if timesCalled == 3
            {
                expectation.fulfill()
            }
        })

        XCTAssertNotNil(timer, "timer is nil")
        XCTAssertTrue(timer!.start(), "timer failed to start")

        self.waitForExpectationsWithTimeout(1.0, handler: nil)

        XCTAssertEqual(timesCalled, 3, "timer didn't fire enough times")
        XCTAssertEqual(timer!.state, TimerState.Stopped, "timer is still running")
    }

    func testRepeatIndefinitely()
    {
        var timesCalled = 0
        let expectation = self.expectationWithDescription("timer was called")

        let timer = Timer(milliseconds: 100, repeat: -1, queue: dispatch_get_main_queue(),
        {
            timer in

            ++timesCalled

            if timesCalled == 3
            {
                timer.stop()
                expectation.fulfill()
            }
        })

        XCTAssertNotNil(timer, "timer is nil")
        XCTAssertTrue(timer!.start(), "timer failed to start")

        self.waitForExpectationsWithTimeout(1.0, handler: nil)

        XCTAssertEqual(timesCalled, 3, "timer didn't fire enough times")
        XCTAssertEqual(timer!.state, TimerState.Stopped, "timer is still running")
    }

    func testPause()
    {
        var timesCalled = 0
        let expectation = self.expectationWithDescription("timer was called")
        let timeStarted = NSDate()
        var timeFired: NSDate? = nil

        let timer = Timer(seconds: 4, repeat: 0, queue: dispatch_get_main_queue(),
        {
            timer in

            timeFired = NSDate()
            ++timesCalled
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

        self.waitForExpectationsWithTimeout(10.0, handler: nil)

        XCTAssertEqual(timesCalled, 1, "timer didn't fire")
        XCTAssertNotNil(timeFired, "timeFired is nil")
        XCTAssertEqual(timer!.state, TimerState.Stopped, "timer is still running")
        XCTAssertEqualWithAccuracy(
            timeFired!.timeIntervalSinceDate(timeStarted),
            6.0,
            0.1,
            "timer called at wrong time"
        )
    }

    func testStop()
    {
        var timesCalled = 0;

        let timer = Timer(seconds: 1, repeat: 0, queue: dispatch_get_main_queue(),
        {
            timer in

            ++timesCalled
        })

        XCTAssertNotNil(timer, "timer is nil")
        XCTAssertTrue(timer!.start(), "timer failed to start")

        XCTAssertEqual(timer!.state, TimerState.Running, "timer is not running")

        timer!.stop()

        NSRunLoop.mainRunLoop().runUntilDate(NSDate().dateByAddingTimeInterval(2.0))

        XCTAssertEqual(timesCalled, 0, "timer fired after stopping")
        XCTAssertEqual(timer!.state, TimerState.Stopped, "timer is still running")
    }

    func testARC()
    {
        var timesCalled = 0
        let expectation = self.expectationWithDescription("timer was called")

        let timer = Timer(seconds: 1, repeat: 0, queue: dispatch_get_main_queue(),
        {
            timer in

            ++timesCalled
            expectation.fulfill()
        })

        XCTAssertNotNil(timer, "timer is nil")
        XCTAssertTrue(timer!.start(), "timer failed to start")

        // Don't reference timer below this point. ARC should release it here,
        // but it won't be deallocated until it finishes.

        self.waitForExpectationsWithTimeout(2.0, handler: nil)

        XCTAssertEqual(timesCalled, 1, "timer didn't fire")
        
    }
    
}

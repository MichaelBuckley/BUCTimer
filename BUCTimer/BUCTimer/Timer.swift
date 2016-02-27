//
//  Timer.swift
//  BUCTimer
//
//  Created by Buckley on 4/24/15.
//  Copyright (c) 2015 Buckleyisms. All rights reserved.
//

import Foundation

private let nanosecondsPerMillisecond: UInt64 = 1000000
private let nanosecondsPerSecond: UInt64 = 1000000000

private let globalTimerQueue = dispatch_queue_create("com.buckleyisms.Timer", DISPATCH_QUEUE_SERIAL)

private var runningTimers = Set<Timer>()

/// This enum represents the current state of a timer. There are three possible states.
///
/// - Stopped: The timer is currently stopped. The timer may transition to the Running state.
/// - Running: The timer is currently running. The timer may transition to the Paused and Stopped states.
/// - Paused: The timer is currently paused. The timer may transition to the Running and Stopped states.

public enum TimerState {
    /// The timer is currently stopped. The timer may transition to the Running state.
    case Stopped
    /// The timer is currently running. The timer may transition to the Paused and Stopped states.
    case Running
    /// The timer is currently paused. The timer may transition to the Running and Stopped states.
    case Paused
}

/// This class implements a timer using GCD timer dispatch sources. It can be used from any thread, and allows the user
/// To specify which queue the timer will execute the completion handler on.
///
/// Users do not need to keep strong references to the timers they create. Timers will not be deallocated until they
/// have been stopped. Timers are passed into completion handlers so that users may stop them from within the handler.

public class Timer : Hashable {
    private var timer: dispatch_source_t? = nil
    private let interval: UInt64
    private let reptitions: Int64
    private let queue: dispatch_queue_t
    private let completion: (Timer) -> ()

    private var _state: TimerState = TimerState.Stopped
    private var timerStartedAt: NSDate? = nil
    private var pauseInterval: Int64 = 0

    public var hashValue: Int {
        get {
            return Int(self.interval)
        }
    }

    /// The current state of the timer. The timer begins in the Stopped state.

    public var state: TimerState {
        get {
            var stateToReturn = TimerState.Stopped

            dispatch_sync(globalTimerQueue, {
                stateToReturn = self._state
            })

            return stateToReturn
        }
    }

    /// Initializes a timer, but does not start it.
    ///
    /// This initializer will fail if the interval is greater than INT64_MAX (9223372036854775807) nanoseconds
    ///
    /// - parameter nanoseconds: The timer's interval in nanoseconds.
    /// - parameter repeats: The number of times the timer will fire. Passing 0 will cause the timer to fire just once,
    /// and passing a negative number will cause the timer to repeatedly fire until explicitly stopped.
    /// - parameter queue: The queue on which to run the completion handler when the timer fires
    /// - parameter completion: A closure to run each time the timer fires. This timer is passed in as the closure's single
    /// parameter so that the timer may be stopped or paused from within the closure.

    public init?(nanoseconds: UInt64, repeats: Int64, queue: dispatch_queue_t, _ completion: (Timer) -> ()) {
        self.interval = nanoseconds
        self.reptitions = repeats
        self.queue = queue
        self.completion = completion

        if nanoseconds > UInt64(INT64_MAX) {
            return nil
        }
    }

    /// Initializes a timer, but does not start it.
    ///
    /// This initializer will fail if the interval is greater than 9223372036854 milliseconds
    ///
    /// - parameter milliseconds: The timer's interval in milliseconds.
    /// - parameter repeats: The number of times the timer will fire. Passing 0 will cause the timer to fire just once,
    /// and passing a negative number will cause the timer to repeatedly fire until explicitly stopped.
    /// - parameter queue: The queue on which to run the completion handler when the timer fires
    /// - parameter completion: A closure to run each time the timer fires. This timer is passed in as the closure's single
    /// parameter so that the timer may be stopped or paused from within the closure.

    public convenience init?(milliseconds: UInt64, repeats: Int64, queue: dispatch_queue_t, _ completion: (Timer) -> ()) {
        self.init(nanoseconds: milliseconds * nanosecondsPerMillisecond, repeats: repeats, queue: queue, completion)
    }

    /// Initializes a timer, but does not start it.
    ///
    /// This initializer will fail if the interval is greater than 9223372036 seconds
    ///
    /// - parameter seconds: The timer's interval in seconds.
    /// - parameter repeats: The number of times the timer will fire. Passing 0 will cause the timer to fire just once,
    /// and passing a negative number will cause the timer to repeatedly fire until explicitly stopped.
    /// - parameter queue: The queue on which to run the completion handler when the timer fires
    /// - parameter completion: A closure to run each time the timer fires. This timer is passed in as the closure's single
    /// parameter so that the timer may be stopped or paused from within the closure.

    public convenience init?(seconds: UInt64, repeats: Int64, queue: dispatch_queue_t, _ completion: (Timer) -> ()) {
        self.init(nanoseconds: seconds * nanosecondsPerSecond, repeats: repeats, queue: queue, completion)
    }

    deinit {
        cancel()
    }

    /// Starts the timer.
    ///
    /// If the timer is paused, this method will resume the timer from where it was paused. if the timer is already
    /// running, this method does nothing.
    ///
    /// - returns: true if called when the timer is stopped or paused, false if called when the timer is already running

    public func start() -> Bool {
        var started = false

        dispatch_sync(globalTimerQueue, {
            if self._state != TimerState.Running {
                var remaining = self.reptitions

                self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, globalTimerQueue)

                if let timer = self.timer {
                    dispatch_source_set_timer(
                        timer,
                        dispatch_time(DISPATCH_TIME_NOW, Int64(self.interval) - self.pauseInterval),
                        self.interval,
                        0
                    )

                    dispatch_source_set_event_handler(timer, {
                        if self._state == TimerState.Running {
                            if remaining > 0 {
                                --remaining;
                            }

                            if remaining == 0 {
                                self.cancel()
                                self.reset()
                            }

                            self.pauseInterval = 0
                            self.timerStartedAt = NSDate()

                            dispatch_async(self.queue, { self.completion(self)})
                        }
                    })

                    runningTimers.insert(self)

                    self.timerStartedAt = NSDate()

                    self._state = TimerState.Running
                    started = true

                    dispatch_resume(timer)
                }
            }
        })

        return started
    }

    /// Stops the timer.
    ///
    /// This method resets the timer, even if it is paused.
    ///
    /// If this method is called while the timer is in the process of firing, the timer will not stop until after it has
    /// fired.

    public func stop() {
        dispatch_sync(globalTimerQueue, {
            self.cancel()
            self.reset()
        })
    }

    /// Pauses the timer.
    ///
    /// This method does nothing if the timer is stopped or paused
    ///
    /// If this method is called while the timer is in the process of firing, the timer will not pause until after it
    /// has fired.
    ///
    /// - returns: true if the timer was running when this method was called, false otherwise

    public func pause() -> Bool {
        var paused = false

        dispatch_sync(globalTimerQueue, {
            if self._state == TimerState.Running {
                if let timerStartedAt = self.timerStartedAt {
                    let timeSinceStart = Int64(
                        NSDate().timeIntervalSinceDate(timerStartedAt) * NSTimeInterval(nanosecondsPerSecond)
                    )

                    self.pauseInterval += timeSinceStart
                }

                self.cancel()
                self._state = TimerState.Paused
                paused = true
            }
        })

        return paused
    }

    private func cancel() {
        if self._state == TimerState.Running {
            if let timer = self.timer {
                dispatch_source_cancel(timer)
            }

            runningTimers.remove(self)
        }
    }

    private func reset() {
        self._state = TimerState.Stopped
        self.timerStartedAt = nil
        self.pauseInterval = 0
    }
}

public func == (lhs: Timer, rhs: Timer) -> Bool {
    return lhs === rhs
}
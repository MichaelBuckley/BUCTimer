//
//  File.swift
//  Timer
//
//  Created by Buckley on 4/24/15.
//  Copyright (c) 2015 Buckleyisms. All rights reserved.
//

import Foundation

private let nanosecondsPerMillisecond: UInt64 = 1000000
private let nanosecondsPerSecond: UInt64 = 1000000000

private let globalTimerQueue = dispatch_queue_create("com.buckleyisms.Timer", DISPATCH_QUEUE_SERIAL)

private var runningTimers = Set<Timer>()

public enum TimerState
{
    case Stopped
    case Running
    case Paused
}

public class Timer : Hashable
{
    private var timer: dispatch_source_t? = nil
    private let interval: UInt64
    private let reptitions: Int64
    private let queue: dispatch_queue_t
    private let completion: (Timer) -> ()

    private var _state: TimerState = TimerState.Stopped
    private var timerStartedAt: NSDate? = nil
    private var pauseInterval: Int64 = 0

    public var hashValue: Int
    {
        get
        {
            return Int(self.interval)
        }
    }

    public var state: TimerState
    {
        get
        {
            var stateToReturn = TimerState.Stopped

            dispatch_sync(globalTimerQueue,
            {
                stateToReturn = self._state
            })

            return stateToReturn
        }
    }

    public init?(nanoseconds: UInt64, repeat: Int64, queue: dispatch_queue_t, _ completion: (Timer) -> ())
    {
        self.interval = nanoseconds
        self.reptitions = repeat
        self.queue = queue
        self.completion = completion

        if nanoseconds > UInt64(INT64_MAX)
        {
            return nil
        }
    }

    public convenience init?(milliseconds: UInt64, repeat: Int64, queue: dispatch_queue_t, _ completion: (Timer) -> ())
    {
        self.init(nanoseconds: milliseconds * nanosecondsPerMillisecond, repeat: repeat, queue: queue, completion)
    }

    public convenience init?(seconds: UInt64, repeat: Int64, queue: dispatch_queue_t, _ completion: (Timer) -> ())
    {
        self.init(nanoseconds: seconds * nanosecondsPerSecond, repeat: repeat, queue: queue, completion)
    }

    deinit
    {
        cancel()
    }

    public func start() -> Bool
    {
        var started = false

        dispatch_sync(globalTimerQueue,
        {
            if self._state != TimerState.Running
            {
                var remaining = self.reptitions

                self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, globalTimerQueue)

                if let timer = self.timer
                {
                    dispatch_source_set_timer(
                        timer,
                        dispatch_time(DISPATCH_TIME_NOW, Int64(self.interval) - self.pauseInterval),
                        self.interval,
                        0
                    )

                    dispatch_source_set_event_handler(timer,
                    {
                        if self._state == TimerState.Running
                        {
                            if remaining > 0
                            {
                                --remaining;
                            }

                            if remaining == 0
                            {
                                self.cancel()
                                self.reset()
                            }

                            self.pauseInterval = 0
                            self.timerStartedAt = NSDate()

                            dispatch_async(self.queue, { self.completion(self) })
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

    public func stop()
    {
        dispatch_sync(globalTimerQueue,
        {
            self.cancel()
            self.reset()
        })
    }

    public func pause() -> Bool
    {
        var paused = false

        dispatch_sync(globalTimerQueue,
        {
            if self._state == TimerState.Running
            {
                if let timerStartedAt = self.timerStartedAt
                {
                    var timeSinceStart = Int64(
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

    private func cancel()
    {
        if self._state == TimerState.Running
        {
            if let timer = self.timer
            {
                dispatch_source_cancel(timer)
            }

            runningTimers.remove(self)
        }
    }

    private func reset()
    {
        self._state = TimerState.Stopped
        self.timerStartedAt = nil
        self.pauseInterval = 0
    }
}

public func ==(lhs: Timer, rhs: Timer) -> Bool
{
    return lhs === rhs
}
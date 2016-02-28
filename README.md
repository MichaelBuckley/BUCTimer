# BUCTimer

BUCTimer is a native Swift timer based on GCD. Timers can be scheduled from any thread, even if that thread does not have a runloop, and can execute code on any queue. Timers can be paused, stopped, and restarted.

## Installation

### [Carthage](https://github.com/Carthage/Carthage) ###


Carthage is the recommended way to install BUCTimer. Start by adding the following line to your [Cartfile](https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md#cartfile).
```
github "MichaelBuckley/BUCTimer" ~> 2.0
```

Full instructions on installing dependencies with Carthage can be found in [Carthage's README](https://github.com/Carthage/Carthage#adding-frameworks-to-an-application).

### [CocoaPods](http://cocoapods.org) ###

Add the following line to your Podfile(http://guides.cocoapods.org/using/the-podfile.html).

```ruby
pod 'BUCTimer', '~> 2.0'
```
Then, run `pod update`.

## Usage

Using BUCTimer is simple. Create a timer object and call `start()`.

```Swift
import BUCTimer

let timer = Timer(milliseconds: 100, repeats: 0, queue: dispatch_get_main_queue(),
{
    timer in

    // Code to be called when the timer fires
})

timer?.start()
```

There are also initializers that allow you to specify the interval in seconds and nanoseconds. The initializer will fail if the interval is greater than 292 years.

If you specify 0 or 1 for the repeats parameter, the timer will only fire once before stopping. If you specify a greater number, the timer will fire that many times before stoping. If you specify a negative number, the timer will repeat indefinitely until paused or stopped. Because of this, the timer is passed into your completion handler as a parameter so that you can stop the timer once you no longer need it.

```Swift
import BUCTimer

let timer = Timer(milliseconds: 100, repeats: -1, queue: dispatch_get_main_queue(),
{
    timer in

    var stopTimer = false

    // Code to be called when the timer fires, and which may set stopTimer to true

    if stopTimer
    {
        timer.stop()
    }
})

timer?.start()
```

### Pausing, Stopping and Resuming ###

Timers can be paused by calling the `pause()` method. The next time you call `start()` on that timer, it will pick up from where it left off. For example, If you have a timer with a 2-second interval, and you call `pause()` one second after calling `start()`, the timer will fire one second after the next time you call `start()` on it.

in contrast, calling `stop()` will reset the timer. If you called stop on a timer with a two-second interval, the timer would fire two seconds after the next time you called `start()` on it.

You may call `stop()` on a paused timer to reset it.

## License

BUCTimer is released under the [MIT license](http://opensource.org/licenses/MIT).

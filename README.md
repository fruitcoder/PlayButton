# PlayButton

[![Version](https://img.shields.io/cocoapods/v/PlayButton.svg?style=flat)](http://cocoapods.org/pods/PlayButton)
[![License](https://img.shields.io/cocoapods/l/PlayButton.svg?style=flat)](http://cocoapods.org/pods/PlayButton)
[![Platform](https://img.shields.io/cocoapods/p/PlayButton.svg?style=flat)](http://cocoapods.org/pods/PlayButton)

## Overview

This project serves two purposes: 
1. It's a button I might use in another open source project (a customizable media player) but you can use it in your projects as well, if you just want the animated button and not the entire player. 
2. I wanted to create an animation + secondary animation that is reversible through user interaction. WHAT? Okay, so the whole state transition is one keyframe animation, but I cannot just "reverse" the animation, because the secondary animation (animation caused by the movement of the right pause layer) behaves differently depending on the direction (this influences the bending of the line). Since the solution I came up with is not that perfect, which partly results from wrong timing functions, the reversble animation is under another branch and you can just check it out. I consider switching from the `CADisplayLink` approach to a custom layer property animation, where `progress` would range from `0.0` to `1.0` and when there is still an animation going on while hitting the button I would remove the animation and add the reverse animation with `1.0 - progress`. That way I could avoid all the state tracking. 

## Demo
![alt tag](RefreshSuccess.gif) 

## Usage

```Swift
import PlayButton

let playButton = PlayButton(origin: CGPoint(x: 100, y: 100), width: 30.0, initialAction: .Pause)
playButton.addTarget(self, action: #selector(tap), forControlEvents: .TouchUpInside)
view.addSubview(playButton)
```

Or just add a `UIButton` to your Storyboard and set the class to `PlayButton` 

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements
* ARC
* iOS8

## Installation

PlayButton is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "PlayButton"
```

## Author

Alexander Hüllmandel, alx91@me.com

## License

PlayButton is available under the MIT license. See the LICENSE file for more info.

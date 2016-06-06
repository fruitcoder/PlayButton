//
//  PlayButton.swift
//  Pods
//
//  Created by Alexander Hüllmandel on 06/06/16.
//
//

import UIKit

public enum PlayAction {
  case Pause
  case Play
  
  /// `.Pause` when self is `.Play`, .Play when `self` is `.Pause`
  public var reverseAction: PlayAction {
    return self == .Play ? .Pause : .Play
  }
}

@IBDesignable
public class PlayButton: UIButton {
  public private(set) var buttonAction = PlayAction.Play
  
  /// The ratio between the width of the pause line and the width of the button. Defaults to `0.27`.
  @IBInspectable
  public var pauseLineWidthRatio: CGFloat = 0.27
  
  /// Returns how wide the pause line is for the current bounds
  public var pauseLineWidth: CGFloat{
    return CGRectGetWidth(bounds) * pauseLineWidthRatio
  }
  
  /// This property determines how much the pause shape will be scaled in relation to the bounds. Defaults to `0.5`.
  @IBInspectable
  public var pauseScale: CGFloat = 0.5
  
  /// Returns how wide the pause line is during the scaling animation.
  public var scaledPauseLineWidth: CGFloat {
    return pauseScale * pauseLineWidth
  }
  
  /// Determines how long the animation will take. Defaults to `1.05`
  public var animationDuration: CFTimeInterval = 1.05 // defaults to 1.05
  
  public override init(frame: CGRect) {
    super.init(frame: frame)
    
    setup()
  }
  
  ///  Initializes and returns a newly allocated `PlayButton` object with the specified parameters.
  ///
  ///  - parameter origin:        The origin of the button
  ///  - parameter width:         The width of the button, which will also be used as its height. Defaults to `30.0`
  ///  - parameter initialAction: The initial button action, that the button represents. Defaults to `.Play`
  ///
  ///  - returns: An initialized `PlayButton` object
  public convenience init(origin: CGPoint, width: CGFloat = 30.0, initialAction: PlayAction = .Play) {
    self.init(frame: CGRect(origin: origin, size: CGSize(width: width, height: width)))
    
    self.buttonAction = initialAction
    setup()
  }
  
  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    
    setup()
  }
  
  public override var tintColor: UIColor! {
    didSet {
      leftShapeLayer.fillColor = tintColor.CGColor
      rightShapeLayer.fillColor = tintColor.CGColor
    }
  }
  
  private var displayLink: CADisplayLink!
  private enum Animation: String {
    case LeftPlayToPause, RightPlayToPause, LeftPauseToPlay, RightPauseToPlay
    
    var key: String {
      return self.rawValue
    }
    
    var keyTimes: [Float] {
      switch self {
      case .LeftPauseToPlay:
        return [0.0, 0.143, 0.486, 0.486, 0.714, 0.714, 0.811, 0.908, 1.0]
      case .RightPauseToPlay:
        return [0.0, 0.143, 0.429, 0.543, 0.629, 0.657, 0.714, 0.714, 1.0]
      case .LeftPlayToPause:
        return [0.0, 0.097, 0.194, 0.286, 0.857, 1.0]
      case .RightPlayToPause:
        return [0.0, 0.286, 0.286, 0.571, 0.686, 0.771, 0.8, 0.857, 1.0]
      }
    }
    
    var timingFunctions: [CAMediaTimingFunction]? {
      switch self {
      case .LeftPauseToPlay:
        return [
          CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn),
          CAMediaTimingFunction(name: kCAMediaTimingFunctionDefault), // ignored, because interpolated paths are the same
          CAMediaTimingFunction(name: kCAMediaTimingFunctionDefault), // ignored, because the keyTimes between the frames are the same -> instant change
          CAMediaTimingFunction(name: kCAMediaTimingFunctionDefault), // ignored, because interpolated paths are the same (zeroPath)
          CAMediaTimingFunction(name: kCAMediaTimingFunctionDefault), // ignored, because the keyTimes between the frames are the same -> instant change
          CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear),
          CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear),
          CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn),
        ]
      case .RightPauseToPlay:
        return [
          CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn),
          CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn),
          CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut),
          CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut),
          CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut),
          CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut),
          CAMediaTimingFunction(name: kCAMediaTimingFunctionDefault),
          CAMediaTimingFunction(name: kCAMediaTimingFunctionDefault),
        ]
      case .LeftPlayToPause:
        return [
          CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn),
          CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear),
          CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear),
          CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear),
          CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn),
        ]
      case .RightPlayToPause:
        return [ // default
          CAMediaTimingFunction(name: kCAMediaTimingFunctionDefault), // ignored, because interpolated paths are the same (zeroPath)
          CAMediaTimingFunction(name: kCAMediaTimingFunctionDefault), // ignored, because the keyTimes between the frames are the same -> instant change
          CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn),
          CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut),
          CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut),
          CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut),
          CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut),
          CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        ]
      }
    }
    
    func finalFrame(lineWidth: CGFloat, atScale scale: CGFloat, bounds: CGRect) -> CGPath {
      switch self {
      case .LeftPauseToPlay:
        return playPathAtScale(1.0, lineWidth: lineWidth, bounds: bounds)
      case .RightPauseToPlay:
        return zeroPath()
      case .LeftPlayToPause:
        return leftMorph2PlayPathAtScale(1.0, lineWidth: lineWidth, bounds: bounds)
      case .RightPlayToPause:
        return rightPausePathAtScale(1.0, lineWidth: lineWidth, bounds: bounds, xOffset: bounds.width - lineWidth, bending: 0.0)
      }
    }
    
    func keyframes(forLineWidth lineWidth: CGFloat, atScale scale: CGFloat, bounds: CGRect) -> [CGPath] {
      let scaledLineWidth = lineWidth * scale
      switch self {
      case .LeftPauseToPlay:
        return [
          leftMorph2PlayPathAtScale(1.0, lineWidth: lineWidth, bounds: bounds),
          leftMorph2PlayPathAtScale(scale, lineWidth: scaledLineWidth, bounds: bounds),
          leftMorph2PlayPathAtScale(scale, lineWidth: scaledLineWidth, bounds: bounds),
          zeroPath(), // hide when right shape layer "rebounces" into left one
          zeroPath(), // stay hidden until right layer finished bouncing
          leftMorph2PlayPathAtScale(scale, lineWidth: scaledLineWidth, bounds: bounds), // appear again
          leftMorph1PlayPathAtScale(scale, lineWidth: scaledLineWidth, bounds: bounds),
          playPathAtScale(scale, lineWidth: scaledLineWidth, bounds: bounds),
          playPathAtScale(1.0, lineWidth: lineWidth, bounds: bounds)
        ]
      case .RightPauseToPlay:
        return [
          rightPausePathAtScale(1.0, lineWidth: lineWidth, bounds: bounds, xOffset: bounds.width - lineWidth, bending: 0.0),
          rightPausePathAtScale(scale, lineWidth: scaledLineWidth, bounds: bounds, xOffset: scale*bounds.width - scaledLineWidth, bending: 0.0),
          rightPausePathAtScale(scale, lineWidth: scaledLineWidth, bounds: bounds, xOffset: 0.0, bending: 1.0),
          rightPausePathAtScale(scale, lineWidth: scaledLineWidth, bounds: bounds, xOffset: 0.0, bending: -0.7),
          rightPausePathAtScale(scale, lineWidth: scaledLineWidth, bounds: bounds, xOffset: 0.0, bending: 0.3),
          rightPausePathAtScale(scale, lineWidth: scaledLineWidth, bounds: bounds, xOffset: 0.0, bending: -0.15),
          rightPausePathAtScale(scale, lineWidth: scaledLineWidth, bounds: bounds, xOffset: 0.0, bending: 0.0),
          zeroPath(), // hide it
        ]
        
      case .LeftPlayToPause:
        return [
          playPathAtScale(1.0, lineWidth: lineWidth, bounds: bounds),
          playPathAtScale(scale, lineWidth: lineWidth, bounds: bounds),
          leftMorph1PlayPathAtScale(scale, lineWidth: lineWidth, bounds: bounds),
          leftMorph2PlayPathAtScale(scale, lineWidth: scaledLineWidth, bounds: bounds),
          leftMorph2PlayPathAtScale(scale, lineWidth: scaledLineWidth, bounds: bounds),
          leftMorph2PlayPathAtScale(1.0, lineWidth: lineWidth, bounds: bounds),
        ]
        
      case .RightPlayToPause:
        return [
          zeroPath(),
          zeroPath(),
          rightPausePathAtScale(scale, lineWidth: scaledLineWidth, bounds: bounds, xOffset: 0.0, bending: 0.0),
          rightPausePathAtScale(scale, lineWidth: scaledLineWidth, bounds: bounds, xOffset: scale*bounds.width - scaledLineWidth, bending: -1.0),
          rightPausePathAtScale(scale, lineWidth: scaledLineWidth, bounds: bounds, xOffset: scale*bounds.width - scaledLineWidth, bending: 0.7),
          rightPausePathAtScale(scale, lineWidth: scaledLineWidth, bounds: bounds, xOffset: scale*bounds.width - scaledLineWidth, bending: -0.3),
          rightPausePathAtScale(scale, lineWidth: scaledLineWidth, bounds: bounds, xOffset: scale*bounds.width - scaledLineWidth, bending: 0.15),
          rightPausePathAtScale(scale, lineWidth: scaledLineWidth, bounds: bounds, xOffset: scale*bounds.width - scaledLineWidth, bending: 0.0),
          rightPausePathAtScale(1.0, lineWidth: lineWidth, bounds: bounds, xOffset: bounds.width - lineWidth, bending: 0.0),
        ]
      }
    }
    
    ///  Returns a keyframe animation with given parameters
    ///
    ///  - parameter duration:   how long the animation should take in total
    ///  - parameter timeOffset: `timeOffset` describes the progress of the animation. If `timeOffset = 0.0` it starts from the beginning, if `timeOffset = 0.5` it starts at 50%
    ///  - parameter lineWidth:  how thick the paused line is
    ///  - parameter scale:      how small the button is scaled during animation
    ///  - parameter bounds:     the bounds of the button
    ///
    ///  - returns: Returns a keyframe animation with given parameters
    func keyframeAnimation(withDuration duration: CFTimeInterval, lineWidth: CGFloat, scale: CGFloat, bounds: CGRect, timeOffset: CFTimeInterval = 0.0, fromValue: CGPath? = nil) -> CAKeyframeAnimation {
      let animation = CAKeyframeAnimation(keyPath: "path")
      animation.duration = (1.0 - timeOffset) * duration
      
      let keyFrames: [CGPath]
      let keyTimes: [Float]
      let timingFunctions: [CAMediaTimingFunction]?
      
      if let fromValue = fromValue {
        let indexOfNextKeyframe = timeOffset == 0.0 ? 0 : self.keyTimes.indexOf({ $0 > Float(timeOffset) })! // seems the same as Swift 3.0's first(where:)...
  
        // keyframes
        var keyFrameSubset = Array(keyframes(forLineWidth: lineWidth, atScale: scale, bounds: bounds).suffixFrom(indexOfNextKeyframe))
        if indexOfNextKeyframe != 0 { keyFrameSubset.insert(fromValue, atIndex: 0) }
        
        // times
        var keyTimeSubset = Array(self.keyTimes.suffixFrom(indexOfNextKeyframe))
        if indexOfNextKeyframe != 0 {
          keyTimeSubset = keyTimeSubset.map({ ($0 - Float(timeOffset)) * Float(duration/animation.duration) }) // convert time space
          keyTimeSubset.insert(0.0, atIndex: 0)
        }
        
        // timing functions
        var timingFunctionsSubset: [CAMediaTimingFunction]?
        if let functions = self.timingFunctions {
          if indexOfNextKeyframe == 0 { // take all timing functions
            timingFunctionsSubset = functions
          } else {
            timingFunctionsSubset = Array(functions.suffixFrom(indexOfNextKeyframe))
          }
        } else {
          timingFunctionsSubset = nil
        }
        
        keyFrames = keyFrameSubset
        keyTimes = keyTimeSubset
        timingFunctions = timingFunctionsSubset
      } else {
        keyFrames = keyframes(forLineWidth: lineWidth, atScale: scale, bounds: bounds)
        keyTimes = self.keyTimes
        timingFunctions = self.timingFunctions
      }
      
      animation.values = keyFrames
      animation.keyTimes = keyTimes
      animation.timingFunctions = timingFunctions
      
      return animation
    }
    
    private func zeroPath() -> CGPath {
      let margin = 0.0
      let playPath = UIBezierPath()
      playPath.moveToPoint(CGPoint(x: margin, y: margin))
      playPath.closePath()
      return playPath.CGPath
    }
    
    private func playPathAtScale(scale: CGFloat, lineWidth: CGFloat, bounds: CGRect) -> CGPath {
      let margin = (1.0 - scale)/2.0 * CGRectGetWidth(bounds)
      let playPath = UIBezierPath()
      playPath.moveToPoint(CGPoint(x: margin, y: margin))
      playPath.addLineToPoint(CGPoint(x: margin + lineWidth, y: margin + floor(lineWidth/sqrt(3))))
      playPath.addLineToPoint(CGPoint(x: CGRectGetMaxX(bounds)-margin, y: CGRectGetMidY(bounds)))
      playPath.addLineToPoint(CGPoint(x: CGRectGetMaxX(bounds)-margin, y: CGRectGetMidY(bounds)))
      playPath.addLineToPoint(CGPoint(x: margin + lineWidth, y: CGRectGetMaxY(bounds) - margin - floor(lineWidth/sqrt(3))))
      playPath.addLineToPoint(CGPoint(x: margin, y: CGRectGetMaxY(bounds) - margin))
      playPath.closePath()
      return playPath.CGPath
    }
    
    private func leftMorph1PlayPathAtScale(scale: CGFloat, lineWidth: CGFloat, bounds: CGRect) -> CGPath {
      let margin = (1.0 - scale)/2.0 * CGRectGetWidth(bounds)
      let playPath = UIBezierPath()
      playPath.moveToPoint(CGPoint(x: margin, y: margin))
      playPath.addLineToPoint(CGPoint(x: margin + lineWidth, y: margin + lineWidth/sqrt(3)))
      playPath.addLineToPoint(CGPoint(x: margin + lineWidth, y: margin + lineWidth/sqrt(3)))
      playPath.addLineToPoint(CGPoint(x: margin + lineWidth, y: CGRectGetMaxY(bounds) - margin - lineWidth/sqrt(3)))
      playPath.addLineToPoint(CGPoint(x: margin + lineWidth, y: CGRectGetMaxY(bounds) - margin - lineWidth/sqrt(3)))
      playPath.addLineToPoint(CGPoint(x: margin, y: CGRectGetMaxY(bounds) - margin))
      playPath.closePath()
      
      return playPath.CGPath
    }
    
    private func leftMorph2PlayPathAtScale(scale: CGFloat, lineWidth: CGFloat, bounds: CGRect) -> CGPath {
      let margin = (1.0 - scale)/2.0 * CGRectGetWidth(bounds)
      let playPath = UIBezierPath()
      playPath.moveToPoint(CGPoint(x: margin, y: margin))
      playPath.addLineToPoint(CGPoint(x: margin + lineWidth, y: margin))
      playPath.addLineToPoint(CGPoint(x: margin + lineWidth, y: margin + lineWidth/sqrt(3)))
      playPath.addLineToPoint(CGPoint(x: margin + lineWidth, y: CGRectGetMaxY(bounds) - margin - lineWidth/sqrt(3)))
      playPath.addLineToPoint(CGPoint(x: margin + lineWidth, y: CGRectGetMaxY(bounds) - margin))
      playPath.addLineToPoint(CGPoint(x: margin, y: CGRectGetMaxY(bounds) - margin))
      playPath.closePath()
      
      return playPath.CGPath
    }
    
    private func rightPausePathAtScale(scale: CGFloat = 1.0, lineWidth: CGFloat, bounds: CGRect, xOffset: CGFloat = 0.0, bending: CGFloat = 0.0) -> CGPath {
      let margin = (1.0 - scale)/2.0 * CGRectGetWidth(bounds)
      let playPath = UIBezierPath()
      playPath.moveToPoint(CGPoint(x: margin + lineWidth + xOffset, y: margin))
      playPath.addQuadCurveToPoint(CGPoint(x: margin + lineWidth + xOffset, y: CGRectGetMaxY(bounds) - margin),
                                   controlPoint: CGPoint(x: margin + lineWidth + xOffset - bending * lineWidth, y: CGRectGetMidY(bounds)))
      playPath.addLineToPoint(CGPoint(x: margin + xOffset, y: CGRectGetMaxY(bounds) - margin))
      playPath.addQuadCurveToPoint(CGPoint(x: margin + xOffset, y: margin),
                                   controlPoint: CGPoint(x: margin + xOffset - bending * lineWidth, y: CGRectGetMidY(bounds)))
      playPath.closePath()
      
      return playPath.CGPath
    }
  }
  
  private let leftShapeLayer: CAShapeLayer = {
    $0.contentsScale = UIScreen.mainScreen().scale
    $0.fillColor = UIColor.blackColor().CGColor
    return $0
  }(CAShapeLayer())
  
  private let rightShapeLayer: CAShapeLayer = {
    $0.contentsScale = UIScreen.mainScreen().scale
    $0.fillColor = UIColor.blackColor().CGColor
    return $0
  }(CAShapeLayer())
  
  public func setButtonAction(action: PlayAction, animated: Bool) {
    guard buttonAction != action else { return }
    
    buttonAction = action
    
    if animated {
      animationStart = 0
      displayLink.paused = false
      
      switch buttonAction {
      case .Pause:
        // set model values to final state
        leftShapeLayer.path = Animation.LeftPlayToPause.finalFrame(pauseLineWidth, atScale: pauseScale, bounds: bounds)
        rightShapeLayer.path = Animation.RightPlayToPause.finalFrame(pauseLineWidth, atScale: pauseScale, bounds: bounds)
        
        // left layer
        if let _ = leftShapeLayer.animationForKey(Animation.LeftPauseToPlay.key), currentPath = (leftShapeLayer.presentationLayer() as? CAShapeLayer)?.path {
          leftShapeLayer.removeAllAnimations()
          
          let reversedTimeOffset = CFTimeInterval(1.0 - progress)
          leftShapeLayer.addAnimation(Animation.LeftPlayToPause.keyframeAnimation(withDuration: animationDuration,
            lineWidth: pauseLineWidth,
            scale: pauseScale,
            bounds: bounds,
            timeOffset: reversedTimeOffset,
            fromValue: currentPath), forKey: Animation.LeftPlayToPause.key)
        } else {
          progress = 0.0
          
          leftShapeLayer.addAnimation(Animation.LeftPlayToPause.keyframeAnimation(withDuration: animationDuration,
            lineWidth: pauseLineWidth,
            scale: pauseScale,
            bounds: bounds,
            timeOffset: 0.0,
            fromValue: nil), forKey: Animation.LeftPlayToPause.key)
        }
        
        // right layer
        if let _ = rightShapeLayer.animationForKey(Animation.RightPauseToPlay.key), currentPath = (rightShapeLayer.presentationLayer() as? CAShapeLayer)?.path {
          rightShapeLayer.removeAllAnimations()
          
          let reversedTimeOffset = CFTimeInterval(1.0 - progress)
          rightShapeLayer.addAnimation(Animation.RightPlayToPause.keyframeAnimation(withDuration: animationDuration,
            lineWidth: pauseLineWidth,
            scale: pauseScale,
            bounds: bounds,
            timeOffset: reversedTimeOffset,
            fromValue: currentPath), forKey: Animation.RightPlayToPause.key)
        } else {
          rightShapeLayer.addAnimation(Animation.RightPlayToPause.keyframeAnimation(withDuration: animationDuration,
            lineWidth: pauseLineWidth,
            scale: pauseScale,
            bounds: bounds,
            timeOffset: 0.0,
            fromValue: nil), forKey: Animation.RightPlayToPause.key)
        }
        
      case .Play:
        // set model values to final state
        leftShapeLayer.path = Animation.LeftPauseToPlay.finalFrame(pauseLineWidth, atScale: pauseScale, bounds: bounds)
        rightShapeLayer.path = Animation.LeftPauseToPlay.finalFrame(pauseLineWidth, atScale: pauseScale, bounds: bounds)
        
        // left layer
        if let _ = leftShapeLayer.animationForKey(Animation.LeftPlayToPause.key), currentPath = (leftShapeLayer.presentationLayer() as? CAShapeLayer)?.path {
          leftShapeLayer.removeAllAnimations()
          
          let reversedTimeOffset = CFTimeInterval(1.0 - progress)
          leftShapeLayer.addAnimation(Animation.LeftPauseToPlay.keyframeAnimation(withDuration: animationDuration,
            lineWidth: pauseLineWidth,
            scale: pauseScale,
            bounds: bounds,
            timeOffset: reversedTimeOffset,
            fromValue: currentPath), forKey: Animation.LeftPauseToPlay.key)
        } else {
          progress = 0.0
          
          leftShapeLayer.addAnimation(Animation.LeftPauseToPlay.keyframeAnimation(withDuration: animationDuration,
            lineWidth: pauseLineWidth,
            scale: pauseScale,
            bounds: bounds,
            timeOffset: 0.0,
            fromValue: nil), forKey: Animation.LeftPauseToPlay.key)
        }
        
        // right layer
        if let _ = rightShapeLayer.animationForKey(Animation.RightPlayToPause.key), currentPath = (rightShapeLayer.presentationLayer() as? CAShapeLayer)?.path {
          rightShapeLayer.removeAllAnimations()
          
          let reversedTimeOffset = CFTimeInterval(1.0 - progress)
          rightShapeLayer.addAnimation(Animation.RightPauseToPlay.keyframeAnimation(withDuration: animationDuration,
            lineWidth: pauseLineWidth,
            scale: pauseScale,
            bounds: bounds,
            timeOffset: reversedTimeOffset,
            fromValue: currentPath), forKey: Animation.RightPauseToPlay.key)
        } else {
          rightShapeLayer.addAnimation(Animation.RightPauseToPlay.keyframeAnimation(withDuration: animationDuration,
            lineWidth: pauseLineWidth,
            scale: pauseScale,
            bounds: bounds,
            timeOffset: 0.0,
            fromValue: nil), forKey: Animation.RightPauseToPlay.key)
        }
      }
    } else {
      displayLink.paused = true
      
      switch buttonAction {
      case .Play:
        leftShapeLayer.path = Animation.LeftPauseToPlay.finalFrame(pauseLineWidth, atScale: pauseScale, bounds: bounds)
        rightShapeLayer.path = Animation.LeftPauseToPlay.finalFrame(pauseLineWidth, atScale: pauseScale, bounds: bounds)
      case .Pause:
        leftShapeLayer.path = Animation.LeftPlayToPause.finalFrame(pauseLineWidth, atScale: pauseScale, bounds: bounds)
        rightShapeLayer.path = Animation.RightPlayToPause.finalFrame(pauseLineWidth, atScale: pauseScale, bounds: bounds)
      }
    }
  }
  
  private var animationStart: CFTimeInterval = 0
  private var progress: Float = 0.0
  private var progressOffset: Float = 0.0
  private func setup() {
    displayLink = CADisplayLink(target: self, selector: #selector(tick))
    displayLink.addToRunLoop(.mainRunLoop(), forMode: NSDefaultRunLoopMode)
    displayLink.paused = true
    
    backgroundColor = .clearColor()//.yellowColor()
    tintColor = .blackColor()
    
    layer.addSublayer(leftShapeLayer)
    layer.addSublayer(rightShapeLayer)
    
    leftShapeLayer.path = Animation.LeftPauseToPlay.finalFrame(pauseLineWidth, atScale: pauseScale, bounds: bounds)
    rightShapeLayer.path = Animation.LeftPauseToPlay.finalFrame(pauseLineWidth, atScale: pauseScale, bounds: bounds)
  }
  
  @objc private func tick() {
    if animationStart == 0 {
      animationStart = displayLink.timestamp
      progressOffset = 1.0 - progress // we already made it this far
      if progressOffset == 1.0 {
        progressOffset = 0.0
      }
    }
    progress = min(Float((displayLink.timestamp - animationStart)/(animationDuration)) + progressOffset, 1.0)
    
    print(progress)
    if progress == 1.0 { // animation finished
      displayLink.paused = true
      progressOffset = 0.0
    }
  }
  
  public override func layoutSublayersOfLayer(layer: CALayer) {
    super.layoutSublayersOfLayer(layer)
    
    leftShapeLayer.frame = bounds
    rightShapeLayer.frame = bounds
    
    switch buttonAction {
    case .Pause:
      leftShapeLayer.path = Animation.LeftPlayToPause.finalFrame(pauseLineWidth, atScale: 1.0, bounds: bounds)
      rightShapeLayer.path = Animation.RightPlayToPause.finalFrame(pauseLineWidth, atScale: 1.0, bounds: bounds)
      
    case .Play:
      leftShapeLayer.path = Animation.LeftPauseToPlay.finalFrame(pauseLineWidth, atScale: 1.0, bounds: bounds)
      rightShapeLayer.path = Animation.RightPauseToPlay.finalFrame(pauseLineWidth, atScale: 1.0, bounds: bounds)
    }
  }
}
 
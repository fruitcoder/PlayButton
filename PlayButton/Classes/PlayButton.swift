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
    ///  - parameter lineWidth:  how thick the paused line is
    ///  - parameter scale:      how small the button is scaled during animation
    ///  - parameter bounds:     the bounds of the button
    ///
    ///  - returns: Returns a keyframe animation with given parameters
    func keyframeAnimation(withDuration duration: CFTimeInterval, lineWidth: CGFloat, scale: CGFloat, bounds: CGRect) -> CAKeyframeAnimation {
      let animation = CAKeyframeAnimation(keyPath: "path")
      animation.duration = duration
      
      animation.values = keyframes(forLineWidth: lineWidth, atScale: scale, bounds: bounds)
      animation.keyTimes = self.keyTimes
      animation.timingFunctions = self.timingFunctions
      
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
  
  ///  Set the button action for the button. If the `action` is the same as `buttonAction`, nothing happens. If `animated` is `true` the animation will take `animationDuration` seconds, when there is no animation currently going on. If `animated` is `false` or there is already an ongoing animation, the state will be immidiately set
  ///
  ///  - parameter action:   The new button action
  ///  - parameter animated: Determines whether the state change should be animated (with duration `animationDuration`)
  public func setButtonAction(action: PlayAction, animated: Bool) {
    guard buttonAction != action else { return }
    
    buttonAction = action
    
    switch buttonAction {
    case .Pause:
      if !animated || leftShapeLayer.animationForKey(Animation.LeftPauseToPlay.key) != nil { // ongoing animation is cancelled
        setModelToFinalPath()
      } else {
        setModelToFinalPath()
        
        // left layer
        leftShapeLayer.addAnimation(Animation.LeftPlayToPause.keyframeAnimation(withDuration: animationDuration,
          lineWidth: pauseLineWidth,
          scale: pauseScale,
          bounds: bounds), forKey: Animation.LeftPlayToPause.key)
        
        // right layer
        rightShapeLayer.addAnimation(Animation.RightPlayToPause.keyframeAnimation(withDuration: animationDuration,
          lineWidth: pauseLineWidth,
          scale: pauseScale,
          bounds: bounds), forKey: Animation.RightPlayToPause.key)
      }
    case .Play:
      if !animated || leftShapeLayer.animationForKey(Animation.LeftPlayToPause.key) != nil { // ongoing animation is cancelled
        setModelToFinalPath()
      } else {
        setModelToFinalPath()

        // left layer
        leftShapeLayer.addAnimation(Animation.LeftPauseToPlay.keyframeAnimation(withDuration: animationDuration,
                                                                                  lineWidth: pauseLineWidth,
                                                                                  scale: pauseScale,
                                                                                  bounds: bounds), forKey: Animation.LeftPauseToPlay.key)
      
        // right layer
        rightShapeLayer.addAnimation(Animation.RightPauseToPlay.keyframeAnimation(withDuration: animationDuration,
                                                                                  lineWidth: pauseLineWidth,
                                                                                  scale: pauseScale,
                                                                                  bounds: bounds), forKey: Animation.RightPauseToPlay.key)
      }
    }
  }
  
  private func setModelToFinalPath() {
    switch buttonAction {
    case .Pause:
      leftShapeLayer.removeAllAnimations()
      rightShapeLayer.removeAllAnimations()
        
      leftShapeLayer.path = Animation.LeftPlayToPause.finalFrame(pauseLineWidth, atScale: 1.0, bounds: bounds)
      rightShapeLayer.path = Animation.RightPlayToPause.finalFrame(pauseLineWidth, atScale: 1.0, bounds: bounds)
    case .Play:
      leftShapeLayer.removeAllAnimations()
      rightShapeLayer.removeAllAnimations()
      
      leftShapeLayer.path = Animation.LeftPauseToPlay.finalFrame(pauseLineWidth, atScale: 1.0, bounds: bounds)
      rightShapeLayer.path = Animation.RightPauseToPlay.finalFrame(pauseLineWidth, atScale: 1.0, bounds: bounds)
    }
  }
  
  private func setup() {
    backgroundColor = .clearColor()
    tintColor = .blackColor()
    
    layer.addSublayer(leftShapeLayer)
    layer.addSublayer(rightShapeLayer)
    
    leftShapeLayer.path = Animation.LeftPauseToPlay.finalFrame(pauseLineWidth, atScale: pauseScale, bounds: bounds)
    rightShapeLayer.path = Animation.RightPauseToPlay.finalFrame(pauseLineWidth, atScale: pauseScale, bounds: bounds)
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
 
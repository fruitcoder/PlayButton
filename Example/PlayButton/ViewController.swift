//
//  ViewController.swift
//  PlayButton
//
//  Created by Alexander Hüllmandel on 06/06/2016.
//  Copyright (c) 2016 Alexander Hüllmandel. All rights reserved.
//

import UIKit
import PlayButton

class ViewController: UIViewController {

  // button created from code
  @IBAction func playButtonPressed(sender: PlayButton) {
    sender.setButtonAction(sender.buttonAction.reverseAction, animated: true)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()

    let playButton = PlayButton(origin: CGPoint(x: 100, y: 100), width: 30.0, initialAction: .Pause)
    playButton.addTarget(self, action: #selector(tap), forControlEvents: .TouchUpInside)
    //view.addSubview(playButton)
  }
  
  // programmatically created button
  func tap(button: PlayButton!) {
    button.setButtonAction(button.buttonAction.reverseAction, animated: true)
  }
}


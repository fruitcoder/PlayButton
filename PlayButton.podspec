#
# Be sure to run `pod lib lint PlayButton.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'PlayButton'
  s.version          = '0.1.0'
  s.summary          = 'A subclass on UIButton that animates its state between a playing and a paused state.'
  s.description      = 'This CocoaPod is a small part of a feature upcoming media player, that is currently under development and will be open sourced once it's stable. Since the button itself can be used in other projects as a button that switches between play and pause, it makes sense to have it as a separate CocoaPod. The special thing about the animation is that the CAKeyframe animation reverses when the user touches the button during animation. Since this is still not working 100% it remains in a different branch and is open for testing.'
  s.homepage         = 'https://github.com/<GITHUB_USERNAME>/PlayButton'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Alexander Hüllmandel' => 'alx91@me.com' }
  s.source           = { :git => 'https://github.com/<GITHUB_USERNAME>/PlayButton.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/hllmandel'

  s.ios.deployment_target = '8.0'

  s.source_files = 'PlayButton/Classes/**/*'
  
  # s.resource_bundles = {
  #   'PlayButton' => ['PlayButton/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end

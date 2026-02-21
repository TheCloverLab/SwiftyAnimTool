#
# Be sure to run `pod lib lint SwiftyAnimTool.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SwiftyAnimTool'
  s.version          = '1.2.0'
  s.summary          = 'Cocoapod library for animtool'
  s.description      = 'see https://github.com/dinghaoz/animtool'
  s.homepage         = 'https://github.com/Jerry/SwiftyAnimTool'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Jerry' => 'jerry.qiushi@gmail.com' }
  s.source           = { :git => 'https://github.com/Jerry/SwiftyAnimTool.git', :tag => s.version.to_s }
  s.ios.deployment_target = '12.0'
  s.vendored_framework = 'SwiftyAnimTool/SwiftyAnimTool.xcframework'
end

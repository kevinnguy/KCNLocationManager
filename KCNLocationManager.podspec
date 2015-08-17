Pod::Spec.new do |s|
  s.name             = "KCNLocationManager"
  s.version          = "1.0.0"
  s.summary          = "Location manager"
  s.homepage         = "https://github.com/kevinnguy/KCNLocationManager"
  s.license          = 'MIT'
  s.author           = 'Kevin Nguy'
  s.source           = { :git => "https://github.com/kevinnguy/KCNLocationManager.git", :tag => :master }
  s.social_media_url = 'https://twitter.com/kevnguy'

  s.platform     = :ios
  s.ios.deployment_target = '7.0'

  s.source_files = 'Classes'
end

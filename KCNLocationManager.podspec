Pod::Spec.new do |s|
  s.name             = "KCNLocationManager"
  s.version          = "1.0.1"
  s.summary          = "Location manager"
  s.homepage         = "https://github.com/kevinnguy/KCNLocationManager"
  s.license          = 'MIT'
  s.authors          = { 'Kevin Nguy' => 'kevnguy@gmail.com' }
  s.source           = { :git => "https://github.com/kevinnguy/KCNLocationManager.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/kevnguy'

  s.platform     = :ios
  s.ios.deployment_target = '7.0'

  s.source_files = 'Classes'
end

Pod::Spec.new do |spec|
  spec.name         = "com_huntmobi_web2app"
  spec.version      = "2.4.7"
  spec.summary      = "w2a"
  spec.description  = <<-DESC
    web2app
  DESC
  spec.homepage     = "https://github.com/web2app-bi4sight/web2app-iOS"
  spec.license      = "MIT"
  spec.author       = { "Leo" => "leoliu@huntmobi.com" }                   
  spec.platform     = :ios
  spec.ios.deployment_target = "12.0"
  spec.source       = { :git => "https://github.com/web2app-bi4sight/web2app-iOS.git", :tag => "#{spec.version}" }
  spec.source_files  = "com_huntmobi_web2app/*.{h,m}"
  spec.public_header_files = "com_huntmobi_web2app/*.h"
  spec.requires_arc = true
end

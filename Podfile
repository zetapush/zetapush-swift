# Uncomment this line to define a global platform for your project
# platform :ios, '9.0'
platform :ios, '10.0'

inhibit_all_warnings!

target 'ZetaPushSwift' do
  # Comment this line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for ZetaPushSwift
  pod 'Starscream'
  pod 'SwiftyJSON'
  pod 'PromiseKit', '~> 6.3.4'
  pod 'XCGLogger', '~> 6.0.4'
  pod 'Gloss', '~> 2.0.1'
end

post_install do |installer|
    
    installer.pods_project.build_configurations.each do |config|
        config.build_settings['SWIFT_SUPPRESS_WARNINGS'] = 'YES'
        config.build_settings['SWIFT_VERSION'] = '4'
    end
    
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_SUPPRESS_WARNINGS'] = 'YES'
            config.build_settings['SWIFT_VERSION'] = '4'
        end
    end
end

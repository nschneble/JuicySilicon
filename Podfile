platform :osx, '11.0'

use_frameworks!
target 'Juice' do
  pod 'RxSwift', '~> 6.0'
  pod 'RxRelay', '~> 6.0'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '11.0'
    end
  end
end

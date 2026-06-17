#source 'https://mirrors.tuna.tsinghua.edu.cn/git/CocoaPods/Specs.git'
#source 'https://guides.cocoapods.org/syntax/podfile.html#platform'

platform :ios, '16.0'
use_frameworks!
inhibit_all_warnings!
target 'LocationApp' do

pod 'AFNetworking'
pod 'JSONModel'
pod 'MBProgressHUD'
pod 'SDWebImage'
pod 'Masonry'
pod 'MJRefresh'
pod 'GoogleMaps', '10.0.0'


end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
    end
  end
end

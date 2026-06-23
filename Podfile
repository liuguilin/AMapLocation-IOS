#source 'https://mirrors.tuna.tsinghua.edu.cn/git/CocoaPods/Specs.git'
#source 'https://guides.cocoapods.org/syntax/podfile.html#platform'

platform :ios, '16.0'
use_frameworks!
inhibit_all_warnings!
target 'LocationApp' do

pod 'AFNetworking'
pod 'JSONModel'
pod 'SDWebImage'
pod 'Masonry'
pod 'MJRefresh'
pod 'GoogleMaps', '10.0.0'


end

PRIVACY_MANIFEST_PODS = {
  'AFNetworking' => 'PrivacyManifests/AFNetworking/PrivacyInfo.xcprivacy'
}.freeze

def add_privacy_manifest_to_target(installer, target_name, manifest_relative_path)
  manifest_path = File.join(__dir__, manifest_relative_path)
  return unless File.exist?(manifest_path)

  installer.pods_project.targets.each do |target|
    next unless target.name == target_name

    privacy_group = installer.pods_project.main_group.find_subpath('Privacy', true)
    file_ref = privacy_group.files.find { |f| f.path == manifest_path } ||
               privacy_group.new_file(manifest_path)
    target.resources_build_phase.add_file_reference(file_ref) unless
      target.resources_build_phase.files_references.include?(file_ref)
  end
end

def remove_private_netinet6_imports
  Dir.glob(File.join(__dir__, 'Pods/**/*.{m,mm}')).each do |file|
    content = File.read(file)
    next unless content.include?('#import <netinet6/in6.h>')

    patched = content.gsub("#import <netinet6/in6.h>\n", '')
    next if patched == content

    File.chmod(0o644, file)
    File.write(file, patched)
    puts "Removed private netinet6/in6.h import from #{file}"
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
    end
  end

  PRIVACY_MANIFEST_PODS.each do |pod_name, manifest_path|
    add_privacy_manifest_to_target(installer, pod_name, manifest_path)
  end

  remove_private_netinet6_imports
end

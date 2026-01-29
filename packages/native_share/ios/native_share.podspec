Pod::Spec.new do |s|
  s.name             = 'native_share'
  s.version          = '1.0.0'
  s.summary          = 'A Flutter plugin for native file sharing.'
  s.description      = <<-DESC
A Flutter plugin for native file sharing using method channels.
                       DESC
  s.homepage         = 'https://example.com'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'
  s.swift_version = '5.0'
end

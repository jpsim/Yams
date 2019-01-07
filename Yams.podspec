Pod::Spec.new do |s|
  s.name                      = 'Yams'
  s.version                   = '1.0.1'
  s.summary                   = 'A sweet and swifty YAML parser.'
  s.homepage                  = 'https://github.com/jpsim/Yams'
  s.source                    = { :git => s.homepage + '.git', :tag => s.version }
  s.license                   = { :type => 'MIT', :file => 'LICENSE' }
  s.author                    = { 'JP Simard' => 'jp@jpsim.com' }
  s.source_files              = 'Sources/**/*.{h,c,cpp,swift}'
  s.pod_target_xcconfig       = { 'APPLICATION_EXTENSION_API_ONLY' => 'YES' }
  s.ios.deployment_target     = '8.0'
  s.osx.deployment_target     = '10.9'
  s.tvos.deployment_target    = '9.0'
  s.watchos.deployment_target = '2.0'
end

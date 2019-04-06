Pod::Spec.new do |s|
  s.name                      = 'Yams'
  s.version                   = '2.0.0'
  s.summary                   = 'A sweet and swifty YAML parser.'
  s.homepage                  = 'https://github.com/jpsim/Yams'
  s.source                    = { :git => s.homepage + '.git', :tag => s.version }
  s.license                   = { :type => 'MIT', :file => 'LICENSE' }
  s.authors                   = { 'JP Simard' => 'jp@jpsim.com',
                                  'Norio Nomura' => 'norio.nomura@gmail.com' }
  s.source_files              = 'Sources/**/*.{h,c,swift}'
  s.pod_target_xcconfig       = { 'APPLICATION_EXTENSION_API_ONLY' => 'YES' }
  s.ios.deployment_target     = '8.0'
  s.osx.deployment_target     = '10.9'
  s.tvos.deployment_target    = '9.0'
  s.watchos.deployment_target = '2.0'
end

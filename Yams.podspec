Pod::Spec.new do |s|
  s.name                       = 'Yams'
  s.version                    = '5.1.3'
  s.summary                    = 'A sweet and swifty YAML parser.'
  s.homepage                   = 'https://github.com/jpsim/Yams'
  s.source                     = { :git => s.homepage + '.git', :tag => s.version }
  s.license                    = { :type => 'MIT', :file => 'LICENSE' }
  s.authors                    = { 'JP Simard' => 'jp@jpsim.com',
                                  'Norio Nomura' => 'norio.nomura@gmail.com' }
  s.source_files               = 'Sources/**/*.{h,c,swift}'
  s.swift_versions             = ['5.7', '5.8', '5.9', '5.10']
  s.pod_target_xcconfig        = { 'APPLICATION_EXTENSION_API_ONLY' => 'YES' }
  s.ios.deployment_target      = '11.0'
  s.osx.deployment_target      = '10.13'
  s.tvos.deployment_target     = '11.0'
  s.visionos.deployment_target = '1.0'
end

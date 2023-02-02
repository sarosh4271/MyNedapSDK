
Pod::Spec.new do |s|
  s.name             = 'MyNedapSDK'
  s.version          = '0.1.3'
  s.summary          = 'A short description of MyNedapSDK.'
  s.homepage         = 'https://github.com/sarosh4271/MyNedapSDK'
  s.license          = { :type => 'MIT', :file => 'LICENSE.md' }
  s.author           = { 'M Sarosh' => 'sarosh4271@gmail.com' }
  s.source           = { :git => 'https://github.com/sarosh4271/MyNedapSDK', :branch => 'fixed'  }
  s.ios.deployment_target = '13.0'
  s.swift_version = '5.0'
  s.source_files = 'Sources/MyNedapSDK/**/*'
  s.dependency 'CryptoSwift'
end

Pod::Spec.new do |s|
    s.name = 'Lexical'
    s.version = '0.2.0'
    s.license = 'MIT'
    s.summary = 'pod wrapper around facebook/lexical-ios'
    s.homepage = 'https://github.com/fractionalapp/lexical-ios'
    s.platform       = :ios, '13.0'
    s.swift_version  = '5.4'
    s.author = 'Peter Lin'
    s.source = { :git => 'https://github.com/fractionalapp/lexical-ios.git' }
    s.source_files = 'Lexical/**/*'
end

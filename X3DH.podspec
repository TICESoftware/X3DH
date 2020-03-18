Pod::Spec.new do |s|

  s.name          = "X3DH"
  s.version       = "2.0.3"
  s.summary       = "X3DH key agreement protocol."
  s.platform      = :ios, "11.0"
  s.swift_version = "5.1"

  s.homepage      = "https://ticeapp.com"

  s.author        = { "TICE Software UG (haftungsbeschränkt)" => "contact@ticeapp.com" }
  s.source        = { :git => "https://github.com/TICESoftware/X3DH.git", :tag => "#{s.version}" }
  s.license      = { :type => 'MIT' }

  s.source_files  = "Sources/**/*"

  s.dependency "Sodium"
  s.dependency "HKDF"

end

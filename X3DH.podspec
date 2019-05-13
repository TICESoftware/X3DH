Pod::Spec.new do |s|

  s.name          = "X3DH"
  s.version       = "1.0.1"
  s.summary       = "X3DH key agreement protocol."
  s.platform      = :ios, "11.0"
  s.swift_version = "5.0"

  s.homepage      = "http://letsmeet.anbion.de"

  s.author        = { "Anbion" => "letsmeet@anbion.de" }
  s.source        = { :git => "git@github.com:AnbionApps/X3DH.git", :tag => "#{s.version}" }

  s.source_files  = "Sources/**/*"

  s.dependency "Sodium"
  s.dependency "HKDF"

end

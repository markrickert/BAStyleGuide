# -*- coding: utf-8 -*-
$:.unshift("/Library/RubyMotion/lib")
require 'motion/project/template/ios'

begin
  require 'bundler'
  Bundler.setup
  Bundler.require
rescue LoadError
end

Motion::Project::App.setup do |app|
  app.name = 'BA Styles'
  app.identifier = 'com.mohawkapps.BAStyleGuide'

  app.short_version = "1.0.2"
  app.version = (`git rev-list HEAD --count`.strip.to_i).to_s

  app.deployment_target = "7.0"

  app.device_family = [:iphone, :ipad]
  app.interface_orientations = [:portrait, :landscape_left, :landscape_right, :portrait_upside_down]

  app.frameworks += ["QuartzCore"]
  app.libs << "/usr/lib/libsqlite3.dylib"

  app.icons = Dir.glob("resources/Icon*.png").map{|icon| icon.split("/").last}

  app.info_plist['UIRequiresFullScreen'] = true
  app.info_plist['APP_STORE_ID'] = 670470983
  app.info_plist['CFBundleURLTypes'] = [
    { 'CFBundleURLName' => app.identifier,
      'CFBundleURLSchemes' => ['bastyle'] }
  ]
  app.info_plist["LSApplicationQueriesSchemes"] = ["beerjudge"]

  app.files_dependencies 'app/Screens/DetailScreen.rb' => 'app/Screens/SizeableWebScreen.rb'
  app.files_dependencies 'app/Screens/IntroScreen.rb'  => 'app/Screens/SizeableWebScreen.rb'

  app.pods do
    pod 'Appirater'
    pod 'OpenInChrome'
    pod 'EAIntroView', '~> 2.7.0'
    pod 'CrittercismSDK', '~> 5.2.0'
  end

  app.development do
    app.entitlements['get-task-allow'] = true
    app.codesign_certificate = "iPhone Developer: Mark Rickert (YA2VZGDX4S)"
    app.provisioning_profile = "./provisioning/development.mobileprovision"
  end

  app.release do
    app.entitlements['get-task-allow'] = false
    app.codesign_certificate = "iPhone Distribution: Mohawk Apps, LLC (DW9QQZR4ZL)"
    app.provisioning_profile = "./provisioning/release.mobileprovision"
  end

end

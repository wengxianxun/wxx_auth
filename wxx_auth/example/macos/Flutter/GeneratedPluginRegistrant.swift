//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

import google_sign_in_ios
import shared_preferences_foundation
import sign_in_with_apple
import wxx_auth

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  GoogleSignInPlugin.register(with: registry.registrar(forPlugin: "GoogleSignInPlugin"))
  SharedPreferencesPlugin.register(with: registry.registrar(forPlugin: "SharedPreferencesPlugin"))
  SignInWithApplePlugin.register(with: registry.registrar(forPlugin: "SignInWithApplePlugin"))
  WxxAuthPlugin.register(with: registry.registrar(forPlugin: "WxxAuthPlugin"))
}

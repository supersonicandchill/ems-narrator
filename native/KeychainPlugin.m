//
//  KeychainPlugin.m
//  EMS Narrator
//
//  Capacitor bridge registration for KeychainPlugin.swift.
//  Without this file, window.Capacitor.Plugins.Keychain does not exist
//  in JavaScript.
//

#import <Capacitor/Capacitor.h>

CAP_PLUGIN(KeychainPlugin, "Keychain",
  CAP_PLUGIN_METHOD(setKey, CAPPluginReturnPromise);
  CAP_PLUGIN_METHOD(getKey, CAPPluginReturnPromise);
  CAP_PLUGIN_METHOD(deleteKey, CAPPluginReturnPromise);
)

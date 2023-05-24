# UI librray private drop with Calling SDK private drop

This private repo is to share private drops of `Calling UI Library` with or without private drops of `Calling Native SDK`.

## Publish podspec of Calling Native SDK
- Publish private drop following [link](https://github.com/iaulakh/calling_native_ios_private_drop)

## Publish podspec of UI Library
- Add SSH key [ssh key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account)
- Initialize repo `pod repo add calling_ui_library_private_drop git@github.com:iaulakh/calling_ui_library_private_drop.git`
- Change version in `.podspec`
- Copy `sdk/Calling and Common` from ui librray public repo that you want to release
- Checkin code to master and release with tag
- Release `pod repo push calling_ui_library_private_drop AzureCommunicationUICalling.podspec --allow-warnings`

## Podfile for demo app
```
source 'git@github.com:iaulakh/calling_ui_library_private_drop.git'
source 'git@github.com:iaulakh/calling_native_ios_private_drop.git'
source 'https://github.com/CocoaPods/Specs.git'

target 'UILibraryQuickStart' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  pod 'AzureCommunicationUICalling, '1.4.0-beta-private.2.2'
end
```

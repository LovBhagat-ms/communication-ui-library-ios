# calling_native_ios_private_drop
- Add SSH key [ssh key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account)
- Initialize repo `pod repo add calling_native_ios_private_drop git@github.com:iaulakh/calling_native_ios_private_drop.git`
- Copy `.xcframework` from native SDK private drop to repo
- Change version in `.podspec`
- Checkin code to master and release with tag
- Release `pod repo push calling_native_ios_private_drop AzureCommunicationCalling.podspec`
